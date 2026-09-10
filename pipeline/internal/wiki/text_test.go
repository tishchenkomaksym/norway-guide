package wiki

import "strings"

import "testing"

func TestCleanTextУбираетХвост(t *testing.T) {
	raw := strings.Join([]string{
		"Bryggen er en rekke gamle handelshus i Bergen.",
		"",
		"== Historie ==",
		"Bryggen brant flere ganger.",
		"",
		"== Eksterne lenker ==",
		"Offisiell nettside",
		"Bilder på Commons",
	}, "\n")

	got := CleanText(raw)

	if !strings.Contains(got, "Historie") {
		t.Error("содержательный раздел не должен теряться")
	}
	if strings.Contains(got, "Eksterne lenker") ||
		strings.Contains(got, "Offisiell nettside") {
		t.Error("раздел внешних ссылок должен отбрасываться целиком")
	}
}

func TestSummarizeБерётЦелыеПредложения(t *testing.T) {
	text := "Preikestolen er et fjellplatå i Rogaland. " +
		"Platået ligger 604 meter over Lysefjorden. " +
		"Turen tar rundt fire timer. " +
		"Stien starter ved Preikestolen fjellstue."

	got := Summarize(text)

	if got == "" {
		t.Fatal("summary не должен быть пустым")
	}
	if !strings.HasSuffix(got, ".") {
		t.Errorf("summary обрывается не на конце предложения: %q", got)
	}
	if strings.Contains(got, "fjellstue") {
		t.Error("summary не должен вмещать все предложения подряд")
	}
}

func TestSummarizeНеЛомаетсяНаЧислах(t *testing.T) {
	// Точка после числа не заканчивает предложение: за ней нет заглавной.
	text := "Fossen er 182 m. høy og ligger i Eidfjord."
	got := Summarize(text)
	if !strings.Contains(got, "Eidfjord") {
		t.Errorf("предложение обрезано по числу: %q", got)
	}
}

func TestSummarizeДлинноеПредложениеЦеликом(t *testing.T) {
	long := "Dette er en veldig lang setning som fortsetter og fortsetter " +
		"og fortsetter uten noen naturlig pause og går langt forbi grensen " +
		"på tre hundre tegn slik at den ikke passer inn i den vanlige " +
		"grensen for et sammendrag i det hele tatt."

	got := Summarize(long)
	if got != long {
		t.Error("единственное длинное предложение должно отдаваться целиком, а не обрезаться")
	}
}

func TestSummarizeУбираетТранскрипцию(t *testing.T) {
	text := "Bryggen ('the dock'), also known as Tyskebryggen " +
		"(Norwegian: [ˈtʏ̀skə̩brʏɡːn̩], 'the German dock'), is a series of " +
		"Hanseatic buildings in Bergen."

	got := Summarize(text)

	if strings.Contains(got, "ˈtʏ") || strings.Contains(got, "Norwegian:") {
		t.Errorf("фонетическая вставка осталась в summary: %q", got)
	}
	if !strings.Contains(got, "Hanseatic") {
		t.Errorf("содержательная часть потеряна: %q", got)
	}
	if strings.Contains(got, "  ") {
		t.Errorf("двойные пробелы после удаления вставки: %q", got)
	}
}

func TestSummarizeСохраняетОсмысленныеСкобки(t *testing.T) {
	text := "Håkonshallen (bygget mellom 1247 og 1261) er en steinhall i Bergen."
	got := Summarize(text)
	if !strings.Contains(got, "1247") {
		t.Errorf("осмысленная скобка не должна удаляться: %q", got)
	}
}

func TestParseSite(t *testing.T) {
	cases := map[string][2]string{
		"nowiki":       {"no", "wiki"},
		"enwiki":       {"en", "wiki"},
		"dewikivoyage": {"de", "wikivoyage"},
		"nbwiki":       {"no", "wiki"}, // букмол приводим к no
	}

	for site, want := range cases {
		lang, project, ok := parseSite(site)
		if !ok {
			t.Errorf("%s: не разобран", site)
			continue
		}
		if lang != want[0] || project != want[1] {
			t.Errorf("%s: получено %s/%s, ожидалось %s/%s",
				site, lang, project, want[0], want[1])
		}
	}

	if _, _, ok := parseSite("commonswiki_something"); ok {
		t.Error("незнакомый проект не должен разбираться")
	}
}
