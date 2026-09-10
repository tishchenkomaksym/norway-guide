// Команда media — четвёртый этап пайплайна (§3 спецификации).
//
// Скачивает фотографии мест и городов с Wikimedia Commons. Лицензия
// проверяется ДО скачивания: файлы под NonCommercial, NoDerivatives и fair
// use отбрасываются, а у остальных сохраняется автор и ссылка на источник.
// Без этого приложение нельзя публиковать (§7 спецификации).
//
// Запуск:
//
//	go run ./cmd/media --places data/places-norway.jsonl \
//	                   --cities data/cities-norway.jsonl \
//	                   --out data/photos.jsonl --dir ../app/assets/photos
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/grigorianez/nordguide/pipeline/internal/wiki"
)

type entity struct {
	ID         string `json:"id"`
	NameNo     string `json:"name_no"`
	Importance int    `json:"importance"`
	Rank       int    `json:"rank"`
	WikidataID string `json:"wikidata_id"`
}

// score — по чему отбирать: у мест значимость, у городов ранг.
func (e entity) score() int {
	if e.Importance > 0 {
		return e.Importance
	}
	return e.Rank
}

func main() {
	var (
		placesPath = flag.String("places", "data/places-norway.jsonl", "места")
		citiesPath = flag.String("cities", "data/cities-norway.jsonl", "города")
		outPath    = flag.String("out", "data/photos.jsonl", "куда писать метаданные")
		dir        = flag.String("dir", "../app/assets/photos", "куда класть файлы")
		cacheDir   = flag.String("cache", "data/cache", "дисковый кэш запросов")
		width      = flag.Int("width", 640, "ширина уменьшенной копии, px")
		limit      = flag.Int("limit", 200, "сколько объектов обработать")
	)
	flag.Parse()

	start := time.Now()

	places, err := readJSONL[entity](*placesPath)
	if err != nil {
		fatal(err)
	}
	cities, err := readJSONL[entity](*citiesPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "предупреждение: города не прочитаны: %v\n", err)
	}

	// Города обрабатываем первыми: заглавное фото города нужнее, чем снимок
	// сто первой церкви — на экране обзора город виден каждому.
	targets := pick(cities, *limit/3)
	targets = append(targets, pick(places, *limit-len(targets))...)

	fmt.Fprintf(os.Stderr, "К обработке: %d объектов\n", len(targets))
	if len(targets) == 0 {
		fmt.Fprintln(os.Stderr, "нечего обрабатывать")
		return
	}

	client, err := wiki.NewClient(*cacheDir)
	if err != nil {
		fatal(err)
	}

	ids := make([]string, 0, len(targets))
	for _, t := range targets {
		ids = append(ids, t.WikidataID)
	}

	fmt.Fprintln(os.Stderr, "Wikidata: ищем изображения (P18)...")
	names, err := client.FetchImageNames(ids)
	if err != nil {
		fmt.Fprintf(os.Stderr, "предупреждение: %v\n", err)
	}
	fmt.Fprintf(os.Stderr, "  с изображением: %d из %d\n", len(names), len(ids))

	if err := os.MkdirAll(*dir, 0o755); err != nil {
		fatal(err)
	}

	var (
		photos       []wiki.Photo
		failures     []string
		noImage      int
		rejectedLic  int
		downloaded   int
		totalBytes   int64
		licenseCount = map[string]int{}
	)

	for i, t := range targets {
		fmt.Fprintf(os.Stderr, "\r  %d/%d  %-38.38s", i+1, len(targets), t.NameNo)

		fileName, ok := names[t.WikidataID]
		if !ok {
			noImage++
			continue
		}

		info, err := client.FetchImageInfo(fileName, *width)
		if err != nil {
			failures = append(failures, err.Error())
			continue
		}
		if info == nil {
			// Либо лицензия не подходит, либо не указан автор.
			rejectedLic++
			continue
		}

		local := filepath.Join(*dir, safeName(t.ID)+extOf(fileName))
		size, err := download(info.LocalPath, local)
		if err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", t.NameNo, err))
			continue
		}

		info.EntityID = t.ID
		info.LocalPath = "assets/photos/" + filepath.Base(local)
		photos = append(photos, *info)
		licenseCount[info.License]++
		downloaded++
		totalBytes += size
	}
	fmt.Fprintln(os.Stderr)

	if err := writeJSONL(*outPath, photos); err != nil {
		fatal(err)
	}

	report(reportData{
		targets:     len(targets),
		downloaded:  downloaded,
		noImage:     noImage,
		rejectedLic: rejectedLic,
		failures:    failures,
		licenses:    licenseCount,
		bytes:       totalBytes,
		outPath:     *outPath,
		dir:         *dir,
		elapsed:     time.Since(start),
	})
}

