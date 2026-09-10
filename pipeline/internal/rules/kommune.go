package rules

import (
	"fmt"
	"net/url"
	"strings"

	"github.com/grigorianez/nordguide/pipeline/internal/wiki"
)

// Kommune — норвежская коммуна с контактами.
//
// Именно коммуна отвечает на вопрос «где узнать правила»: она либо сама
// издаёт местные постановления, либо знает, кто владеет водой и угодьями.
// Телефон здесь важнее сайта: сайты меняют структуру, номер живёт годами.
type Kommune struct {
	Number    string `json:"number"`
	Name      string `json:"name"`
	County    string `json:"county"`
	Phone     string `json:"phone,omitempty"`
	Website   string `json:"website,omitempty"`
	CheckedAt string `json:"checked_at"`
}

type pointResponse struct {
	KommuneNavn   string `json:"kommunenavn"`
	KommuneNummer string `json:"kommunenummer"`
	FylkesNavn    string `json:"fylkesnavn"`
}

// SvalbardMinLat — южная граница зоны, которую сервис коммун не покрывает.
//
// Шпицберген и Ян-Майен не поделены на коммуны: там сидит губернатор
// (Sysselmesteren), и правила охоты и рыбалки совсем другие — большая часть
// архипелага заповедна, охота лицензируется отдельно. Отправлять человека
// звонить в несуществующую коммуну нельзя.
const SvalbardMinLat = 74.0

// LookupPoint определяет коммуну по координатам через сервис Kartverket.
//
// Возвращает пустой результат без ошибки, если точка вне зоны действия
// сервиса: посреди моря или на Шпицбергене. Это штатный исход, а не сбой.
func LookupPoint(c *wiki.Client, lat, lon float64) (*Kommune, error) {
	if lat >= SvalbardMinLat {
		// Сервис ответит 404, и это не ошибка сети: коммун там нет.
		return nil, nil
	}

	u := fmt.Sprintf(
		"https://ws.geonorge.no/kommuneinfo/v1/punkt?nord=%.6f&ost=%.6f&koordsys=4258",
		lat, lon,
	)

	var resp pointResponse
	if err := c.GetJSON(u, &resp); err != nil {
		return nil, fmt.Errorf("kartverket %.4f,%.4f: %w", lat, lon, err)
	}
	if resp.KommuneNummer == "" {
		return nil, nil
	}

	return &Kommune{
		Number: resp.KommuneNummer,
		Name:   resp.KommuneNavn,
		County: resp.FylkesNavn,
	}, nil
}

type brregResponse struct {
	Embedded struct {
		Enheter []struct {
			Navn                string `json:"navn"`
			Organisasjonsnummer string `json:"organisasjonsnummer"`
			Hjemmeside          string `json:"hjemmeside"`
			Telefon             string `json:"telefon"`
			Organisasjonsform   struct {
				Kode string `json:"kode"`
			} `json:"organisasjonsform"`
		} `json:"enheter"`
	} `json:"_embedded"`
}

// FetchContacts достаёт телефон и сайт коммуны из реестра организаций.
//
// В реестре у одной коммуны бывает несколько записей — например, отдельные
// подразделения по НДС. Нужна та, у которой организационная форма KOMM:
// у прочих контакты либо пустые, либо ведут не туда.
func FetchContacts(c *wiki.Client, k *Kommune) error {
	// Ищем по названию: номера организаций коммун нигде не опубликованы
	// единым списком, а название совпадает с точностью до формы
	// («kommune» или «herad» в Вестланде).
	queries := []string{
		k.Name + " kommune",
		k.Name + " herad",
		k.Name,
	}

	for _, q := range queries {
		u := fmt.Sprintf(
			"https://data.brreg.no/enhetsregisteret/api/enheter?navn=%s&size=10",
			url.QueryEscape(q),
		)

		var resp brregResponse
		if err := c.GetJSON(u, &resp); err != nil {
			return fmt.Errorf("brreg %q: %w", q, err)
		}

		for _, e := range resp.Embedded.Enheter {
			if e.Organisasjonsform.Kode != "KOMM" {
				continue
			}
			// Название в реестре в верхнем регистре: сверяем без учёта.
			if !strings.Contains(
				strings.ToLower(e.Navn), strings.ToLower(k.Name)) {
				continue
			}
			k.Phone = normalizePhone(e.Telefon)
			k.Website = normalizeURL(e.Hjemmeside)
			return nil
		}
	}

	// Контактов не нашлось — не ошибка: приложение покажет национальные
	// правила без местного телефона.
	return nil
}

// normalizePhone приводит номер к виду «12 34 56 78».
//
// В реестре номера записаны как придётся: с неразрывными пробелами,
// слитно, с кодом страны. Разнобой заметен в списке, а неразрывный пробел
// вдобавок ломает набор при подстановке в tel:.
//
// Норвежские номера восьмизначные и по традиции разбиваются попарно;
// мобильные (начинаются с 4 или 9) — тройками. Всё, что не восемь цифр,
// оставляем как есть: это либо номер с кодом страны, либо что-то нетипичное,
// и портить его хуже, чем показать как в источнике.
func normalizePhone(s string) string {
	var digits []rune
	for _, r := range s {
		if r >= '0' && r <= '9' {
			digits = append(digits, r)
		}
	}
	if len(digits) == 10 && string(digits[:2]) == "47" {
		digits = digits[2:] // код страны
	}
	if len(digits) != 8 {
		return strings.Join(strings.Fields(s), " ")
	}

	d := string(digits)
	if d[0] == '4' || d[0] == '9' {
		return fmt.Sprintf("%s %s %s", d[0:3], d[3:5], d[5:8])
	}
	return fmt.Sprintf("%s %s %s %s", d[0:2], d[2:4], d[4:6], d[6:8])
}

func normalizeURL(s string) string {
	s = strings.TrimSpace(s)
	if s == "" {
		return ""
	}
	if !strings.HasPrefix(s, "http://") && !strings.HasPrefix(s, "https://") {
		s = "https://" + s
	}
	return strings.TrimSuffix(s, "/")
}
