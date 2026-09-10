package rules

import "testing"

func TestNormalizePhone(t *testing.T) {
	cases := map[string]string{
		// Неразрывные пробелы из реестра: они ломают набор через tel:.
		"70 26 80 00":     "70 26 80 00",
		"74052500":        "74 05 25 00",
		"+47 74 05 25 00": "74 05 25 00",
		"4740123456":      "401 23 456", // мобильный, тройками
		"":                "",
	}

	for in, want := range cases {
		if got := normalizePhone(in); got != want {
			t.Errorf("normalizePhone(%q) = %q, ожидалось %q", in, got, want)
		}
	}
}

func TestNormalizePhoneНеПортитНетипичные(t *testing.T) {
	// Короткие служебные номера и всё, что не восемь цифр, оставляем
	// как в источнике: испортить хуже, чем показать непривычно.
	if got := normalizePhone("116 117"); got != "116 117" {
		t.Errorf("получено %q", got)
	}
}

func TestNormalizeURL(t *testing.T) {
	cases := map[string]string{
		"www.voss.kommune.no/":       "https://www.voss.kommune.no",
		"https://stranda.kommune.no": "https://stranda.kommune.no",
		"  aurland.kommune.no  ":     "https://aurland.kommune.no",
		"":                           "",
	}
	for in, want := range cases {
		if got := normalizeURL(in); got != want {
			t.Errorf("normalizeURL(%q) = %q, ожидалось %q", in, got, want)
		}
	}
}

func TestНациональныеПравилаИмеютИсточник(t *testing.T) {
	// Правило без ссылки бесполезно: человек не сможет его перепроверить,
	// а мы не сможем доказать, откуда взяли формулировку.
	if len(NationalRules) == 0 {
		t.Fatal("список национальных правил пуст")
	}
	for _, r := range NationalRules {
		if r.SourceURL == "" {
			t.Errorf("нет источника: %s", r.Title)
		}
		if r.Authority == "" {
			t.Errorf("не указано, кто отвечает: %s", r.Title)
		}
		if r.Body == "" {
			t.Errorf("пустой текст: %s", r.Title)
		}
	}
}

func TestЕстьПравилаДляОбоихВидов(t *testing.T) {
	if len(RulesFor(Fishing)) == 0 {
		t.Error("нет правил рыбалки")
	}
	if len(RulesFor(Hunting)) == 0 {
		t.Error("нет правил охоты")
	}
}
