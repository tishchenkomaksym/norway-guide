// Команда appart готовит оформление приложения из исходных картинок.
//
// Делает две вещи, обе разовые, но повторяемые: обрезает заставку главного
// экрана и собирает иконки запуска для Android из эмблемы.
//
// Почему это код, а не ручная правка в редакторе. Исходники приходят
// разными: другой размер, другая пропорция, запечённая «прозрачность».
// Скрипт фиксирует, что именно с ними делается, и следующая замена
// картинки не превращается в археологию.
//
// Запуск:
//
//	go run ./cmd/appart splash <вход.jpg> <выход.jpg> <срезать сверху, доля>
//	go run ./cmd/appart icons <вход.jpg> <каталог res> [доля ширины] [сдвиг вверх]
//	go run ./cmd/appart ios-icons <вход.jpg> <AppIcon.appiconset> [доля] [сдвиг]
package main

import (
	"fmt"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"image/png"
	"os"
	"path/filepath"
	"strconv"

	xdraw "golang.org/x/image/draw"
)

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintln(os.Stderr, "нужно: appart splash|icons <вход> <выход> [доля]")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "splash":
		frac := 0.28
		if len(os.Args) > 4 {
			if v, err := strconv.ParseFloat(os.Args[4], 64); err == nil {
				frac = v
			}
		}
		if err := splash(os.Args[2], os.Args[3], frac); err != nil {
			fatal(err)
		}
	case "ios-icons":
		frac, shift := 0.56, 0.125
		if len(os.Args) > 4 {
			if v, err := strconv.ParseFloat(os.Args[4], 64); err == nil {
				frac = v
			}
		}
		if len(os.Args) > 5 {
			if v, err := strconv.ParseFloat(os.Args[5], 64); err == nil {
				shift = v
			}
		}
		if err := iosIcons(os.Args[2], os.Args[3], frac, shift); err != nil {
			fatal(err)
		}
	case "icons":
		// Доля ширины и сдвиг центра по вертикали: у разных эмблем круг
		// занимает разную часть кадра, и подбирать это приходится глазами.
		frac, shift := 0.62, 0.055
		if len(os.Args) > 4 {
			if v, err := strconv.ParseFloat(os.Args[4], 64); err == nil {
				frac = v
			}
		}
		if len(os.Args) > 5 {
			if v, err := strconv.ParseFloat(os.Args[5], 64); err == nil {
				shift = v
			}
		}
		if err := icons(os.Args[2], os.Args[3], frac, shift); err != nil {
			fatal(err)
		}
	default:
		fatal(fmt.Errorf("неизвестная команда %q", os.Args[1]))
	}
}

// splash срезает верхнюю часть картинки.
//
// На исходной заставке вверху нарисованы логотип и надпись «Norway Explore».
// Оставить их нельзя: заголовок рисует само приложение и берёт его из
// локализации — иначе на русском и китайском экране висел бы английский
// текст, а на экране оказалось бы два заголовка сразу.
func splash(src, dst string, topFraction float64) error {
	img, err := load(src)
	if err != nil {
		return err
	}
	b := img.Bounds()
	cut := int(float64(b.Dy()) * topFraction)
	rect := image.Rect(b.Min.X, b.Min.Y+cut, b.Max.X, b.Max.Y)

	out := image.NewRGBA(image.Rect(0, 0, rect.Dx(), rect.Dy()))
	draw.Draw(out, out.Bounds(), img, rect.Min, draw.Src)

	f, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer f.Close()
	if err := jpeg.Encode(f, out, &jpeg.Options{Quality: 88}); err != nil {
		return err
	}
	fmt.Printf("заставка: %dx%d -> %dx%d (срезано сверху %d px)\n",
		b.Dx(), b.Dy(), rect.Dx(), rect.Dy(), cut)
	return nil
}

// Размеры иконок запуска Android по плотностям экрана.
var densities = map[string]int{
	"mipmap-mdpi":    48,
	"mipmap-hdpi":    72,
	"mipmap-xhdpi":   96,
	"mipmap-xxhdpi":  144,
	"mipmap-xxxhdpi": 192,
}

