// Команда probe — разведка покрытия контента перед началом Этапа 0.
//
// Отвечает на вопрос из §12 спецификации: хватает ли Wikipedia и Wikivoyage
// текстов по норвежским городам и достопримечательностям, чтобы приложение
// имело смысл. Если покрытие низкое, вся продуктовая гипотеза меняется, и
// узнать это надо до того, как написана хоть строчка пайплайна.
//
// Порог годности: не менее 70% городов имеют на en текст в три абзаца и более.
//
// Запуск: go run ./cmd/probe > ../docs/probe-result.md
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strconv"
	"time"
)

const userAgent = "nordguide-probe/0.1 (offline Norway guide; content coverage research)"

// Языки первой очереди по §8.2. Испанский, русский и китайский на этом этапе
// не проверяем: по ним всё равно планируется машинный перевод.
var langs = []string{"en", "no", "de"}

var cities = []string{
	"Oslo", "Bergen", "Trondheim", "Stavanger", "Tromsø", "Ålesund", "Bodø",
	"Kristiansand", "Drammen", "Fredrikstad", "Molde", "Haugesund", "Larvik",
	"Tønsberg", "Lillehammer", "Hamar", "Narvik", "Alta", "Kirkenes", "Harstad",
	"Svolvær", "Flåm", "Geiranger", "Voss", "Odda", "Røros", "Trysil",
	"Longyearbyen", "Åndalsnes", "Kristiansund",
}

var places = []string{
	"Preikestolen", "Trolltunga", "Kjeragbolten", "Geirangerfjord", "Nærøyfjord",
	"Briksdalsbreen", "Vøringsfossen", "Nigardsbreen", "Atlanterhavsveien",
	"Trollstigen", "Nordkapp", "Bryggen", "Nidarosdomen", "Vigelandsanlegget",
	"Holmenkollbakken", "Frammuseet", "Munchmuseet", "Akershus festning",
	"Heddal stavkirke", "Borgund stavkirke", "Urnes stavkirke", "Låtefossen",
	"Jostedalsbreen", "Hardangervidda", "Besseggen", "Galdhøpiggen",
	"Saltstraumen", "Lysefjorden", "Sognefjorden", "Reine",
}

// result — длина текста по каждому источнику и языку для одного объекта.
type result struct {
	Name  string
	Wiki  map[string]int // lang -> длина extract в символах
	Voy   map[string]int
	Fetch error
}

type apiResponse struct {
	Query struct {
		Pages map[string]struct {
			Title   string `json:"title"`
			Extract string `json:"extract"`
			Missing any    `json:"missing"`
		} `json:"pages"`
	} `json:"query"`
}

var client = &http.Client{Timeout: 30 * time.Second}

// fetchExtract возвращает длину полного текста статьи в символах; 0 — статьи нет.
//
// Wikipedia режет частые анонимные запросы через 429. Отличать «статьи нет» от
// «нас притормозили» обязательно: иначе разведка молча покажет нулевое покрытие
// там, где контент на самом деле есть.
func fetchExtract(site, lang, title string) (int, error) {
	u := fmt.Sprintf("https://%s.%s.org/w/api.php"+
		"?action=query&prop=extracts&explaintext=1&redirects=1&format=json&titles=%s",
		lang, site, url.QueryEscape(title))

	const maxAttempts = 4
	backoff := 2 * time.Second

	for attempt := 1; ; attempt++ {
		req, err := http.NewRequest("GET", u, nil)
		if err != nil {
			return 0, err
		}
		req.Header.Set("User-Agent", userAgent)
		req.Header.Set("Accept-Encoding", "gzip")

		resp, err := client.Do(req)
		if err != nil {
			if attempt >= maxAttempts {
				return 0, err
			}
			time.Sleep(backoff)
			backoff *= 2
			continue
		}

		if resp.StatusCode == http.StatusTooManyRequests || resp.StatusCode >= 500 {
			resp.Body.Close()
			if attempt >= maxAttempts {
				return 0, fmt.Errorf("%s.%s %q: HTTP %d после %d попыток",
					lang, site, title, resp.StatusCode, attempt)
			}
			if ra := resp.Header.Get("Retry-After"); ra != "" {
				if secs, e := strconv.Atoi(ra); e == nil {
					time.Sleep(time.Duration(secs) * time.Second)
				} else {
					time.Sleep(backoff)
				}
			} else {
				time.Sleep(backoff)
			}
			backoff *= 2
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			return 0, err
		}
		if resp.StatusCode != http.StatusOK {
			return 0, fmt.Errorf("%s.%s %q: HTTP %d", lang, site, title, resp.StatusCode)
		}

		var ar apiResponse
		if err := json.Unmarshal(body, &ar); err != nil {
			return 0, fmt.Errorf("%s.%s %q: разбор ответа: %w", lang, site, title, err)
		}
		for _, p := range ar.Query.Pages {
			if p.Missing != nil {
				return 0, nil
			}
			return len([]rune(p.Extract)), nil
		}
		return 0, nil
	}
}

