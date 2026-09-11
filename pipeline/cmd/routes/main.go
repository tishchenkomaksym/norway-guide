// Команда routes составляет пешие маршруты по городам.
//
// Что это такое и чем не является. Это не навигация и не оптимальный
// обход: приложение не знает ни улиц, ни переходов, ни расписаний. Это
// ответ на вопрос «у меня полдня в Бергене, что успею посмотреть» —
// список главных мест в шаговой доступности, выстроенный так, чтобы
// не метаться по городу.
//
// Как строится порядок. От самого значимого места жадно идём к ближайшему
// непосещённому — «ближайший сосед». Оптимальным такой маршрут не бывает,
// но разница с оптимальным на шести-восьми точках в пределах пары
// километров исчисляется минутами, а понятность важнее: человек видит
// осмысленную цепочку, а не прыжки через центр.
//
// Откуда время. Расстояние по прямой умножается на 1.35 — поправка на то,
// что по улицам ходят не по прямой (эта величина известна как «коэффициент
// извилистости» и для городской сетки обычно 1.2–1.5). Скорость пешехода
// 4 км/ч. Плюс время на осмотр по категории: музей дольше смотровой.
// Числа приблизительные, и приложение показывает их как «около».
//
// Запуск:
//
//	go run ./cmd/routes --db data/content.sqlite --out data/routes.jsonl
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
)

// Route — маршрут и его остановки.
type Route struct {
	ID         string  `json:"id"`
	CityID     string  `json:"city_id"`
	CityName   string  `json:"city_name"`
	DurationH  float64 `json:"duration_h"`
	DistanceKm float64 `json:"distance_km"`
	Stops      []Stop  `json:"stops"`
}

type Stop struct {
	PlaceID string `json:"place_id"`
	Ord     int    `json:"ord"`
	// Note остаётся пустым: подписи к остановкам — это текст, который
	// надо писать руками и переводить на шесть языков. Придумывать их
	// автоматически значит наполнить приложение водой вида «приятное
	// место для прогулки».
	Note string `json:"note,omitempty"`
}

type place struct {
	id         string
	name       string
	category   string
	lat, lon   float64
	importance int
	topRank    int
}

// Сколько минут закладывать на осмотр. Оценки грубые и намеренно
// скромные: лучше человек успеет больше, чем окажется, что маршрут
// на полдня не помещается в день.
var visitMinutes = map[string]int{
	"museum":    50,
	"church":    20,
	"viewpoint": 15,
	"waterfall": 20,
	"fjord":     30,
	"beach":     30,
	"lake":      20,
	"river":     15,
	"glacier":   40,
	"hike":      60,
}

const (
	walkingSpeedKmh = 4.0
	// Поправка на то, что по улицам не ходят по прямой.
	detourFactor = 1.35
)

func main() {
	var (
		dbPath          = flag.String("db", "data/content.sqlite", "контентная база")
		outPath         = flag.String("out", "data/routes.jsonl", "куда писать маршруты")
		radiusKm        = flag.Float64("radius", 2.0, "радиус от центра города, км")
		maxStops        = flag.Int("max-stops", 7, "сколько остановок в маршруте")
		minStops        = flag.Int("min-stops", 4, "меньше этого маршрут не составляем")
		minImport       = flag.Int("min-importance", 40, "не брать места ниже этой значимости")
		maxSameCategory = flag.Int("max-same", 3, "сколько мест одной категории пускать в маршрут")
	)
	flag.Parse()

	start := time.Now()

	db, err := sql.Open("sqlite", *dbPath)
	if err != nil {
		fatal(err)
	}
	defer db.Close()

	cities, err := loadCities(db)
	if err != nil {
		fatal(err)
	}

	out, err := os.Create(*outPath)
	if err != nil {
		fatal(err)
	}
	defer out.Close()
	w := bufio.NewWriter(out)
	defer w.Flush()
	enc := json.NewEncoder(w)

	var built, skipped int
	var totalStops int
	byStops := map[int]int{}

	for _, c := range cities {
		places, err := loadPlaces(db, c.id, c.lat, c.lon, *radiusKm, *minImport)
		if err != nil {
			fatal(err)
		}
		places = pickDiverse(places, *maxStops, *maxSameCategory)
		if len(places) < *minStops {
			skipped++
			continue
		}

		route := buildRoute(c, places)
		if err := enc.Encode(route); err != nil {
			fatal(err)
		}
		built++
		totalStops += len(route.Stops)
		byStops[len(route.Stops)]++
	}

	fmt.Printf("\nМаршруты составлены за %s\n\n", time.Since(start).Round(time.Millisecond))
	fmt.Printf("  городов обработано: %d\n", len(cities))
	fmt.Printf("  маршрутов:          %d\n", built)
	fmt.Printf("  пропущено городов:  %d (мест меньше %d)\n", skipped, *minStops)
	if built > 0 {
		fmt.Printf("  остановок в среднем: %.1f\n", float64(totalStops)/float64(built))
	}
	fmt.Printf("  файл:               %s\n", *outPath)
}

