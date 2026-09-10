// Команда rules — собирает сведения о том, ГДЕ ПРОВЕРИТЬ правила рыбалки
// и охоты для мест из каталога.
//
// Чего эта команда принципиально не делает: она не решает, можно ли ловить
// или охотиться в конкретной точке. В Норвегии это зависит от коммуны,
// владельца воды, сезона и вида; данные разнесены по сотням сайтов и живут
// в основном в PDF. Приложение, которое скажет «здесь можно», а человек
// получит штраф, хуже отсутствия функции.
//
// Что команда делает вместо этого: для каждого места находит коммуну через
// сервис Kartverket, берёт её телефон и сайт из реестра организаций и
// проставляет дату проверки. Дальше приложение показывает: «правила
// уточняйте в коммуне такой-то, телефон такой-то, проверено такого числа».
//
// Запуск:
//
//	go run ./cmd/rules --places data/places-norway.jsonl --out data/rules.jsonl
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sort"
	"time"

	ngrules "github.com/grigorianez/nordguide/pipeline/internal/rules"
	"github.com/grigorianez/nordguide/pipeline/internal/wiki"
)

type place struct {
	ID         string   `json:"id"`
	Category   string   `json:"category"`
	NameNo     string   `json:"name_no"`
	Lat        float64  `json:"lat"`
	Lon        float64  `json:"lon"`
	Importance int      `json:"importance"`
	Tags       []string `json:"tags"`
}

// placeRule — строка результата: место, его коммуна и куда обращаться.
type placeRule struct {
	PlaceID    string   `json:"place_id"`
	Activities []string `json:"activities"`

	KommuneNumber  string `json:"kommune_number"`
	KommuneName    string `json:"kommune_name"`
	CountyName     string `json:"county_name"`
	KommunePhone   string `json:"kommune_phone,omitempty"`
	KommuneWebsite string `json:"kommune_website,omitempty"`

	// Дата, когда контакты были получены из реестра. Показывается
	// пользователю: сведения устаревают, и он должен видеть, насколько
	// они свежие.
	CheckedAt string `json:"checked_at"`
}

