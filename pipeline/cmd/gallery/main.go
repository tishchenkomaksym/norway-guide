// Команда gallery добирает дополнительные фотографии для карточек мест.
//
// Чем отличается от media. Тот берёт свойство P18 — «изображение» — и
// получает ровно один снимок на объект: выбранный сообществом главный кадр.
// Для списка этого достаточно, но в карточке места одна фотография выглядит
// бедно, особенно у Прекестулена или Гейрангер-фьорда.
//
// Здесь снимки берутся из категории Commons (свойство P373) — это папка со
// всеми фотографиями объекта. Кадры оттуда разного качества, поэтому
// команда применяется не ко всему каталогу, а к тем местам, где галерея
// действительно нужна: топ-20 и объекты с высокой значимостью.
//
// Лицензия проверяется до скачивания, как и в media: NonCommercial,
// NoDerivatives и fair use отбрасываются, у остальных сохраняются автор
// и ссылка (§7 спецификации).
//
// Идемпотентность: уже скачанные файлы не качаются повторно, а прогон
// дописывает в photos.jsonl только новое. Повторный запуск не тратит трафик.
//
// Запуск:
//
//	go run ./cmd/gallery --places data/places-norway.jsonl,data/places-curated.jsonl \
//	                     --photos data/photos.jsonl --per-place 4
package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/grigorianez/nordguide/pipeline/internal/toplist"
	"github.com/grigorianez/nordguide/pipeline/internal/wiki"
)

type entity struct {
	ID         string `json:"id"`
	NameNo     string `json:"name_no"`
	Importance int    `json:"importance"`
	WikidataID string `json:"wikidata_id"`
}

type photoRec struct {
	EntityID  string `json:"entity_id"`
	FileName  string `json:"file_name"`
	LocalPath string `json:"local_path"`
	Width     int    `json:"width"`
	Height    int    `json:"height"`
	Author    string `json:"author"`
	License   string `json:"license"`
	SourceURL string `json:"source_url"`
}

