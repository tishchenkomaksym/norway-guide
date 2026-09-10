package wiki

import (
	"fmt"
	"net/url"
	"strings"
)

// Entity — то, что нам нужно от Wikidata: на каких языках есть статьи
// и как они называются.
//
// Названия статей по языкам критичны: норвежская статья про Bryggen
// называется «Bryggen i Bergen», немецкая — «Bryggen», и угадать это
// без Wikidata нельзя. Именно поэтому Wikidata стоит в пайплайне
// раньше Wikipedia, хотя текстов сама не даёт.
type Entity struct {
	ID string
	// lang → название статьи в Wikipedia на этом языке
	WikipediaTitles map[string]string
	// lang → название статьи в Wikivoyage
	WikivoyageTitles map[string]string
	Labels           map[string]string
}

type wbResponse struct {
	Entities map[string]struct {
		Sitelinks map[string]struct {
			Site  string `json:"site"`
			Title string `json:"title"`
		} `json:"sitelinks"`
		Labels map[string]struct {
			Language string `json:"language"`
			Value    string `json:"value"`
		} `json:"labels"`
	} `json:"entities"`
	Error *struct {
		Info string `json:"info"`
	} `json:"error,omitempty"`
}

// FetchEntities забирает сведения о сущностях батчами.
//
// API принимает до 50 идентификаторов за раз — на 15 000 объектов это
// 300 запросов вместо 15 000. Разница между часом и суткам работы.
func (c *Client) FetchEntities(ids []string, langs []string) (map[string]*Entity, error) {
	out := make(map[string]*Entity, len(ids))

	const batchSize = 50
	for start := 0; start < len(ids); start += batchSize {
		end := start + batchSize
		if end > len(ids) {
			end = len(ids)
		}
		batch := ids[start:end]

		u := fmt.Sprintf(
			"https://www.wikidata.org/w/api.php?action=wbgetentities"+
				"&ids=%s&props=sitelinks|labels&format=json",
			url.QueryEscape(strings.Join(batch, "|")),
		)

		var resp wbResponse
		if err := c.GetJSON(u, &resp); err != nil {
			return out, fmt.Errorf("wikidata батч %d..%d: %w", start, end, err)
		}
		if resp.Error != nil {
			return out, fmt.Errorf("wikidata: %s", resp.Error.Info)
		}

		for id, ent := range resp.Entities {
			e := &Entity{
				ID:               id,
				WikipediaTitles:  map[string]string{},
				WikivoyageTitles: map[string]string{},
				Labels:           map[string]string{},
			}
			for _, link := range ent.Sitelinks {
				lang, project, ok := parseSite(link.Site)
				if !ok || !contains(langs, lang) {
					continue
				}
				switch project {
				case "wiki":
					e.WikipediaTitles[lang] = link.Title
				case "wikivoyage":
					e.WikivoyageTitles[lang] = link.Title
				}
			}
			for _, l := range ent.Labels {
				if contains(langs, l.Language) {
					e.Labels[l.Language] = l.Value
				}
			}
			out[id] = e
		}
	}

	return out, nil
}

// parseSite разбирает код проекта: "nowiki" → no + wiki,
// "dewikivoyage" → de + wikivoyage.
//
// Отдельная тонкость: норвежский букмол в Wikidata обозначается как "nb"
// в языках, но сайт называется "nowiki". Приводим к нашему `no`.
func parseSite(site string) (lang, project string, ok bool) {
	switch {
	case strings.HasSuffix(site, "wikivoyage"):
		lang = strings.TrimSuffix(site, "wikivoyage")
		project = "wikivoyage"
	case strings.HasSuffix(site, "wiki"):
		lang = strings.TrimSuffix(site, "wiki")
		project = "wiki"
	default:
		return "", "", false
	}

	if lang == "" {
		return "", "", false
	}
	if lang == "nb" || lang == "nn" {
		lang = "no"
	}
	return lang, project, true
}

func contains(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}
