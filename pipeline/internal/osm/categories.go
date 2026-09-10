// Package osm содержит извлечение и классификацию объектов OpenStreetMap.
package osm

// Категории мест из §4 спецификации. Значения этих констант попадают
// в колонку places.category и в фильтры приложения — менять их нельзя
// без миграции данных.
const (
	CatFjord     = "fjord"
	CatMuseum    = "museum"
	CatWaterfall = "waterfall"
	CatViewpoint = "viewpoint"
	CatChurch    = "church"
	CatHike      = "hike"
	CatBeach     = "beach"
	CatGlacier   = "glacier"

	// Водоёмы нужны для рыбалки: без них профиль «рыбак» не находит ничего,
	// потому что ловят не во фьорде вообще, а в конкретном озере или реке.
	CatLake  = "lake"
	CatRiver = "river"
)

// rule — одно правило классификации: тег со значением даёт категорию.
// Пустое value означает «любое значение этого тега».
type rule struct {
	key      string
	value    string
	category string
	// baseImportance — вклад самого типа объекта в значимость, 0..40.
	// Фьорд по умолчанию интереснее придорожной часовни, и это разумно
	// заложить до того, как подключатся Wikidata и Wikipedia.
	baseImportance int
}

// rules — ЕДИНСТВЕННОЕ место, где теги OSM превращаются в категории.
//
// Порядок важен: первое совпавшее правило выигрывает. Более специфичные
// правила должны идти раньше общих, иначе `tourism=museum` перехватит
// объект, который на самом деле ставкирка.
//
// Держать таблицей, а не разбросанными if: правил будет десятки, и только
// в таком виде их можно просмотреть глазами и обсудить.
var rules = []rule{
	// Природа — то, ради чего в Норвегию едут.
	{"natural", "glacier", CatGlacier, 32},
	{"natural", "waterfall", CatWaterfall, 30},
	{"waterway", "waterfall", CatWaterfall, 30},
	{"natural", "fjord", CatFjord, 35},
	{"natural", "bay", CatFjord, 20},
	{"natural", "beach", CatBeach, 18},
	{"place", "sea", CatFjord, 25},

	// Озёра и реки. Именованные — в Норвегии их десятки тысяч, и безымянные
	// отсеются проверкой имени в FromTags.
	{"water", "lake", CatLake, 16},
	{"natural", "water", CatLake, 14},
	{"waterway", "river", CatRiver, 15},

	// Смотровые площадки.
	{"tourism", "viewpoint", CatViewpoint, 26},
	{"viewpoint", "yes", CatViewpoint, 24},
	{"natural", "peak", CatViewpoint, 22},

	// Культура. Ставкирки специфичнее музеев, поэтому раньше.
	{"building", "church", CatChurch, 20},
	{"historic", "church", CatChurch, 22},
	{"amenity", "place_of_worship", CatChurch, 16},
	{"tourism", "museum", CatMuseum, 28},
	{"historic", "castle", CatMuseum, 26},
	{"historic", "fort", CatMuseum, 22},
	{"historic", "ruins", CatMuseum, 18},
	{"historic", "archaeological_site", CatMuseum, 18},
	{"tourism", "gallery", CatMuseum, 20},
	{"tourism", "attraction", CatMuseum, 20},
	{"historic", "", CatMuseum, 16},

	// Тропы. Только размеченные маршруты и пути с оценкой сложности.
	//
	// Голые highway=path и footway брать нельзя: первый прогон по району
	// Бергена дал 1227 таких «троп» из 2185 объектов — это дворовые дорожки
	// и городские тротуары с названием улицы. Они не достопримечательности,
	// разбавляют выдачу и портят статистику покрытия.
	{"route", "hiking", CatHike, 24},
	{"sac_scale", "", CatHike, 20},
	{"trail_visibility", "", CatHike, 16},
}