// failures копит сетевые ошибки, чтобы они попали в отчёт, а не растворились.
var failures []string

func probe(names []string) []result {
	out := make([]result, 0, len(names))
	for i, name := range names {
		r := result{Name: name, Wiki: map[string]int{}, Voy: map[string]int{}}
		for _, lang := range langs {
			n, err := fetchExtract("wikipedia", lang, name)
			if err != nil {
				r.Fetch = err
				failures = append(failures, err.Error())
			}
			r.Wiki[lang] = n
			time.Sleep(400 * time.Millisecond) // вежливость к API

			n, err = fetchExtract("wikivoyage", lang, name)
			if err != nil {
				r.Fetch = err
				failures = append(failures, err.Error())
			}
			r.Voy[lang] = n
			time.Sleep(400 * time.Millisecond)
		}
		out = append(out, r)
		fmt.Fprintf(os.Stderr, "\r  %d/%d  %-24s", i+1, len(names), name)
	}
	fmt.Fprintln(os.Stderr)
	return out
}

// Примерно три абзаца связного текста.
const goodEnough = 1500

func report(title string, rs []result) {
	fmt.Printf("\n## %s\n\n", title)
	fmt.Println("| Объект | WP en | WP no | WP de | WV en | WV no | WV de |")
	fmt.Println("|---|---:|---:|---:|---:|---:|---:|")

	sort.Slice(rs, func(i, j int) bool { return rs[i].Wiki["en"] > rs[j].Wiki["en"] })
	for _, r := range rs {
		fmt.Printf("| %s | %d | %d | %d | %d | %d | %d |\n", r.Name,
			r.Wiki["en"], r.Wiki["no"], r.Wiki["de"],
			r.Voy["en"], r.Voy["no"], r.Voy["de"])
	}

	fmt.Printf("\n**Итоги по %d объектам:**\n\n", len(rs))
	fmt.Println("| Источник | Есть статья | Из них ≥1500 симв. | Средняя длина |")
	fmt.Println("|---|---:|---:|---:|")

	type src struct {
		name string
		get  func(result) int
	}
	srcs := []src{}
	for _, l := range langs {
		l := l
		srcs = append(srcs, src{"Wikipedia " + l, func(r result) int { return r.Wiki[l] }})
	}
	for _, l := range langs {
		l := l
		srcs = append(srcs, src{"Wikivoyage " + l, func(r result) int { return r.Voy[l] }})
	}

	for _, s := range srcs {
		have, good, total := 0, 0, 0
		for _, r := range rs {
			n := s.get(r)
			if n > 0 {
				have++
				total += n
			}
			if n >= goodEnough {
				good++
			}
		}
		avg := 0
		if have > 0 {
			avg = total / have
		}
		fmt.Printf("| %s | %d/%d (%d%%) | %d (%d%%) | %d |\n", s.name,
			have, len(rs), have*100/len(rs), good, good*100/len(rs), avg)
	}
}

func main() {
	fmt.Fprintln(os.Stderr, "Разведка покрытия: города...")
	cityRes := probe(cities)
	fmt.Fprintln(os.Stderr, "Разведка покрытия: достопримечательности...")
	placeRes := probe(places)

	fmt.Println("# Разведка покрытия контента")
	fmt.Printf("\nДата: %s. Длина текста в символах, 0 — статьи нет.\n", time.Now().Format("2006-01-02"))
	fmt.Printf("Порог «годен»: %d символов, примерно три абзаца.\n", goodEnough)
	fmt.Println("\nWP — Wikipedia, WV — Wikivoyage.")

	report("Города", cityRes)
	report("Достопримечательности", placeRes)

	if len(failures) > 0 {
		fmt.Printf("\n## ВНИМАНИЕ: %d сетевых ошибок\n\n", len(failures))
		fmt.Println("Нули в таблицах выше могут означать не отсутствие статьи, а сбой запроса.")
		fmt.Print("Результат в этом случае недостоверен, прогон надо повторить.\n\n")
		fmt.Println("```")
		for i, f := range failures {
			if i >= 20 {
				fmt.Printf("... и ещё %d\n", len(failures)-20)
				break
			}
			fmt.Println(f)
		}
		fmt.Println("```")
	} else {
		fmt.Println("\nСетевых ошибок нет — нули означают действительное отсутствие статьи.")
	}

	fmt.Println("\n## Как читать результат")
	fmt.Println("\nКритерий продолжения (риск 1): не менее 70% городов имеют на Wikipedia en")
	fmt.Println("текст в 1500+ символов. Если ниже — описания придётся писать вручную,")
	fmt.Println("и продуктовую гипотезу надо пересматривать до начала разработки.")
}
