// Команда enrich — второй и третий этапы пайплайна (§3 спецификации).
//
// Берёт JSONL от extract, догружает через Wikidata названия статей на нужных
// языках и вытаскивает тексты из Wikipedia и Wikivoyage.
//
// Обогащаются НЕ все объекты, а топ по значимости. Замер от 2026-09-10
// показал: тег wikidata есть у 9% выборки, но у 100% топ-50 по importance.
// О безымянном заливе статью не пишут, и гнаться за полным покрытием
// бессмысленно (см. docs/decisions.md).
//
// Источники разделены по замеру покрытия (docs/probe-result.md):
// города берём из Wikivoyage, отдельные места — из Wikipedia.
//
// Запуск:
//
//	go run ./cmd/enrich --in data/places-bergen.jsonl --out data/translations.jsonl
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"sort"
	"time"

	"github.com/grigorianez/nordguide/pipeline/internal/wiki"
)

// place — то, что нужно от extract. Полную структуру не тянем: enrich
// не должен зависеть от всех полей, которые может добавить extract.
type place struct {
	ID         string `json:"id"`
	Category   string `json:"category"`
	NameNo     string `json:"name_no"`
	Importance int    `json:"importance"`
	WikidataID string `json:"wikidata_id"`
	Wikipedia  string `json:"wikipedia"`
}

// translation — строка будущей таблицы translations.
type translation struct {
	EntityType  string `json:"entity_type"`
	EntityID    string `json:"entity_id"`
	Lang        string `json:"lang"`
	Name        string `json:"name,omitempty"`
	Summary     string `json:"summary,omitempty"`
	Description string `json:"description,omitempty"`
	Source      string `json:"source"`
	Quality     int    `json:"quality"`
	// Атрибуция по CC BY-SA: без ссылки на конкретную ревизию она неполна.
	SourceURL string `json:"source_url,omitempty"`
	RevID     int64  `json:"rev_id,omitempty"`
}

