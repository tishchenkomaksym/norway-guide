// Команда toplist дописывает в набор мест те объекты топа, которых нет
// в извлечении из OSM.
//
// Автоматическое извлечение видит не всё: парк скульптур, лыжный трамплин,
// горная дорога, железная дорога и архипелаг не попадают ни в одну из наших
// категорий, хотя это одни из самых посещаемых мест страны. Список задан
// руками в internal/toplist, здесь он превращается в обычные записи мест —
// чтобы дальше их обогащали те же enrich и media, без отдельной ветки кода.
//
// Идемпотентность: объекты, уже найденные в OSM, не дублируются. Совпадение
// ищется по идентификатору Wikidata, а не по названию: названия в OSM
// пишутся по-разному, и «Vøringsfossen» против «Vøringfossen» дало бы
// два места вместо одного.
//
// Запуск:
//
//	go run ./cmd/toplist --places data/places-norway.jsonl \
//	                     --out data/places-curated.jsonl
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/grigorianez/nordguide/pipeline/internal/toplist"
)

type place struct {
	ID         string            `json:"id"`
	Category   string            `json:"category"`
	NameNo     string            `json:"name_no"`
	Lat        float64           `json:"lat"`
	Lon        float64           `json:"lon"`
	Importance int               `json:"importance"`
	WikidataID string            `json:"wikidata_id"`
	Wikipedia  string            `json:"wikipedia"`
	Tags       []string          `json:"tags"`
	RawTags    map[string]string `json:"raw_tags"`
}

func main() {
	var (
		placesPath = flag.String("places", "data/places-norway.jsonl", "места от extract")
		outPath    = flag.String("out", "data/places-curated.jsonl", "куда писать недостающие")
	)
	flag.Parse()

	known := map[string]string{} // wikidata_id -> id места
	f, err := os.Open(*placesPath)
	if err != nil {
		fatal(err)
	}
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 1<<20), 1<<22)
	for sc.Scan() {
		var p place
		if err := json.Unmarshal(sc.Bytes(), &p); err != nil {
			continue
		}
		if p.WikidataID != "" {
			known[p.WikidataID] = p.ID
		}
	}
	f.Close()
	if err := sc.Err(); err != nil {
		fatal(err)
	}

	out, err := os.Create(*outPath)
	if err != nil {
		fatal(err)
	}
	defer out.Close()
	w := bufio.NewWriter(out)
	defer w.Flush()

	var added, existed int
	for _, a := range toplist.All {
		if id, ok := known[a.QID]; ok {
			existed++
			fmt.Fprintf(os.Stderr, "  %2d. %-24s уже есть (%s)\n", a.Rank, a.Name, id)
			continue
		}
		p := place{
			// Префикс curated: отличает курируемую запись от объекта OSM.
			// Без него неясно, откуда взялись координаты, и при следующем
			// извлечении такую запись невозможно отличить от настоящей.
			ID:       "curated:" + a.QID,
			Category: a.Category,
			NameNo:   a.Name,
			Lat:      a.Lat,
			Lon:      a.Lon,
			// Топ по определению значимее всего остального: список
			// собран по посещаемости, а не по полноте разметки.
			Importance: 100,
			WikidataID: a.QID,
			Tags:       []string{},
			RawTags:    map[string]string{"source": "toplist"},
		}
		b, err := json.Marshal(p)
		if err != nil {
			fatal(err)
		}
		w.Write(b)
		w.WriteByte('\n')
		added++
		fmt.Fprintf(os.Stderr, "  %2d. %-24s добавлено\n", a.Rank, a.Name)
	}

	fmt.Printf("\nКурируемый список (%d): уже в OSM %d, добавлено %d\n",
		len(toplist.All), existed, added)
	fmt.Printf("Файл: %s\n", *outPath)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "ошибка:", err)
	os.Exit(1)
}