// Classify возвращает категорию и базовую значимость объекта.
// Второй результат false означает, что объект нам не интересен.
func Classify(tags map[string]string) (string, int, bool) {
	for _, r := range rules {
		v, ok := tags[r.key]
		if !ok {
			continue
		}
		if r.value == "" || v == r.value {
			return r.category, r.baseImportance, true
		}
	}
	return "", 0, false
}

// Importance — значимость объекта, 0..100.
//
// Складывается из типа объекта и внешних признаков известности. Ссылка
// на Wikidata или Wikipedia — самый надёжный сигнал: о безымянном ручье
// статью не пишут. Наличие имени обязательно: объект без названия
// показать в списке невозможно.
//
// Формула вынесена отдельно и покрыта тестом намеренно: её будут крутить,
// и без теста правки превратятся в угадывание.
func Importance(tags map[string]string, base int) int {
	score := base

	if _, ok := tags["wikidata"]; ok {
		score += 25
	}
	if _, ok := tags["wikipedia"]; ok {
		score += 20
	}
	if _, ok := tags["website"]; ok {
		score += 5
	}
	if _, ok := tags["opening_hours"]; ok {
		score += 5
	}
	if _, ok := tags["heritage"]; ok {
		score += 10
	}
	if v, ok := tags["tourism"]; ok && v == "attraction" {
		score += 5
	}
	// Объекты ЮНЕСКО в Норвегии наперечёт, и это всегда главные точки.
	if v, ok := tags["heritage:operator"]; ok && v == "whc" {
		score += 15
	}

	if score > 100 {
		score = 100
	}
	if score < 0 {
		score = 0
	}
	return score
}

// Name возвращает каноническое норвежское имя объекта.
//
// Порядок: name:no → name:nb → name → name:nn. Норвежское имя каноническое
// по §4 спеки; все прочие языки живут в таблице translations.
func Name(tags map[string]string) string {
	for _, key := range []string{"name:no", "name:nb", "name", "name:nn"} {
		if v, ok := tags[key]; ok && v != "" {
			return v
		}
	}
	return ""
}

// Tags извлекает мультитеги для профилей пользователя (см. place_tags).
func Tags(tags map[string]string, category string) []string {
	var out []string

	if v, ok := tags["heritage:operator"]; ok && v == "whc" {
		out = append(out, "unesco")
	}
	if v, ok := tags["wheelchair"]; ok && (v == "yes" || v == "limited") {
		out = append(out, "wheelchair")
	}
	// Рыбалка. Тег fishing в OSM ставят и на местах лова, и на запретах,
	// поэтому значение проверяем: fishing=no означает обратное.
	if v, ok := tags["fishing"]; ok && v != "no" {
		out = append(out, "fishing")
	}
	if category == CatLake || category == CatRiver || category == CatBeach {
		out = append(out, "fishing")
	}

	// Охота. Тегов охоты в OSM почти нет, и это честно: она регулируется
	// не картой, а правилами коммуны и согласием землевладельца. Помечаем
	// только явные указания — приложение всё равно отправит проверять
	// правила, а не разрешит охотиться.
	if v, ok := tags["hunting"]; ok && v != "no" {
		out = append(out, "hunting")
	}
	if v, ok := tags["landuse"]; ok && v == "hunting" {
		out = append(out, "hunting")
	}
	if v, ok := tags["tourism"]; ok && v == "aquarium" {
		out = append(out, "kids_friendly")
	}
	if v, ok := tags["seasonal"]; ok && v == "no" {
		out = append(out, "winter_open")
	}
	return out
}

// Season возвращает сезонное ограничение, если оно указано в тегах.
// Горные дороги и высокогорные тропы закрыты примерно с октября по май —
// без этого приложение отправит человека к закрытому шлагбауму.
func Season(tags map[string]string) string {
	if v, ok := tags["seasonal"]; ok && v != "" && v != "no" {
		return v
	}
	if v, ok := tags["opening_hours"]; ok {
		// Часто пишут прямо в часах работы: "Jun-Sep".
		if len(v) <= 16 && (contains(v, "Jun") || contains(v, "May")) {
			return v
		}
	}
	return ""
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
