// Команда build — финальный этап пайплайна: сборка content.sqlite.
//
// Читает JSONL от extract и enrich, раскладывает по таблицам §4 спецификации,
// наполняет полнотекстовый индекс и сжимает базу. Полученный файл приложение
// открывает напрямую, поэтому схема здесь обязана совпадать со схемой drift.
//
// Запуск:
//
//	go run ./cmd/build --places data/places-bergen.jsonl \
//	                   --cities data/cities-bergen.jsonl \
//	                   --translations data/translations-bergen.jsonl \
//	                   --out data/content.sqlite
package main

import (
	"bufio"
	"database/sql"
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"sort"
	"time"

	_ "modernc.org/sqlite"

	"github.com/grigorianez/nordguide/pipeline/internal/packer"
)

type place struct {
	ID         string   `json:"id"`
	Category   string   `json:"category"`
	NameNo     string   `json:"name_no"`
	Lat        float64  `json:"lat"`
	Lon        float64  `json:"lon"`
	Importance int      `json:"importance"`
	WikidataID string   `json:"wikidata_id"`
	Website    string   `json:"website"`
	OpeningHrs string   `json:"opening_hours"`
	Season     string   `json:"season"`
	Difficulty string   `json:"difficulty"`
	Tags       []string `json:"tags"`
}

type city struct {
	ID         string  `json:"id"`
	NameNo     string  `json:"name_no"`
	Lat        float64 `json:"lat"`
	Lon        float64 `json:"lon"`
	Population int     `json:"population"`
	Rank       int     `json:"rank"`
}

type photo struct {
	EntityID  string `json:"entity_id"`
	LocalPath string `json:"local_path"`
	Author    string `json:"author"`
	License   string `json:"license"`
	SourceURL string `json:"source_url"`
}

type translation struct {
	EntityType  string `json:"entity_type"`
	EntityID    string `json:"entity_id"`
	Lang        string `json:"lang"`
	Name        string `json:"name"`
	Summary     string `json:"summary"`
	Description string `json:"description"`
	Source      string `json:"source"`
	Quality     int    `json:"quality"`
	SourceURL   string `json:"source_url"`
	RevID       int64  `json:"rev_id"`
}

func main() {
	var (
		placesPath = flag.String("places", "data/places.jsonl", "места от extract")
		citiesPath = flag.String("cities", "data/cities.jsonl", "города от extract")
		transPath  = flag.String("translations", "data/translations.jsonl", "тексты от enrich")
		photosPath = flag.String("photos", "data/photos.jsonl", "фотографии от media")
		outPath    = flag.String("out", "data/content.sqlite", "куда собирать базу")
		regionID   = flag.String("region", "norway", "идентификатор региона")
		regionName = flag.String("region-name", "Norge", "название региона")
		cityRadius = flag.Float64("city-radius", 25, "радиус привязки места к городу, км")
		minCityPop = flag.Int("min-city-rank", 40, "не брать города со значимостью ниже")
	)
	flag.Parse()

	start := time.Now()

	places, err := readJSONL[place](*placesPath)
	if err != nil {
		fatal(err)
	}
	cities, err := readJSONL[city](*citiesPath)
	if err != nil {
		// Города не обязательны: без них соберётся база только с местами.
		fmt.Fprintf(os.Stderr, "предупреждение: города не прочитаны: %v\n", err)
	}
	translations, err := readJSONL[translation](*transPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "предупреждение: тексты не прочитаны: %v\n", err)
	}
	photos, err := readJSONL[photo](*photosPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "предупреждение: фото не прочитаны: %v\n", err)
	}

	// Мелкие деревни только засоряют список городов: их сотни, а смотреть
	// в них нечего. Порог по значимости отсекает их до записи в базу.
	var keptCities []city
	for _, c := range cities {
		if c.Rank >= *minCityPop {
			keptCities = append(keptCities, c)
		}
	}

	fmt.Fprintf(os.Stderr, "Мест: %d, городов: %d (из %d), текстов: %d\n",
		len(places), len(keptCities), len(cities), len(translations))

	if err := os.Remove(*outPath); err != nil && !os.IsNotExist(err) {
		fatal(err)
	}

	db, err := sql.Open("sqlite", *outPath)
	if err != nil {
		fatal(err)
	}
	defer db.Close()

	if _, err := db.Exec(packer.Schema); err != nil {
		fatal(fmt.Errorf("схема: %w", err))
	}
	if _, err := db.Exec(packer.SchemaFTS); err != nil {
		fatal(fmt.Errorf("FTS: %w", err))
	}

	stats, err := fill(db, *regionID, *regionName, places, keptCities,
		translations, photos, *cityRadius)
	if err != nil {
		fatal(err)
	}

	// Версия схемы обязана совпадать с schemaVersion в drift. Иначе
	// приложение примет готовую базу за пустую, попытается создать таблицы
	// заново и упадёт на «table already exists».
	if _, err := db.Exec(fmt.Sprintf("PRAGMA user_version = %d", packer.SchemaVersion)); err != nil {
		fatal(fmt.Errorf("user_version: %w", err))
	}

	fmt.Fprintln(os.Stderr, "Сжатие базы...")
	if _, err := db.Exec("VACUUM"); err != nil {
		fatal(fmt.Errorf("VACUUM: %w", err))
	}
	if _, err := db.Exec("ANALYZE"); err != nil {
		fatal(fmt.Errorf("ANALYZE: %w", err))
	}

	report(stats, *outPath, time.Since(start))
}