func main() {
	var (
		placesPath = flag.String("places", "data/places-norway.jsonl,data/places-curated.jsonl",
			"места, можно несколько через запятую")
		photosPath = flag.String("photos", "data/photos.jsonl", "файл метаданных, дополняется")
		dir        = flag.String("dir", "../app/assets/photos", "куда класть файлы")
		cacheDir   = flag.String("cache", "data/cache", "дисковый кэш запросов")
		width      = flag.Int("width", 640, "ширина уменьшенной копии, px")
		perPlace   = flag.Int("per-place", 4, "сколько снимков на место, включая уже имеющийся")
		minImp     = flag.Int("min-importance", 0, "брать также места со значимостью не ниже (0 — только топ)")
	)
	flag.Parse()

	start := time.Now()

	var places []entity
	for _, p := range strings.Split(*placesPath, ",") {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		items, err := readJSONL[entity](p)
		if err != nil {
			if os.IsNotExist(err) {
				fmt.Fprintf(os.Stderr, "предупреждение: %s не найден\n", p)
				continue
			}
			fatal(err)
		}
		places = append(places, items...)
	}

	existing, err := readJSONL[photoRec](*photosPath)
	if err != nil && !os.IsNotExist(err) {
		fatal(err)
	}
	// Сколько снимков уже есть у объекта и какие файлы заняты.
	have := map[string]int{}
	haveFile := map[string]bool{}
	for _, p := range existing {
		have[p.EntityID]++
		haveFile[p.FileName] = true
	}

	// Кого обрабатываем: топ-20 всегда, остальные — по порогу значимости.
	var targets []entity
	for _, p := range places {
		if p.WikidataID == "" {
			continue
		}
		_, isTop := toplist.ByQID(p.WikidataID)
		if isTop || (*minImp > 0 && p.Importance >= *minImp) {
			targets = append(targets, p)
		}
	}
	sort.SliceStable(targets, func(i, j int) bool {
		return targets[i].Importance > targets[j].Importance
	})

	fmt.Fprintf(os.Stderr, "К обработке: %d мест, цель %d снимков на место\n",
		len(targets), *perPlace)
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

	fmt.Fprintln(os.Stderr, "Wikidata: ищем категории Commons (P373)...")
	cats, err := client.FetchCommonsCategories(ids)
	if err != nil {
		fmt.Fprintf(os.Stderr, "предупреждение: %v\n", err)
	}
	fmt.Fprintf(os.Stderr, "  с категорией: %d из %d\n", len(cats), len(ids))

	if err := os.MkdirAll(*dir, 0o755); err != nil {
		fatal(err)
	}

	var (
		added        []photoRec
		noCategory   int
		rejectedLic  int
		failures     []string
		catFiles     int
		irrelevant   int
		skippedHave  int
		totalBytes   int64
		licenseCount = map[string]int{}
	)

	for i, t := range targets {
		fmt.Fprintf(os.Stderr, "\r  %d/%d  %-38.38s", i+1, len(targets), t.NameNo)

		need := *perPlace - have[t.ID]
		if need <= 0 {
			skippedHave++
			continue
		}

		cat, ok := cats[t.WikidataID]
		if !ok {
			noCategory++
			continue
		}

		// Запрашиваем с запасом: часть файлов отсеется по лицензии,
		// часть окажется уже скачанной.
		files, err := client.FetchCategoryFiles(cat, need*4)
		if err != nil {
			failures = append(failures, fmt.Sprintf("категория %s: %v", cat, err))
			continue
		}
		catFiles += len(files)

		for _, fileName := range files {
			if need <= 0 {
				break
			}
			if haveFile[fileName] {
				continue
			}
			// Имя файла обязано перекликаться с названием места.
			//
			// Категории Commons отсортированы по алфавиту, файлы с цифр
			// идут первыми, и часть файлов категоризована ошибочно. Первый
			// прогон принёс в галерею парка Вигеланна снимок нацистского
			// партийного съезда и кадр «1292 A2. Oslo» — оба формально
			// лежали в нужной категории.
			//
			// Проверка грубая и отсекает часть хороших снимков (описательные
			// названия вроде «Einer der bekanntesten Fjorde Norwegens»
			// не пройдут). Это правильный размен: короткая галерея — мелкая
			// потеря, чужая фотография в карточке места — грубая ошибка.
			if !relevant(fileName, t.NameNo) {
				irrelevant++
				continue
			}

			info, err := client.FetchImageInfo(fileName, *width)
			if err != nil {
				// Ошибки не глотаем: молчаливый continue уже один раз
				// выдал «0 добавлено» без единой причины в отчёте.
				failures = append(failures, fmt.Sprintf("%s: %v", fileName, err))
				continue
			}
			if info == nil {
				rejectedLic++
				continue
			}

			// Имя файла содержит порядковый номер: у места несколько
			// снимков, и они не должны затирать друг друга.
			local := filepath.Join(*dir,
				fmt.Sprintf("%s_%d%s", safeName(t.ID), have[t.ID]+1, extOf(fileName)))

			// FetchImageInfo кладёт в LocalPath ещё удалённый адрес
			// уменьшенной копии — так же, как это делает media.
			n, err := download(info.SourceURL, local, info.LocalPath)
			if err != nil {
				failures = append(failures, fmt.Sprintf("%s: %v", fileName, err))
				continue
			}

			rel := "assets/photos/" + filepath.Base(local)
			added = append(added, photoRec{
				EntityID:  t.ID,
				FileName:  fileName,
				LocalPath: rel,
				Width:     info.Width,
				Height:    info.Height,
				Author:    info.Author,
				License:   info.License,
				SourceURL: info.SourceURL,
			})
			licenseCount[info.License]++
			totalBytes += n
			haveFile[fileName] = true
			have[t.ID]++
			need--
		}
	}
	fmt.Fprintln(os.Stderr)

	all := append(existing, added...)
	if err := writeJSONL(*photosPath, all); err != nil {
		fatal(err)
	}

	fmt.Printf("\nГалереи собраны за %s\n\n", time.Since(start).Round(time.Second))
	fmt.Printf("  мест обработано:        %d\n", len(targets))
	fmt.Printf("  снимков добавлено:      %d\n", len(added))
	fmt.Printf("  уже хватало:            %d\n", skippedHave)
	fmt.Printf("  без категории Commons:  %d\n", noCategory)
	fmt.Printf("  файлов в категориях:    %d\n", catFiles)
	fmt.Printf("  не по теме:             %d\n", irrelevant)
	fmt.Printf("  отброшено по лицензии:  %d\n", rejectedLic)
	if len(failures) > 0 {
		fmt.Printf("  ошибок:                 %d\n", len(failures))
		for i, f := range failures {
			if i >= 5 {
				break
			}
			fmt.Printf("    %s\n", f)
		}
	}
	fmt.Printf("  скачано:                %.1f МБ\n", float64(totalBytes)/(1<<20))
	fmt.Printf("  всего в %s: %d\n", *photosPath, len(all))

	if len(licenseCount) > 0 {
		fmt.Println("\nЛицензии добавленных:")
		keys := make([]string, 0, len(licenseCount))
		for k := range licenseCount {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			fmt.Printf("  %-28s %d\n", k, licenseCount[k])
		}
	}
}

