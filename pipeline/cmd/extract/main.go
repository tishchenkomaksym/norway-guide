// Команда extract — первый этап пайплайна (§3 спецификации).
//
// Читает выгрузку OpenStreetMap и вытаскивает интересные гиду объекты:
// фьорды, водопады, музеи, смотровые площадки, ставкирки, ледники, тропы.
// Результат — JSONL с сырыми тегами, из которого дальше собирается SQLite.
//
// Почему два прохода. У точки координаты есть прямо в ней, а у линии и
// отношения — только ссылки на узлы. Держать в памяти все 60 миллионов узлов
// Норвегии нельзя, поэтому первый проход собирает, какие узлы вообще нужны,
// а второй забирает только их координаты.
//
// Запуск:
//
//	go run ./cmd/extract --in data/norway-latest.osm.pbf --out data/places.jsonl
//	go run ./cmd/extract --bbox 4.0,59.5,8.5,62.5   # только Vestland
package main

import (
	"bufio"
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/paulmach/osm"
	"github.com/paulmach/osm/osmpbf"

	ng "github.com/grigorianez/nordguide/pipeline/internal/osm"
)

type bbox struct {
	minLon, minLat, maxLon, maxLat float64
}

func (b *bbox) contains(lat, lon float64) bool {
	if b == nil {
		return true
	}
	return lon >= b.minLon && lon <= b.maxLon && lat >= b.minLat && lat <= b.maxLat
}

func parseBbox(s string) (*bbox, error) {
	if s == "" {
		return nil, nil
	}
	parts := strings.Split(s, ",")
	if len(parts) != 4 {
		return nil, fmt.Errorf("bbox: нужно 4 числа minLon,minLat,maxLon,maxLat, получено %d", len(parts))
	}
	var v [4]float64
	for i, p := range parts {
		f, err := strconv.ParseFloat(strings.TrimSpace(p), 64)
		if err != nil {
			return nil, fmt.Errorf("bbox: %q не число", p)
		}
		v[i] = f
	}
	return &bbox{v[0], v[1], v[2], v[3]}, nil
}

func main() {
	var (
		inPath   = flag.String("in", "data/norway-latest.osm.pbf", "выгрузка OSM")
		outPath  = flag.String("out", "data/places.jsonl", "куда писать места")
		citiesTo = flag.String("cities", "data/cities.jsonl", "куда писать города")
		bboxStr  = flag.String("bbox", "", "ограничить область: minLon,minLat,maxLon,maxLat")
	)
	flag.Parse()

	box, err := parseBbox(*bboxStr)
	if err != nil {
		fatal(err)
	}

	start := time.Now()

	// Проход 1: точки с тегами обрабатываем сразу, для линий и отношений
	// запоминаем, какие узлы понадобятся.
	fmt.Fprintln(os.Stderr, "Проход 1: объекты с тегами...")
	pass1, err := scanTagged(*inPath, box)
	if err != nil {
		fatal(err)
	}
	fmt.Fprintf(os.Stderr, "  точек: %d, линий и отношений: %d, нужных узлов: %d\n",
		len(pass1.places), len(pass1.ways), len(pass1.neededNodes))

	// Проход 2: координаты нужных узлов.
	if len(pass1.neededNodes) > 0 {
		fmt.Fprintln(os.Stderr, "Проход 2: координаты узлов...")
		if err := fillNodeCoords(*inPath, pass1.neededNodes); err != nil {
			fatal(err)
		}
	}

	// Центроиды линий и отношений.
	for _, w := range pass1.ways {
		lat, lon, ok := centroid(w.nodes, pass1.neededNodes)
		if !ok || !box.contains(lat, lon) {
			continue
		}
		if p, ok := ng.FromTags(w.id, w.tags, lat, lon); ok {
			pass1.places = append(pass1.places, p)
		}
	}

	if err := writeJSONL(*outPath, pass1.places); err != nil {
		fatal(err)
	}
	if err := writeJSONL(*citiesTo, pass1.cities); err != nil {
		fatal(err)
	}
	fmt.Fprintf(os.Stderr, "Городов: %d → %s\n", len(pass1.cities), *citiesTo)

	stats := ng.NewStats()
	stats.TotalScanned = pass1.scanned
	for _, p := range pass1.places {
		stats.Add(p)
	}
	report(stats, *outPath, time.Since(start))
}

type coord struct {
	lat, lon float64
	filled   bool
}

type wayRef struct {
	id    string
	tags  map[string]string
	nodes []osm.NodeID
}

type pass1Result struct {
	places      []ng.Place
	cities      []ng.City
	ways        []wayRef
	neededNodes map[osm.NodeID]*coord
	scanned     int64
}