type buildStats struct {
	regions, cities, places, tags, translations, ftsRows int
	placesWithCity                                       int
	placesWithText                                       int
	photos, photosRejected                               int
	byLang                                               map[string]int
}

func fill(
	db *sql.DB,
	regionID, regionName string,
	places []place,
	cities []city,
	translations []translation,
	photos []photo,
	cityRadiusKm float64,
) (*buildStats, error) {
	st := &buildStats{byLang: map[string]int{}}

	tx, err := db.Begin()
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	// Регион один: деление Норвегии на настоящие фюльке появится, когда
	// пайплайн пойдёт по всей стране. Сейчас важнее, чтобы схема работала.
	bbox := boundingBox(places, cities)
	if _, err := tx.Exec(
		`INSERT INTO regions (id, name_no, bbox, pack_version) VALUES (?, ?, ?, 1)`,
		regionID, regionName, bbox,
	); err != nil {
		return nil, fmt.Errorf("регион: %w", err)
	}
	st.regions = 1

	cityStmt, err := tx.Prepare(
		`INSERT INTO cities (id, region_id, name_no, lat, lon, population)
		 VALUES (?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return nil, err
	}
	for _, c := range cities {
		pop := any(nil)
		if c.Population > 0 {
			pop = c.Population
		}
		if _, err := cityStmt.Exec(c.ID, regionID, c.NameNo, c.Lat, c.Lon, pop); err != nil {
			return nil, fmt.Errorf("город %s: %w", c.ID, err)
		}
		st.cities++
	}

	placeStmt, err := tx.Prepare(
		`INSERT INTO places (id, city_id, region_id, category, name_no, lat, lon,
		                     opening_hours, website, wikidata_id, season,
		                     difficulty, importance)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return nil, err
	}
	tagStmt, err := tx.Prepare(
		`INSERT OR IGNORE INTO place_tags (place_id, tag) VALUES (?, ?)`)
	if err != nil {
		return nil, err
	}

	for _, p := range places {
		cityID := nearestCity(p.Lat, p.Lon, cities, cityRadiusKm)
		var cityVal any
		if cityID != "" {
			cityVal = cityID
			st.placesWithCity++
		}

		if _, err := placeStmt.Exec(
			p.ID, cityVal, regionID, p.Category, p.NameNo, p.Lat, p.Lon,
			nullable(p.OpeningHrs), nullable(p.Website), nullable(p.WikidataID),
			nullable(p.Season), nullable(p.Difficulty), p.Importance,
		); err != nil {
			return nil, fmt.Errorf("место %s: %w", p.ID, err)
		}
		st.places++

		for _, tag := range p.Tags {
			if _, err := tagStmt.Exec(p.ID, tag); err != nil {
				return nil, fmt.Errorf("тег %s/%s: %w", p.ID, tag, err)
			}
			st.tags++
		}
	}

	trStmt, err := tx.Prepare(
		`INSERT OR REPLACE INTO translations
		   (entity_type, entity_id, lang, name, summary, description,
		    source, quality, source_url, rev_id)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return nil, err
	}
	ftsStmt, err := tx.Prepare(
		`INSERT INTO search_fts (entity_type, entity_id, lang, name, description)
		 VALUES (?, ?, ?, ?, ?)`)
	if err != nil {
		return nil, err
	}

	withText := map[string]bool{}
	for _, t := range translations {
		if _, err := trStmt.Exec(
			t.EntityType, t.EntityID, t.Lang, nullable(t.Name),
			nullable(t.Summary), nullable(t.Description), nullable(t.Source),
			t.Quality, nullable(t.SourceURL), nullableInt(t.RevID),
		); err != nil {
			return nil, fmt.Errorf("текст %s/%s: %w", t.EntityID, t.Lang, err)
		}
		st.translations++
		st.byLang[t.Lang]++
		withText[t.EntityID] = true

		// В индекс кладём имя и краткое описание. Полный текст не индексируем:
		// он раздувает индекс в разы, а находится по нему в основном шум.
		if _, err := ftsStmt.Exec(
			t.EntityType, t.EntityID, t.Lang, t.Name, t.Summary,
		); err != nil {
			return nil, fmt.Errorf("FTS %s/%s: %w", t.EntityID, t.Lang, err)
		}
		st.ftsRows++
	}
	st.placesWithText = len(withText)

	// Фотографии. Автор и лицензия объявлены NOT NULL: снимок без них
	// не имеет права попасть в базу, это требование §7 спецификации.
	photoStmt, err := tx.Prepare(
		`INSERT INTO photos (place_id, city_id, path_thumb, path_full,
		                     author, license, source_url)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return nil, err
	}

	cityIDs := make(map[string]bool, len(cities))
	for _, c := range cities {
		cityIDs[c.ID] = true
	}

	for _, ph := range photos {
		if ph.Author == "" || ph.License == "" || ph.SourceURL == "" {
			st.photosRejected++
			continue
		}

		var placeID, cityID any
		if cityIDs[ph.EntityID] {
			cityID = ph.EntityID
		} else {
			placeID = ph.EntityID
		}

		// Уменьшенная копия у нас одна: отдельный thumb появится, когда
		// понадобятся полноразмерные снимки в галерее.
		if _, err := photoStmt.Exec(placeID, cityID, ph.LocalPath,
			ph.LocalPath, ph.Author, ph.License, ph.SourceURL); err != nil {
			return nil, fmt.Errorf("фото %s: %w", ph.EntityID, err)
		}
		st.photos++
	}

	// Заглавное фото города — чтобы карточка в обзоре не лезла за ним
	// отдельным запросом на каждую плитку.
	if _, err := tx.Exec(`
		UPDATE cities SET hero_photo = (
			SELECT path_thumb FROM photos WHERE photos.city_id = cities.id LIMIT 1
		) WHERE EXISTS (
			SELECT 1 FROM photos WHERE photos.city_id = cities.id
		)`); err != nil {
		return nil, fmt.Errorf("hero_photo: %w", err)
	}

	return st, tx.Commit()
}