func main() {
	var (
		inPath    = flag.String("in", "data/places.jsonl", "результат extract")
		outPath   = flag.String("out", "data/translations.jsonl", "куда писать переводы")
		cacheDir  = flag.String("cache", "data/cache", "каталог дискового кэша")
		minImp    = flag.Int("min-importance", 60, "обогащать объекты не ниже этой значимости")
		limit     = flag.Int("limit", 0, "обработать не больше N объектов (0 — все)")
		langsFlag = flag.String("langs", "en,no,de", "языки через запятую")
	)
	flag.Parse()

	langs := splitComma(*langsFlag)
	start := time.Now()

	places, err := readPlaces(*inPath)
	if err != nil {
		fatal(err)
	}
	fmt.Fprintf(os.Stderr, "Прочитано мест: %d\n", len(places))

	// Отбираем кандидатов: значимые и связанные с Wikidata.
	var targets []place
	for _, p := range places {
		if p.Importance < *minImp || p.WikidataID == "" {
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

	fmt.Fprintf(os.Stderr,
		"К обогащению: %d (значимость >= %d, есть wikidata)\n",
		len(targets), *minImp)
	if len(targets) == 0 {
		fmt.Fprintln(os.Stderr, "Нечего обогащать — снизьте --min-importance")
		return
	}

	client, err := wiki.NewClient(*cacheDir)
	if err != nil {
		fatal(err)
	}

	// Шаг 1: Wikidata батчами — узнаём названия статей по языкам.
	ids := make([]string, 0, len(targets))
	for _, p := range targets {
		ids = append(ids, p.WikidataID)
	}
	fmt.Fprintf(os.Stderr, "Wikidata: %d сущностей...\n", len(ids))
	entities, err := client.FetchEntities(ids, langs)
	if err != nil {
		// Частичный результат тоже ценен: продолжаем с тем, что успели.
		fmt.Fprintf(os.Stderr, "предупреждение: %v\n", err)
	}
	fmt.Fprintf(os.Stderr, "  получено: %d\n", len(entities))

	// Шаг 2: тексты статей.
	var (
		out       []translation
		failures  []string
		withText  = map[string]bool{}
		byLang    = map[string]int{}
		bySource  = map[string]int{}
		noArticle int
	)

	for i, p := range targets {
		fmt.Fprintf(os.Stderr, "\r  %d/%d  %-40.40s", i+1, len(targets), p.NameNo)

		ent := entities[p.WikidataID]
		if ent == nil {
			noArticle++
			continue
		}

		for _, lang := range langs {
			// Города берём из Wikivoyage: там формат путеводителя и покрытие
			// 100%. Для отдельных мест Wikivoyage слаб (40%), основной
			// источник — Wikipedia. См. docs/probe-result.md.
			sources := []struct{ name, title string }{
				{"wikipedia", ent.WikipediaTitles[lang]},
				{"wikivoyage", ent.WikivoyageTitles[lang]},
			}

			for _, src := range sources {
				if src.title == "" {
					continue
				}
				art, err := client.FetchArticle(src.name, lang, src.title)
				if err != nil {
					failures = append(failures, err.Error())
					continue
				}
				if art.NotFound || art.Summary == "" {
					continue
				}

				out = append(out, translation{
					EntityType:  "place",
					EntityID:    p.ID,
					Lang:        lang,
					Name:        pick(ent.Labels[lang], art.Title),
					Summary:     art.Summary,
					Description: art.Text,
					Source:      art.Source,
					Quality:     90, // человеческий текст, не машинный перевод
					SourceURL:   art.PageURL,
					RevID:       art.RevID,
				})
				withText[p.ID] = true
				byLang[lang]++
				bySource[art.Source]++
				break // первый удавшийся источник для этого языка
			}
		}
	}
	fmt.Fprintln(os.Stderr)

	if err := writeJSONL(*outPath, out); err != nil {
		fatal(err)
	}

	report(reportData{
		targets:   len(targets),
		texts:     len(out),
		withText:  len(withText),
		noEntity:  noArticle,
		byLang:    byLang,
		bySource:  bySource,
		failures:  failures,
		requests:  client.Requests,
		cacheHits: client.CacheHits,
		retries:   client.Retries,
		outPath:   *outPath,
		elapsed:   time.Since(start),
	})
}

type reportData struct {
	targets, texts, withText, noEntity int
	byLang, bySource                   map[string]int
	failures                           []string
	requests, cacheHits, retries       int
	outPath                            string
	elapsed                            time.Duration
}

func report(d reportData) {
	fmt.Printf("\n=== enrich: результат ===\n\n")
	fmt.Printf("Объектов к обогащению:  %d\n", d.targets)
	fmt.Printf("Получили текст:         %d (%d%%)\n",
		d.withText, percent(d.withText, d.targets))
	fmt.Printf("Всего текстов:          %d\n", d.texts)
	fmt.Printf("Нет сущности Wikidata:  %d\n", d.noEntity)
	fmt.Printf("Файл:                   %s\n", d.outPath)
	fmt.Printf("Запросов: %d, из кэша: %d, повторов: %d\n",
		d.requests, d.cacheHits, d.retries)
	fmt.Printf("Время: %s\n\n", d.elapsed.Round(time.Second))

	if len(d.byLang) > 0 {
		fmt.Println("По языкам:")
		for _, lang := range sortedKeys(d.byLang) {
			fmt.Printf("  %-4s %d\n", lang, d.byLang[lang])
		}
	}
	if len(d.bySource) > 0 {
		fmt.Println("\nПо источникам:")
		for _, s := range sortedKeys(d.bySource) {
			fmt.Printf("  %-12s %d\n", s, d.bySource[s])
		}
	}

	if len(d.failures) > 0 {
		fmt.Printf("\nОШИБКИ ЗАПРОСОВ: %d\n", len(d.failures))
		fmt.Println("Часть текстов могла не загрузиться. Это НЕ то же самое,")
		fmt.Println("что «статьи нет»: прогон стоит повторить.")
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

func readPlaces(path string) ([]place, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	var out []place
	sc := bufio.NewScanner(f)
	sc.Buffer(make([]byte, 0, 64*1024), 8*1024*1024) // теги бывают длинными
	for sc.Scan() {
		line := sc.Bytes()
		if len(line) == 0 {
			continue
		}
		var p place
		if err := json.Unmarshal(line, &p); err != nil {
			return nil, fmt.Errorf("разбор строки: %w", err)
		}
		out = append(out, p)
	}
	return out, sc.Err()
}

func writeJSONL(path string, items []translation) error {
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

func splitComma(s string) []string {
	var out []string
	cur := ""
	for _, ch := range s {
		if ch == ',' {
			if cur != "" {
				out = append(out, cur)
			}
			cur = ""
			continue
		}
		cur += string(ch)
	}
	if cur != "" {
		out = append(out, cur)
	}
	return out
}

func pick(preferred, fallback string) string {
	if preferred != "" {
		return preferred
	}
	return fallback
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