// pick отбирает объекты с Wikidata по убыванию значимости.
func pick(list []entity, n int) []entity {
	var out []entity
	for _, e := range list {
		if e.WikidataID != "" {
			out = append(out, e)
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].score() > out[j].score() })
	if n > 0 && len(out) > n {
		out = out[:n]
	}
	return out
}

func download(url, dest string) (int64, error) {
	if info, err := os.Stat(dest); err == nil {
		// Уже скачано: повторный прогон не должен тянуть файлы заново.
		return info.Size(), nil
	}

	tmp := dest + ".tmp"
	if err := runCurl(url, tmp); err != nil {
		return 0, err
	}
	info, err := os.Stat(tmp)
	if err != nil {
		return 0, err
	}
	if info.Size() == 0 {
		os.Remove(tmp)
		return 0, fmt.Errorf("пустой файл")
	}
	if err := os.Rename(tmp, dest); err != nil {
		return 0, err
	}
	return info.Size(), nil
}

func safeName(id string) string {
	r := strings.NewReplacer(":", "_", "/", "_", "\\", "_")
	return r.Replace(id)
}

func extOf(fileName string) string {
	ext := strings.ToLower(filepath.Ext(fileName))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".webp":
		return ext
	default:
		// Commons отдаёт уменьшенные копии SVG и TIFF как PNG.
		return ".png"
	}
}

type reportData struct {
	targets, downloaded, noImage, rejectedLic int
	failures                                  []string
	licenses                                  map[string]int
	bytes                                     int64
	outPath, dir                              string
	elapsed                                   time.Duration
}

func report(d reportData) {
	fmt.Printf("\n=== media: результат ===\n\n")
	fmt.Printf("Объектов:            %d\n", d.targets)
	fmt.Printf("Скачано фотографий:  %d (%d%%)\n",
		d.downloaded, percent(d.downloaded, d.targets))
	fmt.Printf("Нет изображения:     %d\n", d.noImage)
	fmt.Printf("Отброшено по лицензии или без автора: %d\n", d.rejectedLic)
	fmt.Printf("Объём:               %.1f МБ\n", float64(d.bytes)/(1<<20))
	if d.downloaded > 0 {
		fmt.Printf("В среднем на файл:   %.0f КБ\n",
			float64(d.bytes)/float64(d.downloaded)/1024)
	}
	fmt.Printf("Файлы:               %s\n", d.dir)
	fmt.Printf("Метаданные:          %s\n", d.outPath)
	fmt.Printf("Время:               %s\n", d.elapsed.Round(time.Second))

	if len(d.licenses) > 0 {
		fmt.Println("\nЛицензии скачанного:")
		keys := make([]string, 0, len(d.licenses))
		for k := range d.licenses {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			fmt.Printf("  %-24s %d\n", k, d.licenses[k])
		}
	}

	if len(d.failures) > 0 {
		fmt.Printf("\nОШИБКИ: %d\n", len(d.failures))
		for i, f := range d.failures {
			if i >= 10 {
				fmt.Printf("  ... и ещё %d\n", len(d.failures)-10)
				break
			}
			fmt.Printf("  %s\n", f)
		}
	} else {
		fmt.Println("\nСетевых ошибок нет.")
	}
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

func writeJSONL[T any](path string, items []T) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	w := bufio.NewWriterSize(f, 1<<20)
	defer w.Flush()

	enc := json.NewEncoder(w)
	for _, it := range items {
		if err := enc.Encode(it); err != nil {
			return err
		}
	}
	return nil
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