// nearestCity привязывает место к городу, который его «притягивает».
//
// Не просто ближайший: у пригорода координата может оказаться ближе, чем
// у центра большого города, и тогда бергенские достопримечательности
// разъезжаются по деревням. В первом прогоне так и вышло — у посёлка
// Syfteland оказалось 161 место, хотя почти всё это Берген.
//
// Поэтому расстояние делится на «притяжение» города: крупный центр
// собирает объекты с большего радиуса, хутор — только то, что рядом.
func nearestCity(lat, lon float64, cities []city, radiusKm float64) string {
	best := ""
	bestScore := math.MaxFloat64

	for _, c := range cities {
		d := distanceMeters(lat, lon, c.Lat, c.Lon)
		pull := cityPull(c)
		if d > radiusKm*1000*pull {
			continue
		}
		score := d / pull
		if score < bestScore {
			bestScore = score
			best = c.ID
		}
	}
	return best
}

// cityPull — во сколько раз охотнее город забирает себе окрестные объекты.
//
// Значения подобраны так, чтобы Берген (270 тыс.) уверенно перетягивал
// объекты у соседних посёлков, но Гейрангер (200 жителей) не терял свои:
// туристические посёлки почти всегда стоят обособленно, и конкуренции
// за их объекты просто нет.
func cityPull(c city) float64 {
	switch {
	case c.Population >= 100000:
		return 4.0
	case c.Population >= 20000:
		return 2.0
	case c.Population >= 5000:
		return 1.4
	case c.Population >= 1000:
		return 1.0
	default:
		return 0.7
	}
}

