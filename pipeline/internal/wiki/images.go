package wiki

import (
	"fmt"
	"net/url"
	"path/filepath"
	"strings"
)

// Photo — снимок с Wikimedia Commons вместе с обязательной атрибуцией.
//
// Поля Author, License и SourceURL не опциональны: §7 спецификации требует
// указания автора и лицензии для каждого файла, и снимок без них не имеет
// права попасть в приложение.
type Photo struct {
	EntityID  string `json:"entity_id"`
	FileName  string `json:"file_name"`
	LocalPath string `json:"local_path"`
	Width     int    `json:"width"`
	Height    int    `json:"height"`
	Author    string `json:"author"`
	License   string `json:"license"`
	SourceURL string `json:"source_url"`
}

type claimsResponse struct {
	Entities map[string]struct {
		Claims map[string][]struct {
			Mainsnak struct {
				DataValue struct {
					Value any `json:"value"`
				} `json:"datavalue"`
			} `json:"mainsnak"`
		} `json:"claims"`
	} `json:"entities"`
}

// FetchImageNames возвращает имена файлов Commons для сущностей Wikidata.
//
// Свойство P18 — «изображение». Это выбранный сообществом главный снимок
// объекта, поэтому он почти всегда уместнее случайного файла из категории.
func (c *Client) FetchImageNames(ids []string) (map[string]string, error) {
	out := make(map[string]string, len(ids))

	const batchSize = 50
	for start := 0; start < len(ids); start += batchSize {
		end := start + batchSize
		if end > len(ids) {
			end = len(ids)
		}

		u := fmt.Sprintf(
			"https://www.wikidata.org/w/api.php?action=wbgetentities"+
				"&ids=%s&props=claims&format=json",
			url.QueryEscape(strings.Join(ids[start:end], "|")),
		)

		var resp claimsResponse
		if err := c.GetJSON(u, &resp); err != nil {
			return out, fmt.Errorf("wikidata P18 %d..%d: %w", start, end, err)
		}

		for id, ent := range resp.Entities {
			claims, ok := ent.Claims["P18"]
			if !ok || len(claims) == 0 {
				continue
			}
			if name, ok := claims[0].Mainsnak.DataValue.Value.(string); ok && name != "" {
				out[id] = name
			}
		}
	}

	return out, nil
}

// FetchCommonsCategories возвращает названия категорий Commons (P373).
//
// Нужны для галереи: P18 даёт ровно один снимок, а в карточке места хочется
// показать несколько. Категория Commons — это папка со всеми фотографиями
// объекта, из неё и берутся дополнительные кадры.
func (c *Client) FetchCommonsCategories(ids []string) (map[string]string, error) {
	out := make(map[string]string, len(ids))

	const batchSize = 50
	for start := 0; start < len(ids); start += batchSize {
		end := start + batchSize
		if end > len(ids) {
			end = len(ids)
		}

		u := fmt.Sprintf(
			"https://www.wikidata.org/w/api.php?action=wbgetentities"+
				"&ids=%s&props=claims&format=json",
			url.QueryEscape(strings.Join(ids[start:end], "|")),
		)

		var resp claimsResponse
		if err := c.GetJSON(u, &resp); err != nil {
			return out, fmt.Errorf("wikidata P373 %d..%d: %w", start, end, err)
		}

		for id, ent := range resp.Entities {
			claims, ok := ent.Claims["P373"]
			if !ok || len(claims) == 0 {
				continue
			}
			if name, ok := claims[0].Mainsnak.DataValue.Value.(string); ok && name != "" {
				out[id] = name
			}
		}
	}

	return out, nil
}

type categoryMembersResponse struct {
	Query struct {
		CategoryMembers []struct {
			Title string `json:"title"`
		} `json:"categorymembers"`
	} `json:"query"`
}

// FetchCategoryFiles возвращает имена файлов из категории Commons.
//
// Берём только файлы (cmtype=file) и только растровые расширения: в
// категориях объектов попадаются схемы в SVG, карты и звуковые файлы,
// которым в фотогалерее места делать нечего.
//
// Порядок не сортируем: Commons отдаёт файлы по алфавиту, и это не хуже
// любой доступной нам эвристики качества. Отбор по лицензии всё равно
// произойдёт дальше, при запросе сведений о каждом файле.
func (c *Client) FetchCategoryFiles(category string, limit int) ([]string, error) {
	if limit <= 0 {
		limit = 10
	}
	title := "Category:" + category
	u := fmt.Sprintf(
		"https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers"+
			"&cmtitle=%s&cmtype=file&cmlimit=%d&format=json",
		url.QueryEscape(title), limit,
	)

	var resp categoryMembersResponse
	if err := c.GetJSON(u, &resp); err != nil {
		return nil, fmt.Errorf("категория %s: %w", category, err)
	}

	out := make([]string, 0, len(resp.Query.CategoryMembers))
	for _, m := range resp.Query.CategoryMembers {
		name := strings.TrimPrefix(m.Title, "File:")
		switch strings.ToLower(filepath.Ext(name)) {
		case ".jpg", ".jpeg", ".png", ".webp":
			out = append(out, name)
		}
	}
	return out, nil
}