// icons собирает иконки запуска из эмблемы.
//
// Исходник — овальная эмблема на «прозрачном» фоне, который на деле
// запечён в JPEG шахматной клеткой. Клетку надо убрать, иначе она станет
// видимым узором по углам иконки.
//
// Эмблема вписывается в квадрат по своей короткой стороне и обрезается
// сверху и снизу: подпись под эмблемой в размере 48 пикселей всё равно
// нечитаема, а место занимает.
func icons(src, resDir string, sideFraction, yShift float64) error {
	img, err := load(src)
	if err != nil {
		return err
	}
	b := img.Bounds()

	// Берём сцену ВНУТРИ эмблемы, а не эмблему целиком.
	//
	// Первая попытка вписывала весь овал в квадрат, и получилось плохо:
	// по углам вылезала шахматка (в JPEG «прозрачность» запечена
	// пикселями и никакой заливкой не убирается), а снизу торчал
	// обрезанный кусок подписи. В иконке 48×48 подпись всё равно
	// нечитаема, а шахматка бросается в глаза.
	//
	// Поэтому вырезаем квадрат, который целиком помещается внутри овала:
	// домик, горы и сияние — то, что различимо в мелком размере.
	side := int(float64(b.Dx()) * sideFraction)
	cx := (b.Min.X + b.Max.X) / 2
	cy := (b.Min.Y+b.Max.Y)/2 - int(float64(b.Dy())*yShift)
	crop := image.Rect(cx-side/2, cy-side/2, cx+side/2, cy+side/2).Intersect(b)

	square := image.NewRGBA(image.Rect(0, 0, crop.Dx(), crop.Dy()))
	dark := color.RGBA{0x0E, 0x1F, 0x3A, 0xFF}
	draw.Draw(square, square.Bounds(), &image.Uniform{dark}, image.Point{}, draw.Src)
	draw.Draw(square, square.Bounds(), img, crop.Min, draw.Over)

	// Скругление углов заливкой: даже если квадрат где-то заденет край
	// овала, углы иконки останутся чистыми. Android всё равно обрезает
	// иконку по маске устройства — круглой или со скруглением.
	r := float64(crop.Dx()) / 2
	for y := 0; y < crop.Dy(); y++ {
		for x := 0; x < crop.Dx(); x++ {
			dx, dy := float64(x)-r, float64(y)-r
			if dx*dx+dy*dy > r*r*1.02 {
				square.Set(x, y, dark)
			}
		}
	}

	for dir, size := range densities {
		out := image.NewRGBA(image.Rect(0, 0, size, size))
		xdraw.CatmullRom.Scale(out, out.Bounds(), square, square.Bounds(), draw.Over, nil)

		dir := filepath.Join(resDir, dir)
		if err := os.MkdirAll(dir, 0o755); err != nil {
			return err
		}
		path := filepath.Join(dir, "ic_launcher.png")
		f, err := os.Create(path)
		if err != nil {
			return err
		}
		if err := png.Encode(f, out); err != nil {
			f.Close()
			return err
		}
		f.Close()
		fmt.Printf("  %-16s %dx%d\n", filepath.Base(dir), size, size)
	}
	return nil
}