// relevant решает, нужны ли месту правила рыбалки или охоты.
//
// Категории водоёмов дают рыбалку по существу: ловят в озере или реке,
// а не «во фьорде вообще». Явные теги из OSM учитываем сверх этого.
func relevant(p place) []string {
	set := map[string]bool{}

	switch p.Category {
	case "lake", "river", "beach", "fjord":
		set["fishing"] = true
	}
	for _, t := range p.Tags {
		if t == "fishing" {
			set["fishing"] = true
		}
		if t == "hunting" {
			set["hunting"] = true
		}
	}

	out := make([]string, 0, len(set))
	for k := range set {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func main() {
	var (
		placesPath = flag.String("places", "data/places-norway.jsonl", "места от extract")
		outPath    = flag.String("out", "data/rules.jsonl", "куда писать результат")
		rulesPath  = flag.String("national", "data/national-rules.jsonl", "национальные правила")
		cacheDir   = flag.String("cache", "data/cache", "дисковый кэш запросов")
		minImp     = flag.Int("min-importance", 40, "минимальная значимость места")
		limit      = flag.Int("limit", 400, "сколько мест обработать")
	)
	flag.Parse()

	start := time.Now()

	places, err := readJSONL[place](*placesPath)
	if err != nil {
		fatal(err)
	}

	// Отбираем места, где рыбалка или охота вообще осмысленны.
	var targets []place
	for _, p := range places {
		if p.Importance < *minImp {
			continue
		}
		if len(relevant(p)) == 0 {
			continue
		}
		targets = append(targets, p)
	}
	sort.Slice(targets, func(i, j int) bool {
		return targets[i].Importance > targets[j].Importance
	})
	if *limit > 0 && len(targets) > *limit {
		targets = targets[:*limit]
	}

	fmt.Fprintf(os.Stderr, "Мест с рыбалкой или охотой: %d\n", len(targets))
	if len(targets) == 0 {
		fmt.Fprintln(os.Stderr, "нечего обрабатывать")
		return
	}

	client, err := wiki.NewClient(*cacheDir)
	if err != nil {
		fatal(err)
	}
	// Kartverket и Brreg — государственные сервисы без явных лимитов,
	// но вести себя стоит так же вежливо, как с Wikipedia.
	client.SetRate(300 * time.Millisecond)

	// Коммуны кэшируем в памяти: соседние места почти всегда в одной,
	// и запрашивать контакты по второму разу незачем.
	known := map[string]*ngrules.Kommune{}

	var (
		out        []placeRule
		failures   []string
		outside    int
		withPhone  int
		byActivity = map[string]int{}
	)
	today := time.Now().Format("2006-01-02")

	for i, p := range targets {
		fmt.Fprintf(os.Stderr, "\r  %d/%d  %-36.36s", i+1, len(targets), p.NameNo)

		k, err := ngrules.LookupPoint(client, p.Lat, p.Lon)
		if err != nil {
			failures = append(failures, err.Error())
			continue
		}
		if k == nil {
			// Точка вне суши Норвегии — например, середина фьорда.
			// Правила там определяются берегом, а какой берег «свой»,
			// автоматически не решить.
			outside++
			continue
		}

		if cached, ok := known[k.Number]; ok {
			k = cached
		} else {
			if err := ngrules.FetchContacts(client, k); err != nil {
				failures = append(failures, err.Error())
			}
			k.CheckedAt = today
			known[k.Number] = k
		}

		acts := relevant(p)
		for _, a := range acts {
			byActivity[a]++
		}
		if k.Phone != "" {
			withPhone++
		}

		out = append(out, placeRule{
			PlaceID:        p.ID,
			Activities:     acts,
			KommuneNumber:  k.Number,
			KommuneName:    k.Name,
			CountyName:     k.County,
			KommunePhone:   k.Phone,
			KommuneWebsite: k.Website,
			CheckedAt:      today,
		})
	}
	fmt.Fprintln(os.Stderr)

	if err := writeJSONL(*outPath, out); err != nil {
		fatal(err)
	}
	if err := writeJSONL(*rulesPath, ngrules.NationalRules); err != nil {
		fatal(err)
	}

	report(reportData{
		targets:    len(targets),
		written:    len(out),
		kommuner:   len(known),
		withPhone:  withPhone,
		outside:    outside,
		byActivity: byActivity,
		failures:   failures,
		requests:   client.Requests,
		cacheHits:  client.CacheHits,
		outPath:    *outPath,
		rulesPath:  *rulesPath,
		elapsed:    time.Since(start),
	})
}

type reportData struct {
	targets, written, kommuner, withPhone, outside int
	byActivity                                     map[string]int
	failures                                       []string
	requests, cacheHits                            int
	outPath, rulesPath                             string
	elapsed                                        time.Duration
}

func report(d reportData) {
	fmt.Printf("\n=== rules: результат ===\n\n")
	fmt.Printf("Мест обработано:        %d\n", d.targets)
	fmt.Printf("Записей получено:       %d\n", d.written)
	fmt.Printf("Коммун затронуто:       %d\n", d.kommuner)
	fmt.Printf("Мест с телефоном:       %d (%d%%)\n",
		d.withPhone, percent(d.withPhone, d.written))
	fmt.Printf("Точек вне суши:         %d\n", d.outside)
	fmt.Printf("Запросов: %d, из кэша: %d\n", d.requests, d.cacheHits)
	fmt.Printf("Время: %s\n\n", d.elapsed.Round(time.Second))

	if len(d.byActivity) > 0 {
		fmt.Println("По видам:")
		for _, k := range sortedKeys(d.byActivity) {
			fmt.Printf("  %-10s %d\n", k, d.byActivity[k])
		}
	}

	fmt.Printf("\nФайлы: %s, %s\n", d.outPath, d.rulesPath)

	if len(d.failures) > 0 {
		fmt.Printf("\nОШИБКИ: %d\n", len(d.failures))
		for i, f := range d.failures {
			if i >= 8 {
				fmt.Printf("  ... и ещё %d\n", len(d.failures)-8)
				break
			}
			fmt.Printf("  %s\n", f)
		}
	} else {
		fmt.Println("\nСетевых ошибок нет.")
	}

	fmt.Println("\nЧто в этих данных есть и чего в них нет:")
	fmt.Println("  ЕСТЬ:  коммуна места, её телефон и сайт, дата проверки,")
	fmt.Println("         национальные правила со ссылками на источники.")
	fmt.Println("  НЕТ:   разрешения ловить или охотиться в конкретной точке.")
	fmt.Println("         Это решают коммуна, владелец земли и сезон.")
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

func sortedKeys(m map[string]int) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
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
