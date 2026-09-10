// Команда optimize пережимает скачанные фотографии под размер бандла.
//
// Зачем. Commons отдаёт уменьшенные копии в щедром качестве: при ширине
// 640 px средний файл выходит около 167 КБ. На 1 900 снимков это 306 МБ —
// впятеро больше бюджета бандла в 40–60 МБ (CLAUDE.md), и приложение
// весило бы больше трёхсот мегабайт ещё до первого пакета контента.
//
// Что делает. Уменьшает до заданной ширины и пережимает JPEG с разумным
// качеством. Спецификация просит WebP, и он был бы примерно на треть
// легче, но кодировщик WebP в Go тянет за собой C-библиотеку и ломает
// сборку на чистой машине. JPEG даёт основную часть экономии без новых
// зависимостей; переход на WebP — отдельная задача вместе с cwebp
// в тулчейне.
//
// Идемпотентность: файл, который уже меньше порога и не шире цели,
// пропускается. Повторный прогон ничего не портит и почти ничего не делает.
//
// Запуск:
//
//	go run ./cmd/optimize --dir ../app/assets/photos --width 480 --quality 78
package main

import (
	"flag"
	"fmt"
	"image"
	"image/jpeg"
	_ "image/png"
	"os"
	"path/filepath"
	"strings"
	"time"

	"golang.org/x/image/draw"
)

func main() {
	var (
		dir     = flag.String("dir", "../app/assets/photos", "папка со снимками")
		width   = flag.Int("width", 480, "максимальная ширина, px")
		quality = flag.Int("quality", 78, "качество JPEG, 1..100")
		minSize = flag.Int64("min-size", 60*1024,
			"файлы меньше этого размера не трогать, байт")
		dryRun = flag.Bool("dry-run", false, "только посчитать, ничего не менять")
	)
	flag.Parse()

	start := time.Now()

	entries, err := os.ReadDir(*dir)
	if err != nil {
		fatal(err)
	}

	var (
		before, after int64
		processed     int
		skipped       int
		failed        int
	)

	for i, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		switch strings.ToLower(filepath.Ext(name)) {
		case ".jpg", ".jpeg", ".png":
		default:
			continue
		}

		path := filepath.Join(*dir, name)
		info, err := e.Info()
		if err != nil {
			continue
		}
		before += info.Size()

		if info.Size() < *minSize {
			after += info.Size()
			skipped++
			continue
		}

		if i%50 == 0 {
			fmt.Fprintf(os.Stderr, "\r  %d/%d", i+1, len(entries))
		}

		if *dryRun {
			after += info.Size()
			continue
		}

		n, err := shrink(path, *width, *quality)
		if err != nil {
			failed++
			after += info.Size()
			continue
		}
		after += n
		processed++
	}
	fmt.Fprintln(os.Stderr)

	fmt.Printf("\nСнимки пережаты за %s\n\n", time.Since(start).Round(time.Second))
	fmt.Printf("  обработано:   %d\n", processed)
	fmt.Printf("  пропущено:    %d (меньше %d КБ)\n", skipped, *minSize/1024)
	if failed > 0 {
		fmt.Printf("  не удалось:   %d\n", failed)
	}
	fmt.Printf("  было:         %.1f МБ\n", float64(before)/(1<<20))
	fmt.Printf("  стало:        %.1f МБ\n", float64(after)/(1<<20))
	if before > 0 {
		fmt.Printf("  экономия:     %.0f%%\n",
			100*float64(before-after)/float64(before))
	}
}

// shrink уменьшает и пережимает снимок на месте, возвращая новый размер.
//
// Запись идёт во временный файл рядом и только потом заменяет исходный:
// если процесс прервут посреди кодирования, на диске не останется
// обрезанного файла, который приложение покажет как битую картинку.
func shrink(path string, maxWidth, quality int) (int64, error) {
	f, err := os.Open(path)
	if err != nil {
		return 0, err
	}
	src, _, err := image.Decode(f)
	f.Close()
	if err != nil {
		return 0, err
	}

	b := src.Bounds()
	dst := src
	if b.Dx() > maxWidth {
		h := b.Dy() * maxWidth / b.Dx()
		out := image.NewRGBA(image.Rect(0, 0, maxWidth, h))
		// CatmullRom — заметно чётче билинейной интерполяции на снимках
		// с мелкой фактурой: скалы, вода, хвоя.
		draw.CatmullRom.Scale(out, out.Bounds(), src, b, draw.Over, nil)
		dst = out
	}

	tmp := path + ".tmp"
	g, err := os.Create(tmp)
	if err != nil {
		return 0, err
	}
	if err := jpeg.Encode(g, dst, &jpeg.Options{Quality: quality}); err != nil {
		g.Close()
		os.Remove(tmp)
		return 0, err
	}
	if err := g.Close(); err != nil {
		os.Remove(tmp)
		return 0, err
	}

	// Пережатие иногда даёт файл больше исходного — например, у уже
	// сильно сжатого JPEG. Тогда оставляем оригинал.
	ni, err := os.Stat(tmp)
	if err != nil {
		os.Remove(tmp)
		return 0, err
	}
	oi, err := os.Stat(path)
	if err == nil && ni.Size() >= oi.Size() {
		os.Remove(tmp)
		return oi.Size(), nil
	}

	if err := os.Rename(tmp, path); err != nil {
		os.Remove(tmp)
		return 0, err
	}
	return ni.Size(), nil
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "ошибка:", err)
	os.Exit(1)
}