// scanTagged — первый проход: всё, у чего есть подходящие теги.
func scanTagged(path string, box *bbox) (*pass1Result, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	scanner := osmpbf.New(context.Background(), f, runtime.NumCPU())
	defer scanner.Close()

	res := &pass1Result{neededNodes: map[osm.NodeID]*coord{}}

	for scanner.Scan() {
		res.scanned++
		switch o := scanner.Object().(type) {
		case *osm.Node:
			if len(o.Tags) == 0 {
				continue
			}
			if !box.contains(o.Lat, o.Lon) {
				continue
			}
			tags := tagMap(o.Tags)
			id := fmt.Sprintf("osm:node/%d", o.ID)
			// Населённые пункты — отдельная сущность со своим экраном,
			// поэтому проверяются раньше и не попадают в places.
			if c, ok := ng.CityFromTags("city:"+id, tags, o.Lat, o.Lon); ok {
				res.cities = append(res.cities, c)
				continue
			}
			if p, ok := ng.FromTags(id, tags, o.Lat, o.Lon); ok {
				res.places = append(res.places, p)
			}

		case *osm.Way:
			if len(o.Tags) == 0 || len(o.Nodes) == 0 {
				continue
			}
			tags := tagMap(o.Tags)
			if _, _, ok := ng.Classify(tags); !ok {
				continue
			}
			if ng.Name(tags) == "" {
				continue
			}
			refs := make([]osm.NodeID, 0, len(o.Nodes))
			for _, n := range o.Nodes {
				refs = append(refs, n.ID)
				if _, exists := res.neededNodes[n.ID]; !exists {
					res.neededNodes[n.ID] = &coord{}
				}
			}
			res.ways = append(res.ways, wayRef{
				id:    fmt.Sprintf("osm:way/%d", o.ID),
				tags:  tags,
				nodes: refs,
			})

		case *osm.Relation:
			// Отношения обрабатываем только как носители тегов: их геометрия
			// собирается из участников, что для MVP избыточно. Координату
			// возьмём от первого участника-линии на следующей итерации проекта.
			continue
		}
	}

	return res, scanner.Err()
}

// fillNodeCoords — второй проход: координаты для узлов из needed.
func fillNodeCoords(path string, needed map[osm.NodeID]*coord) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()

	scanner := osmpbf.New(context.Background(), f, runtime.NumCPU())
	defer scanner.Close()

	// Узлы без тегов при втором проходе не пропускаем: именно они и есть
	// геометрия линий.
	scanner.SkipWays = true
	scanner.SkipRelations = true

	for scanner.Scan() {
		n, ok := scanner.Object().(*osm.Node)
		if !ok {
			continue
		}
		if c, need := needed[n.ID]; need {
			c.lat, c.lon, c.filled = n.Lat, n.Lon, true
		}
	}
	return scanner.Err()
}

// centroid — среднее по узлам линии.
//
// Для вытянутых объектов вроде фьорда это грубо, но достаточно: точка нужна,
// чтобы показать объект в списке «рядом» и открыть внешние карты, а не для
// геометрических расчётов.
func centroid(refs []osm.NodeID, coords map[osm.NodeID]*coord) (float64, float64, bool) {
	var sumLat, sumLon float64
	var n int
	for _, id := range refs {
		if c, ok := coords[id]; ok && c.filled {
			sumLat += c.lat
			sumLon += c.lon
			n++
		}
	}
	if n == 0 {
		return 0, 0, false
	}
	return sumLat / float64(n), sumLon / float64(n), true
}

func tagMap(tags osm.Tags) map[string]string {
	m := make(map[string]string, len(tags))
	for _, t := range tags {
		m[t.Key] = t.Value
	}
	return m
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

func report(s *ng.Stats, outPath string, elapsed time.Duration) {
	fmt.Printf("\n=== extract: результат ===\n\n")
	fmt.Printf("Просмотрено объектов OSM: %d\n", s.TotalScanned)
	fmt.Printf("Извлечено мест:           %d\n", s.Matched)
	fmt.Printf("Файл:                     %s\n", outPath)
	fmt.Printf("Время:                    %s\n\n", elapsed.Round(time.Second))

	if s.Matched == 0 {
		fmt.Println("Ничего не извлечено — проверьте bbox и путь к выгрузке.")
		return
	}

	fmt.Println("По категориям:")
	cats := make([]string, 0, len(s.ByCategory))
	for c := range s.ByCategory {
		cats = append(cats, c)
	}
	sort.Slice(cats, func(i, j int) bool {
		return s.ByCategory[cats[i]] > s.ByCategory[cats[j]]
	})
	for _, c := range cats {
		total := s.ByCategory[c]
		wd := s.WikidataByCategory[c]
		fmt.Printf("  %-12s %6d   с wikidata: %5d (%d%%)\n",
			c, total, wd, percent(wd, total))
	}

	fmt.Printf("\nСвязи с внешними источниками — от этого зависит весь enrich:\n")
	fmt.Printf("  wikidata:  %d из %d (%d%%)\n",
		s.WithWikidata, s.Matched, percent(s.WithWikidata, s.Matched))
	fmt.Printf("  wikipedia: %d из %d (%d%%)\n",
		s.WithWikipedia, s.Matched, percent(s.WithWikipedia, s.Matched))

	fmt.Println("\nКак читать: если доля wikidata низкая, обогащение по тегу")
	fmt.Println("не покроет большинство мест и понадобится нечёткий матчинг")
	fmt.Println("по имени и координатам. См. docs/pipeline-plan.md, раздел «Риски».")
}

func percent(part, total int64) int64 {
	if total == 0 {
		return 0
	}
	return part * 100 / total
}

func fatal(err error) {
	fmt.Fprintf(os.Stderr, "ошибка: %v\n", err)
	os.Exit(1)
}