// relevant проверяет, что снимок относится к месту.
//
// Сравниваем по началу значимых слов названия: «Operahuset» даёт «opera»,
// и файл «Full Opera by night.jpg» проходит, а «8. Parteitag» — нет.
// Сравнение по началу, а не по целому слову, нужно из-за норвежского
// словосложения: одно и то же место называют «Nidarosdomen» и «Nidaros
// Cathedral», «Vigelandsanlegget» и «Vigeland Park».
func relevant(fileName, placeName string) bool {
	file := strings.ToLower(fileName)
	// Название места в OSM бывает списком через точку с запятой:
	// «Fløibanen, nedre stasjon;Fløibanen».
	for _, part := range strings.FieldsFunc(strings.ToLower(placeName),
		func(r rune) bool {
			return r == ' ' || r == ';' || r == ',' || r == '(' || r == ')'
		}) {
		// Короткие слова («i», «og», «Oslo») слишком общие: по «Oslo»
		// в галерею попадёт что угодно, снятое в городе. Порог в пять
		// букв выбран так, чтобы «Oslo» (четыре) не проходило, а «Urnes»
		// проходило — иначе «Stabkirche Urnes» терялось бы.
		r := []rune(part)
		if len(r) < 5 {
			continue
		}
		stem := string(r[:5])
		if strings.Contains(file, stem) {
			return true
		}
	}
	return false
}

var httpClient = &http.Client{Timeout: 90 * time.Second}

// download скачивает снимок.
//
// User-Agent обязателен: без него thumb.wikimedia.org отвечает 403 на
// каждый запрос. Первый прогон этой команды именно так и закончился —
// 246 отказов и ни одной скачанной фотографии.
func download(sourceURL, dest, thumbURL string) (int64, error) {
	if info, err := os.Stat(dest); err == nil {
		// Уже скачано: повторный прогон не тратит трафик заново.
		return info.Size(), nil
	}

	addr := thumbURL
	if addr == "" {
		addr = sourceURL
	}

	req, err := http.NewRequest("GET", addr, nil)
	if err != nil {
		return 0, err
	}
	req.Header.Set("User-Agent", wiki.UserAgent)

	resp, err := httpClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	f, err := os.Create(dest)
	if err != nil {
		return 0, err
	}
	defer f.Close()
	return io.Copy(f, resp.Body)
}

func safeName(id string) string {
	r := strings.NewReplacer(":", "_", "/", "_", " ", "_")
	return r.Replace(id)
}

func extOf(fileName string) string {
	ext := strings.ToLower(filepath.Ext(fileName))
	switch ext {
	case ".jpg", ".jpeg":
		return ".jpg"
	case ".png":
		return ".png"
	case ".webp":
		return ".webp"
	default:
		return ".jpg"
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

	w := bufio.NewWriter(f)
	defer w.Flush()
	enc := json.NewEncoder(w)
	for _, it := range items {
		if err := enc.Encode(it); err != nil {
			return err
		}
	}
	return nil
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "ошибка:", err)
	os.Exit(1)
}
