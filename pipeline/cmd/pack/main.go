// Команда pack собирает региональные пакеты фотографий.
//
// Что решает. Снимки весят под сотню мегабайт. В бандле приложения им
// не место: человек скачивает из стора сто мегабайт ради поездки по
// одному фьорду, а Google Play вдобавок ограничивает размер. По §5 спеки
// фотогалереи — это уровень 2: качаются по кнопке «скачать перед
// поездкой», регионами.
//
// Что остаётся в бандле. Только то, без чего приложение бесполезно без
// сети: сама база и снимки топ-мест с городами. Их немного, а именно они
// видны на первом экране — обзор страны не должен выглядеть пустым
// у человека, который ничего не скачал.
//
// Что кладётся в пакет. Остальные снимки, разложенные по регионам
// (internal/regions). Каждый пакет — обычный zip плюс строка в манифесте
// с размером и контрольной суммой: без суммы приложение не отличит
// оборвавшуюся закачку от целого файла.
//
// Сжатия внутри zip нет намеренно: JPEG уже сжат, deflate даёт проценты,
// а время распаковки на телефоне тратит заметное.
//
// Запуск:
//
//	go run ./cmd/pack --db data/content.sqlite --photos ../app/assets/photos \
//	                  --out data/packs --prune
package main

import (
	"archive/zip"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"time"

	"github.com/grigorianez/nordguide/pipeline/internal/regions"
	_ "modernc.org/sqlite"
)

// Manifest — то, что приложение скачивает первым и по чему решает,
// что качать дальше.
type Manifest struct {
	// Version манифеста, а не контента: меняется, когда меняется формат.
	Version int `json:"version"`
	// BuiltAt — когда собран. Показывается в экране загрузок: человек
	// должен видеть, насколько свежи данные.
	BuiltAt string     `json:"built_at"`
	Packs   []PackInfo `json:"packs"`
}

// PackInfo — один региональный пакет.
type PackInfo struct {
	RegionID string `json:"region_id"`
	NameNo   string `json:"name_no"`
	NameEn   string `json:"name_en"`
	// PackVersion растёт при пересборке содержимого. Приложение сравнивает
	// его со скачанным и показывает пометку «доступна новая версия» — но
	// само ничего не качает: решение «Карта не обновляется сама».
	PackVersion int    `json:"pack_version"`
	File        string `json:"file"`
	SizeBytes   int64  `json:"size_bytes"`
	SHA256      string `json:"sha256"`
	Photos      int    `json:"photos"`
	Places      int    `json:"places"`
}

// photo — снимок с привязкой к региону.
type photo struct {
	Path     string // путь вида assets/photos/xxx.jpg
	RegionID string
	InBundle bool
	OwnerID  string // место или город, которому принадлежит снимок
}

func main() {
	var (
		dbPath    = flag.String("db", "data/content.sqlite", "контентная база")
		photosDir = flag.String("photos", "../app/assets/photos", "где лежат снимки")
		outDir    = flag.String("out", "data/packs", "куда складывать пакеты")
		version   = flag.Int("pack-version", 1, "версия содержимого пакетов")
		bundleTop = flag.Int("bundle-top", 25, "снимки скольких мест топа оставить в бандле")
		prune     = flag.Bool("prune", false, "убрать из бандла снимки, уехавшие в пакеты")
		dryRun    = flag.Bool("dry-run", false, "только посчитать, ничего не писать")
	)
	flag.Parse()

	start := time.Now()

	photos, err := loadPhotos(*dbPath, *bundleTop)
	if err != nil {
		fatal(err)
	}

	byRegion := map[string][]photo{}
	bundle := 0
	for _, ph := range photos {
		if ph.InBundle {
			bundle++
			continue
		}
		byRegion[ph.RegionID] = append(byRegion[ph.RegionID], ph)
	}

	fmt.Fprintf(os.Stderr, "Снимков всего: %d, в бандле останется: %d\n",
		len(photos), bundle)

	ids := make([]string, 0, len(byRegion))
	for id := range byRegion {
		ids = append(ids, id)
	}
	sort.Strings(ids)

	if *dryRun {
		var total int64
		for _, id := range ids {
			size := sizeOf(*photosDir, byRegion[id])
			total += size
			fmt.Printf("  %-12s %4d снимков  %6.1f МБ\n",
				id, len(byRegion[id]), float64(size)/(1<<20))
		}
		fmt.Printf("\nИтого в пакетах: %.1f МБ, в бандле остаётся %d снимков\n",
			float64(total)/(1<<20), bundle)
		return
	}

	if err := os.MkdirAll(*outDir, 0o755); err != nil {
		fatal(err)
	}

	manifest := Manifest{
		Version: 1,
		BuiltAt: time.Now().UTC().Format("2006-01-02"),
	}

	var packedBytes int64
	for _, id := range ids {
		region, err := regions.ByID(id)
		if err != nil {
			fatal(err)
		}
		list := byRegion[id]

		zipPath := filepath.Join(*outDir, id+".zip")
		n, size, err := writeZip(zipPath, *photosDir, list)
		if err != nil {
			fatal(fmt.Errorf("пакет %s: %w", id, err))
		}
		sum, err := fileSHA256(zipPath)
		if err != nil {
			fatal(err)
		}

		owners := map[string]bool{}
		for _, ph := range list {
			owners[ph.OwnerID] = true
		}

		manifest.Packs = append(manifest.Packs, PackInfo{
			RegionID:    id,
			NameNo:      region.NameNo,
			NameEn:      region.NameEn,
			PackVersion: *version,
			File:        id + ".zip",
			SizeBytes:   size,
			SHA256:      sum,
			Photos:      n,
			Places:      len(owners),
		})
		packedBytes += size
		fmt.Fprintf(os.Stderr, "  %-12s %4d снимков  %6.1f МБ\n",
			id, n, float64(size)/(1<<20))
	}

	manifestPath := filepath.Join(*outDir, "manifest.json")
	if err := writeJSON(manifestPath, manifest); err != nil {
		fatal(err)
	}

	// Снимки, уехавшие в пакеты, из бандла убираем — иначе смысл теряется:
	// они останутся в APK и вдобавок скачаются повторно.
	var removed int
	var freed int64
	if *prune {
		for _, id := range ids {
			for _, ph := range byRegion[id] {
				p := filepath.Join(*photosDir, filepath.Base(ph.Path))
				info, err := os.Stat(p)
				if err != nil {
					continue
				}
				if err := os.Remove(p); err == nil {
					removed++
					freed += info.Size()
				}
			}
		}
	}

	fmt.Printf("\nПакеты собраны за %s\n\n", time.Since(start).Round(time.Second))
	fmt.Printf("  регионов:          %d\n", len(manifest.Packs))
	fmt.Printf("  снимков в пакетах: %d\n", len(photos)-bundle)
	fmt.Printf("  объём пакетов:     %.1f МБ\n", float64(packedBytes)/(1<<20))
	fmt.Printf("  осталось в бандле: %d снимков\n", bundle)
	if removed > 0 {
		fmt.Printf("  убрано из бандла:  %d файлов, %.1f МБ\n",
			removed, float64(freed)/(1<<20))
	}
	fmt.Printf("  манифест:          %s\n", manifestPath)
}