type city struct {
	id, name string
	lat, lon float64
}

func loadCities(db *sql.DB) ([]city, error) {
	rows, err := db.Query(
		`SELECT id, name_no, lat, lon FROM cities ORDER BY population DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []city
	for rows.Next() {
		var c city
		if err := rows.Scan(&c.id, &c.name, &c.lat, &c.lon); err != nil {
			return nil, err
		}
		out = append(out, c)
	}
	return out, rows.Err()
}

// loadPlaces возвращает места города в пешей доступности, по убыванию
// значимости.
func loadPlaces(db *sql.DB, cityID string, lat, lon, radiusKm float64,
	minImportance int) ([]place, error) {
	rows, err := db.Query(`
	  SELECT id, name_no, category, lat, lon, importance, top_rank
	    FROM places
	   WHERE city_id = ? AND importance >= ?
	   ORDER BY importance DESC`, cityID, minImportance)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []place
	for rows.Next() {
		var p place
		if err := rows.Scan(&p.id, &p.name, &p.category, &p.lat, &p.lon,
			&p.importance, &p.topRank); err != nil {
			return nil, err
		}
		if distanceKm(lat, lon, p.lat, p.lon) <= radiusKm {
			out = append(out, p)
		}
	}
	return out, rows.Err()
}

// pickDiverse отбирает остановки, не давая маршруту выродиться в список
// однотипных мест.
//
// Первая версия просто брала верх списка по значимости — и выдала для Осло
// семь музеев подряд на семь с половиной часов. Дело не в ошибке отбора,
// а в самой шкале: музей размечен в OSM подробнее сквера или смотровой,
// у него больше тегов и своя статья, поэтому по importance он почти всегда
// выигрывает. Прогулка по городу из одних музеев — это не прогулка.
//
// Поэтому на категорию вводится потолок. Места из курируемого топа
// пропускаются вперёд независимо от него: если в городе есть Брюгген или
// Оперный театр, маршрут без них выглядел бы странно.
func pickDiverse(places []place, limit, maxSame int) []place {
	sort.SliceStable(places, func(i, j int) bool {
		// Топ впереди всех: top_rank 1 значимее любой значимости.
		ti, tj := places[i].topRank, places[j].topRank
		if (ti > 0) != (tj > 0) {
			return ti > 0
		}
		if ti > 0 && tj > 0 && ti != tj {
			return ti < tj
		}
		return places[i].importance > places[j].importance
	})

	used := map[string]int{}
	out := make([]place, 0, limit)
	for _, p := range places {
		if len(out) >= limit {
			break
		}
		// Место из топа берём всегда: потолок категории на него не влияет.
		if p.topRank == 0 && used[p.category] >= maxSame {
			continue
		}
		used[p.category]++
		out = append(out, p)
	}
	return out
}

// buildRoute выстраивает порядок обхода и считает время.
func buildRoute(c city, places []place) Route {
	// Начинаем с самого значимого места: если человек сойдёт с маршрута
	// на середине, он успеет увидеть главное.
	sort.SliceStable(places, func(i, j int) bool {
		return places[i].importance > places[j].importance
	})

	visited := make([]bool, len(places))
	order := []place{places[0]}
	visited[0] = true

	for len(order) < len(places) {
		last := order[len(order)-1]
		best, bestDist := -1, math.MaxFloat64
		for i, p := range places {
			if visited[i] {
				continue
			}
			if d := distanceKm(last.lat, last.lon, p.lat, p.lon); d < bestDist {
				best, bestDist = i, d
			}
		}
		if best < 0 {
			break
		}
		visited[best] = true
		order = append(order, places[best])
	}

	var walkKm float64
	var visitMin int
	stops := make([]Stop, 0, len(order))
	for i, p := range order {
		if i > 0 {
			walkKm += distanceKm(order[i-1].lat, order[i-1].lon, p.lat, p.lon)
		}
		minutes, ok := visitMinutes[p.category]
		if !ok {
			minutes = 20
		}
		visitMin += minutes
		stops = append(stops, Stop{PlaceID: p.id, Ord: i})
	}

	walkKm *= detourFactor
	hours := walkKm/walkingSpeedKmh + float64(visitMin)/60

	return Route{
		ID:         "route:" + c.id,
		CityID:     c.id,
		CityName:   c.name,
		DurationH:  math.Round(hours*10) / 10,
		DistanceKm: math.Round(walkKm*10) / 10,
		Stops:      stops,
	}
}

// distanceKm — гаверсинус.
func distanceKm(lat1, lon1, lat2, lon2 float64) float64 {
	const earthKm = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)
	return earthKm * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "ошибка:", err)
	os.Exit(1)
}