// iosIcons собирает иконки для iOS.
//
// Отличие от Android не косметическое: iOS не применяет к иконке маску
// и не терпит прозрачности — Apple отклоняет сборку с альфа-каналом
// в AppIcon. Поэтому здесь квадрат без скругления, залитый фоном,
// а скругляет систему сама при отрисовке.
//
// Набор размеров жёстко задан Apple и лежит в Contents.json; имена
// файлов менять нельзя.
func iosIcons(src, iconsetDir string, sideFraction, yShift float64) error {
	img, err := load(src)
	if err != nil {
		return err
	}
	square := cropSquare(img, sideFraction, yShift)

	// Размер в точках и множитель — как того требует Contents.json.
	type spec struct {
		name string
		px   int
	}
	specs := []spec{
		{"Icon-App-20x20@1x.png", 20}, {"Icon-App-20x20@2x.png", 40},
		{"Icon-App-20x20@3x.png", 60}, {"Icon-App-29x29@1x.png", 29},
		{"Icon-App-29x29@2x.png", 58}, {"Icon-App-29x29@3x.png", 87},
		{"Icon-App-40x40@1x.png", 40}, {"Icon-App-40x40@2x.png", 80},
		{"Icon-App-40x40@3x.png", 120}, {"Icon-App-60x60@2x.png", 120},
		{"Icon-App-60x60@3x.png", 180}, {"Icon-App-76x76@1x.png", 76},
		{"Icon-App-76x76@2x.png", 152}, {"Icon-App-83.5x83.5@2x.png", 167},
		{"Icon-App-1024x1024@1x.png", 1024},
	}

	for _, sp := range specs {
		out := image.NewRGBA(image.Rect(0, 0, sp.px, sp.px))
		xdraw.CatmullRom.Scale(out, out.Bounds(), square, square.Bounds(),
			draw.Over, nil)

		// Убираем альфу: App Store Connect отклоняет иконки с
		// прозрачностью, причём на этапе загрузки, а не сборки.
		opaque := image.NewRGBA(out.Bounds())
		draw.Draw(opaque, opaque.Bounds(),
			&image.Uniform{color.RGBA{0x0E, 0x1F, 0x3A, 0xFF}},
			image.Point{}, draw.Src)
		draw.Draw(opaque, opaque.Bounds(), out, image.Point{}, draw.Over)

		f, err := os.Create(filepath.Join(iconsetDir, sp.name))
		if err != nil {
			return err
		}
		if err := png.Encode(f, opaque); err != nil {
			f.Close()
			return err
		}
		f.Close()
	}
	fmt.Printf("  iOS: %d иконок в %s\n", len(specs), iconsetDir)
	return nil
}

// cropSquare вырезает из эмблемы квадрат со сценой внутри круга.
func cropSquare(img image.Image, sideFraction, yShift float64) image.Image {
	b := img.Bounds()
	side := int(float64(b.Dx()) * sideFraction)
	cx := (b.Min.X + b.Max.X) / 2
	cy := (b.Min.Y+b.Max.Y)/2 - int(float64(b.Dy())*yShift)
	crop := image.Rect(cx-side/2, cy-side/2, cx+side/2, cy+side/2).Intersect(b)

	square := image.NewRGBA(image.Rect(0, 0, crop.Dx(), crop.Dy()))
	dark := color.RGBA{0x0E, 0x1F, 0x3A, 0xFF}
	draw.Draw(square, square.Bounds(), &image.Uniform{dark}, image.Point{}, draw.Src)
	draw.Draw(square, square.Bounds(), img, crop.Min, draw.Over)

	// Углы закрашиваем фоном, а не делаем прозрачными.
	//
	// Квадрат вписан в круглую эмблему и краями задевает то, что лежит
	// за ней, — в исходном JPEG там запечённая шахматка «прозрачности».
	// На Android углы можно было просто вырезать: система накладывает
	// свою маску. На iOS прозрачности в иконке быть не должно вовсе —
	// App Store Connect отклоняет такую сборку при загрузке, — поэтому
	// углы заливаются тем же тёмно-синим, что и фон эмблемы, а скругляет
	// их система при отрисовке.
	r := float64(crop.Dx()) / 2
	for y := 0; y < crop.Dy(); y++ {
		for x := 0; x < crop.Dx(); x++ {
			dx, dy := float64(x)-r, float64(y)-r
			if dx*dx+dy*dy > r*r*1.02 {
				square.Set(x, y, dark)
			}
		}
	}
	return square
}

func load(path string) (image.Image, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	img, _, err := image.Decode(f)
	return img, err
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "ошибка:", err)
	os.Exit(1)
}