type imageInfoResponse struct {
	Query struct {
		Pages map[string]struct {
			Title     string `json:"title"`
			ImageInfo []struct {
				ThumbURL       string `json:"thumburl"`
				ThumbWidth     int    `json:"thumbwidth"`
				ThumbHeight    int    `json:"thumbheight"`
				DescriptionURL string `json:"descriptionurl"`
				ExtMetadata    map[string]struct {
					Value any `json:"value"`
				} `json:"extmetadata"`
			} `json:"imageinfo"`
		} `json:"pages"`
	} `json:"query"`
}

// Лицензии, под которыми файл можно использовать, включая коммерчески.
//
// Всё остальное — NonCommercial, NoDerivatives, fair use, «все права
// защищены» — отбрасывается. Это не осторожность, а условие публикации
// в сторах: нарушение блокирует релиз (§7 спецификации).
func licenseAllowed(license string) bool {
	l := strings.ToLower(license)
	switch {
	case strings.Contains(l, "nc") || strings.Contains(l, "noncommercial"):
		return false
	case strings.Contains(l, "nd") && !strings.Contains(l, "no restrictions"):
		return false
	case strings.Contains(l, "fair use"):
		return false
	case strings.HasPrefix(l, "cc0"),
		strings.HasPrefix(l, "cc by"),
		strings.Contains(l, "public domain"),
		strings.Contains(l, "pd-"),
		strings.Contains(l, "no restrictions"):
		return true
	default:
		return false
	}
}

// FetchImageInfo забирает ссылку на уменьшенную копию и данные об авторстве.
//
// Возвращает nil без ошибки, если лицензия не подходит: это штатный исход,
// а не сбой. Отбрасывать такие файлы надо ДО скачивания.
func (c *Client) FetchImageInfo(fileName string, width int) (*Photo, error) {
	title := "File:" + fileName
	u := fmt.Sprintf(
		"https://commons.wikimedia.org/w/api.php?action=query&titles=%s"+
			"&prop=imageinfo&iiprop=url|extmetadata|size&iiurlwidth=%d&format=json",
		url.QueryEscape(title), width,
	)

	var resp imageInfoResponse
	if err := c.GetJSON(u, &resp); err != nil {
		return nil, fmt.Errorf("commons %q: %w", fileName, err)
	}

	for _, page := range resp.Query.Pages {
		if len(page.ImageInfo) == 0 {
			return nil, nil
		}
		ii := page.ImageInfo[0]

		license := metaString(ii.ExtMetadata, "LicenseShortName")
		if !licenseAllowed(license) {
			return nil, nil
		}

		author := stripHTML(metaString(ii.ExtMetadata, "Artist"))
		if author == "" {
			// Без автора файл использовать нельзя даже под CC BY:
			// атрибуция обязательна, а указывать некого.
			return nil, nil
		}

		return &Photo{
			FileName:  fileName,
			Width:     ii.ThumbWidth,
			Height:    ii.ThumbHeight,
			Author:    author,
			License:   license,
			SourceURL: ii.DescriptionURL,
			LocalPath: ii.ThumbURL, // на этом шаге ещё удалённый адрес
		}, nil
	}

	return nil, nil
}

func metaString(m map[string]struct {
	Value any `json:"value"`
}, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.Value.(string); ok {
			return s
		}
	}
	return ""
}

// stripHTML убирает разметку из поля Artist: Commons отдаёт его как HTML
// со ссылками на профиль автора.
func stripHTML(s string) string {
	var b strings.Builder
	depth := 0
	for _, r := range s {
		switch r {
		case '<':
			depth++
		case '>':
			if depth > 0 {
				depth--
			}
		default:
			if depth == 0 {
				b.WriteRune(r)
			}
		}
	}
	return strings.Join(strings.Fields(b.String()), " ")
}