// loadPhotos читает снимки вместе с координатами их объектов.
//
// Города идут наравне с местами: их фотографии видны в обзоре страны,
// и они остаются в бандле целиком — их всего около двух сотен.
func loadPhotos(dbPath string, bundleTop int) ([]photo, error) {
	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, err
	}
	defer db.Close()

	rows, err := db.Query(`
	  SELECT ph.path_thumb, p.lat, p.lon, p.top_rank, p.id, 0
	    FROM photos ph JOIN places p ON p.id = ph.place_id
	  UNION ALL
	  SELECT ph.path_thumb, c.lat, c.lon, 0, c.id, 1
	    FROM photos ph JOIN cities c ON c.id = ph.city_id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []photo
	for rows.Next() {
		var path, id string
		var lat, lon float64
		var topRank, isCity int
		if err := rows.Scan(&path, &lat, &lon, &topRank, &id, &isCity); err != nil {
			return nil, err
		}
		out = append(out, photo{
			Path:     path,
			RegionID: regions.For(lat, lon).ID,
			// В бандле остаются города и топ: именно они на первом экране
			// у человека, который ещё ничего не скачал.
			InBundle: isCity == 1 || (topRank > 0 && topRank <= bundleTop),
			OwnerID:  id,
		})
	}
	return out, rows.Err()
}

func writeZip(zipPath, photosDir string, list []photo) (int, int64, error) {
	f, err := os.Create(zipPath)
	if err != nil {
		return 0, 0, err
	}
	defer f.Close()

	w := zip.NewWriter(f)
	var added int
	for _, ph := range list {
		name := filepath.Base(ph.Path)
		src, err := os.Open(filepath.Join(photosDir, name))
		if err != nil {
			// Файла нет — пропускаем молча: снимок мог не скачаться
			// из-за HTTP 429, и это не повод не собрать пакет.
			continue
		}
		// Store, а не Deflate: JPEG уже сжат, а распаковка на телефоне
		// стоит времени.
		hdr := &zip.FileHeader{Name: name, Method: zip.Store}
		dst, err := w.CreateHeader(hdr)
		if err != nil {
			src.Close()
			return added, 0, err
		}
		if _, err := io.Copy(dst, src); err != nil {
			src.Close()
			return added, 0, err
		}
		src.Close()
		added++
	}
	if err := w.Close(); err != nil {
		return added, 0, err
	}

	info, err := f.Stat()
	if err != nil {
		return added, 0, err
	}
	return added, info.Size(), nil
}

func sizeOf(dir string, list []photo) int64 {
	var total int64
	for _, ph := range list {
		if info, err := os.Stat(filepath.Join(dir, filepath.Base(ph.Path))); err == nil {
			total += info.Size()
		}
	}
	return total
}

func writeJSON(path string, v any) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

func fileSHA256(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "ошибка:", err)
	os.Exit(1)
}