const degToRad = math.Pi / 180

func distanceMeters(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadius = 6371000.0
	dLat := (lat2 - lat1) * degToRad
	dLon := (lon2 - lon1) * degToRad
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*degToRad)*math.Cos(lat2*degToRad)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	return earthRadius * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

func boundingBox(places []place, cities []city) string {
	minLon, minLat := 180.0, 90.0
	maxLon, maxLat := -180.0, -90.0

	upd := func(lat, lon float64) {
		minLat = math.Min(minLat, lat)
		maxLat = math.Max(maxLat, lat)
		minLon = math.Min(minLon, lon)
		maxLon = math.Max(maxLon, lon)
	}
	for _, p := range places {
		upd(p.Lat, p.Lon)
	}
	for _, c := range cities {
		upd(c.Lat, c.Lon)
	}
	if minLat > maxLat {
		return "0,0,0,0"
	}
	return fmt.Sprintf("%.4f,%.4f,%.4f,%.4f", minLon, minLat, maxLon, maxLat)
}

func readJSONL[T any](path string) ([]T, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var out []T
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 16*1024*1024)
	for sc.Scan() {
		if len(sc.Bytes()) == 0 {
			continue
		}
		var item T
		if err := json.Unmarshal(sc.Bytes(), &item); err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}
		out = append(out, item)
	}
	return out, sc.Err()
}

func nullable(s string) any {
	if s == "" {
		return nil
	}
	return s
}

func nullableInt(n int64) any {
	if n == 0 {
		return nil
	}
	return n
}

func report(st *buildStats, outPath string, elapsed time.Duration) {
	info, err := os.Stat(outPath)
	size := int64(0)
	if err == nil {
		size = info.Size()
	}

	fmt.Printf("\n=== build: результат ===\n\n")
	fmt.Printf("Файл:      %s\n", outPath)
	fmt.Printf("Размер:    %.1f МБ\n", float64(size)/(1<<20))
	fmt.Printf("Время:     %s\n\n", elapsed.Round(time.Millisecond))

	fmt.Println("Записей:")
	fmt.Printf("  регионов:     %d\n", st.regions)
	fmt.Printf("  городов:      %d\n", st.cities)
	fmt.Printf("  мест:         %d\n", st.places)
	fmt.Printf("  из них с городом: %d (%d%%)\n",
		st.placesWithCity, percent(st.placesWithCity, st.places))
	fmt.Printf("  из них с текстом: %d (%d%%)\n",
		st.placesWithText, percent(st.placesWithText, st.places))
	fmt.Printf("  тегов:        %d\n", st.tags)
	fmt.Printf("  фотографий:   %d\n", st.photos)
	if st.photosRejected > 0 {
		fmt.Printf("  отброшено фото без атрибуции: %d\n", st.photosRejected)
	}
	fmt.Printf("  переводов:    %d\n", st.translations)
	fmt.Printf("  строк поиска: %d\n", st.ftsRows)

	if len(st.byLang) > 0 {
		fmt.Println("\nТексты по языкам:")
		langs := make([]string, 0, len(st.byLang))
		for l := range st.byLang {
			langs = append(langs, l)
		}
		sort.Strings(langs)
		for _, l := range langs {
			fmt.Printf("  %-4s %d\n", l, st.byLang[l])
		}
	}

	fmt.Printf("\nБюджет базы по §5 спеки — около 40 МБ на 15 000 объектов.\n")
}

func percent(part, total int) int {
	if total == 0 {
		return 0
	}
	return part * 100 / total
}

func fatal(err error) {
	fmt.Fprintf(os.Stderr, "ошибка: %v\n", err)
	os.Exit(1)
}
