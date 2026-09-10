package wiki

import (
	"fmt"
	"net/url"
	"strings"
)

// Article — текст статьи с указанием источника и ревизии.
//
// Ревизия сохраняется не для порядка: тексты Wikipedia и Wikivoyage идут
// под CC BY-SA, и атрибуция должна указывать на конкретную версию статьи
// (§7 спецификации).
type Article struct {
	Lang     string
	Title    string
	Source   string // "wikipedia" | "wikivoyage"
	Summary  string
	Text     string
	RevID    int64
	PageURL  string
	NotFound bool
}

type extractResponse struct {
	Query struct {
		Pages map[string]struct {
			PageID   int64  `json:"pageid"`
			Title    string `json:"title"`
			Extract  string `json:"extract"`
			Missing  any    `json:"missing"`
			Revision []struct {
				RevID int64 `json:"revid"`
			} `json:"revisions"`
		} `json:"pages"`
	} `json:"query"`
}

// FetchArticle забирает текст статьи.
//
// Норвежского раздела Wikivoyage не существует — `no.wikivoyage.org`
// отдаёт HTML вместо JSON. Проверяем заранее, чтобы не засорять лог
// ошибками разбора.
func (c *Client) FetchArticle(source, lang, title string) (*Article, error) {
	if source == "wikivoyage" && lang == "no" {
		return &Article{Lang: lang, Title: title, Source: source, NotFound: true}, nil
	}

	host := lang + ".wikipedia.org"
	if source == "wikivoyage" {
		host = lang + ".wikivoyage.org"
	}

	u := fmt.Sprintf(
		"https://%s/w/api.php?action=query&prop=extracts|revisions"+
			"&explaintext=1&redirects=1&rvprop=ids&format=json&titles=%s",
		host, url.QueryEscape(title),
	)

	var resp extractResponse
	if err := c.GetJSON(u, &resp); err != nil {
		return nil, fmt.Errorf("%s %s %q: %w", source, lang, title, err)
	}

	for _, p := range resp.Query.Pages {
		if p.Missing != nil {
			return &Article{Lang: lang, Title: title, Source: source, NotFound: true}, nil
		}

		text := CleanText(p.Extract)
		art := &Article{
			Lang:    lang,
			Title:   p.Title,
			Source:  source,
			Text:    text,
			Summary: Summarize(text),
			PageURL: fmt.Sprintf("https://%s/wiki/%s", host,
				url.PathEscape(strings.ReplaceAll(p.Title, " ", "_"))),
		}
		if len(p.Revision) > 0 {
			art.RevID = p.Revision[0].RevID
		}
		return art, nil
	}

	return &Article{Lang: lang, Title: title, Source: source, NotFound: true}, nil
}
