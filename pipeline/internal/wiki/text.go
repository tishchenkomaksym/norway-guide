package wiki

import (
	"strings"
	"unicode"
)

// Разделы, которые не нужны в карточке места: списки ссылок, примечания,
// навигация. В Wikipedia и Wikivoyage они называются по-разному на каждом
// языке, поэтому список приходится вести явно.
var dropSections = map[string]bool{
	// en
	"see also": true, "references": true, "external links": true,
	"further reading": true, "notes": true, "bibliography": true,
	"gallery": true, "sources": true,
	// no
	"se også": true, "referanser": true, "eksterne lenker": true,
	"litteratur": true, "kilder": true, "noter": true,
	// de
	"siehe auch": true, "weblinks": true, "einzelnachweise": true,
	"literatur": true, "anmerkungen": true, "quellen": true,
	// es
	"véase también": true, "referencias": true, "enlaces externos": true,
	"bibliografía": true, "notas": true,
	// ru
	"см. также": true, "примечания": true, "ссылки": true,
	"литература": true, "источники": true,
}

// CleanText приводит plain-извлечение вики-статьи к виду, пригодному
// для карточки места.
//
// API уже отдаёт текст без разметки, но в нём остаются заголовки разделов
// вида «== Geografi ==», пустые абзацы и хвост из ссылок и примечаний.
// Хвост отсекаем целиком: в офлайн-гиде список внешних ссылок бесполезен,
// а место занимает.
func CleanText(raw string) string {
	if raw == "" {
		return ""
	}

	var out []string
	skipping := false

	for _, line := range strings.Split(raw, "\n") {
		trimmed := strings.TrimSpace(line)
		if trimmed == "" {
			continue
		}

		if title, ok := sectionTitle(trimmed); ok {
			skipping = dropSections[strings.ToLower(title)]
			if skipping {
				continue
			}
			// Заголовки разделов сохраняем как отдельные абзацы —
			// они помогают ориентироваться в длинном тексте.
			out = append(out, title)
			continue
		}

		if skipping {
			continue
		}
		out = append(out, trimmed)
	}

	return strings.Join(out, "\n\n")
}

// sectionTitle распознаёт «== Заголовок ==» любого уровня.
func sectionTitle(line string) (string, bool) {
	if !strings.HasPrefix(line, "=") || !strings.HasSuffix(line, "=") {
		return "", false
	}
	title := strings.Trim(line, "=")
	title = strings.TrimSpace(title)
	if title == "" {
		return "", false
	}
	return title, true
}

// Маркеры вставок, которые в карточке места только мешают: фонетика,
// указания языка оригинала, годы жизни.
var pronunciationMarkers = []string{
	"pronounced", "pronunciation", "Norwegian:", "norsk:", "German:",
	"Deutsch:", "IPA", "uttale", "Aussprache", "listen",
}

// stripParentheticals убирает скобочные вставки с транскрипцией и пометками
// о произношении.
//
// В английской Wikipedia первое предложение часто выглядит так:
//
//	Bryggen ('the dock'), also known as Tyskebryggen (Norwegian: [ˈtʏ̀skə̩brʏɡːn̩]), is…
//
// Читателю гида фонетика не нужна, а место в коротком summary она занимает
// заметное. Скобки с обычным пояснением при этом сохраняем: они часто несут
// смысл («построен в 1702 году»).
func stripParentheticals(s string) string {
	var b strings.Builder
	depth := 0
	start := 0
	runes := []rune(s)

	for i := 0; i < len(runes); i++ {
		switch runes[i] {
		case '(', '[':
			if depth == 0 {
				start = i
			}
			depth++
		case ')', ']':
			if depth == 0 {
				b.WriteRune(runes[i])
				continue
			}
			depth--
			if depth == 0 {
				inner := string(runes[start : i+1])
				if !shouldDrop(inner) {
					b.WriteString(inner)
				}
			}
		default:
			if depth == 0 {
				b.WriteRune(runes[i])
			}
		}
	}

	// Незакрытая скобка — отдаём хвост как есть, чтобы не потерять текст.
	if depth > 0 {
		b.WriteString(string(runes[start:]))
	}

	return tidySpaces(b.String())
}

func shouldDrop(inner string) bool {
	for _, m := range pronunciationMarkers {
		if strings.Contains(inner, m) {
			return true
		}
	}
	// Фонетические символы: расширения МФА и комбинируемые диакритики.
	for _, r := range inner {
		if (r >= 0x0250 && r <= 0x02AF) || (r >= 0x0300 && r <= 0x036F) {
			return true
		}
	}
	return false
}

// tidySpaces убирает следы удалённых вставок: двойные пробелы и пробел
// перед знаком препинания.
func tidySpaces(s string) string {
	var b strings.Builder
	prevSpace := false
	for _, r := range s {
		if unicode.IsSpace(r) {
			prevSpace = true
			continue
		}
		if b.Len() > 0 && prevSpace && r != ',' && r != '.' && r != ';' && r != ':' {
			b.WriteByte(' ')
		}
		prevSpace = false
		b.WriteRune(r)
	}
	return strings.TrimSpace(b.String())
}

// Summarize выделяет короткий самостоятельный текст на 2–3 предложения.
//
// Это НЕ обрезанное начало статьи по количеству символов. Именно summary
// лежит в офлайн-уровне и часто оказывается единственным, что человек
// увидит без сети, — обрыв на середине слова там недопустим.
//
// Берём целые предложения из первого абзаца, пока не наберём около
// 300 символов, но не больше трёх.
func Summarize(text string) string {
	if text == "" {
		return ""
	}

	first := text
	if idx := strings.Index(text, "\n\n"); idx > 0 {
		first = text[:idx]
	}
	first = stripParentheticals(first)

	sentences := splitSentences(first)
	if len(sentences) == 0 {
		return ""
	}

	const target = 300
	var b strings.Builder
	for i, s := range sentences {
		if i >= 3 {
			break
		}
		if b.Len() > 0 && b.Len()+len(s) > target {
			break
		}
		if b.Len() > 0 {
			b.WriteByte(' ')
		}
		b.WriteString(s)
	}

	if b.Len() == 0 {
		// Единственное предложение длиннее лимита — отдаём его целиком.
		// Лучше длинное, чем оборванное.
		return sentences[0]
	}
	return b.String()
}

// splitSentences режет текст на предложения.
//
// Наивное деление по точке ломается на сокращениях и, что важнее для
// Норвегии, на числах вида «182 m.» и датах. Поэтому точка считается
// концом предложения, только если дальше идёт пробел и заглавная буква.
func splitSentences(text string) []string {
	var out []string
	runes := []rune(text)
	start := 0

	for i := 0; i < len(runes); i++ {
		ch := runes[i]
		if ch != '.' && ch != '!' && ch != '?' {
			continue
		}

		// Конец текста.
		if i == len(runes)-1 {
			out = append(out, strings.TrimSpace(string(runes[start:])))
			start = len(runes)
			break
		}

		// Дальше должен идти пробел.
		if !unicode.IsSpace(runes[i+1]) {
			continue
		}

		// А за ним — заглавная буква или цифра.
		j := i + 1
		for j < len(runes) && unicode.IsSpace(runes[j]) {
			j++
		}
		if j >= len(runes) {
			out = append(out, strings.TrimSpace(string(runes[start:])))
			start = len(runes)
			break
		}
		if !unicode.IsUpper(runes[j]) && !unicode.IsDigit(runes[j]) {
			continue
		}

		// Не режем после однобуквенного инициала: «H. Ibsen».
		if i >= 1 && unicode.IsUpper(runes[i-1]) &&
			(i == 1 || unicode.IsSpace(runes[i-2])) {
			continue
		}

		sentence := strings.TrimSpace(string(runes[start : i+1]))
		if sentence != "" {
			out = append(out, sentence)
		}
		start = j
		i = j - 1
	}

	if start < len(runes) {
		rest := strings.TrimSpace(string(runes[start:]))
		if rest != "" {
			out = append(out, rest)
		}
	}
	return out
}
