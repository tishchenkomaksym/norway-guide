package osm

// Place — извлечённый объект в том виде, в каком он попадает в JSONL
// и затем в таблицу places.
//
// Сырые теги сохраняются целиком намеренно: переобработка не должна
// требовать повторного чтения полуторагигабайтного .pbf. Это же позволяет
// добавлять новые правила классификации, не перезапуская первый проход.
type Place struct {
	ID         string            `json:"id"` // osm:node/123, osm:way/456
	Category   string            `json:"category"`
	NameNo     string            `json:"name_no"`
	Lat        float64           `json:"lat"`
	Lon        float64           `json:"lon"`
	Importance int               `json:"importance"`
	WikidataID string            `json:"wikidata_id,omitempty"`
	Wikipedia  string            `json:"wikipedia,omitempty"`
	Website    string            `json:"website,omitempty"`
	OpeningHrs string            `json:"opening_hours,omitempty"`
	Season     string            `json:"season,omitempty"`
	Difficulty string            `json:"difficulty,omitempty"`
	Tags       []string          `json:"tags,omitempty"`
	RawTags    map[string]string `json:"raw_tags"`
}

// City — населённый пункт. Отдельная сущность, а не место: у города свой
// экран, свой список достопримечательностей и своя статья в Wikivoyage.
type City struct {
	ID         string            `json:"id"`
	NameNo     string            `json:"name_no"`
	Lat        float64           `json:"lat"`
	Lon        float64           `json:"lon"`
	Population int               `json:"population,omitempty"`
	WikidataID string            `json:"wikidata_id,omitempty"`
	Rank       int               `json:"rank"` // 0..100, по типу и населению
	RawTags    map[string]string `json:"raw_tags"`
}

// CityFromTags распознаёт населённый пункт.
//
// Берём city, town и village: Норвегия страна малонаселённая, и Гейрангер
// с его двумя сотнями жителей для гида важнее иного города. Хутора
// (hamlet, isolated_dwelling) отбрасываем — их тысячи и смотреть там нечего.
func CityFromTags(id string, tags map[string]string, lat, lon float64) (City, bool) {
	place, ok := tags["place"]
	if !ok {
		return City{}, false
	}

	rank := 0
	switch place {
	case "city":
		rank = 60
	case "town":
		rank = 45
	case "village":
		rank = 30
	default:
		return City{}, false
	}

	name := Name(tags)
	if name == "" {
		return City{}, false
	}

	population := 0
	if v, ok := tags["population"]; ok {
		population = parseInt(v)
	}
	switch {
	case population > 100000:
		rank += 40
	case population > 20000:
		rank += 30
	case population > 5000:
		rank += 20
	case population > 1000:
		rank += 10
	}
	if _, ok := tags["wikidata"]; ok {
		rank += 10
	}
	if rank > 100 {
		rank = 100
	}

	return City{
		ID:         id,
		NameNo:     name,
		Lat:        lat,
		Lon:        lon,
		Population: population,
		WikidataID: tags["wikidata"],
		Rank:       rank,
		RawTags:    tags,
	}, true
}

func parseInt(s string) int {
	n := 0
	for _, ch := range s {
		if ch < '0' || ch > '9' {
			// Население иногда пишут как "5 000" или "≈1200" — берём
			// то, что успели разобрать, вместо отказа.
			break
		}
		n = n*10 + int(ch-'0')
	}
	return n
}

// Stats — сводка прогона. Отчитываться числами обязательно: «готово»
// без цифр результатом не считается.
type Stats struct {
	TotalScanned  int64
	Matched       int64
	SkippedNoName int64
	ByCategory    map[string]int64
	WithWikidata  int64
	WithWikipedia int64
	// Доля объектов с wikidata по категориям — на этом держится весь
	// последующий этап обогащения.
	WikidataByCategory map[string]int64
}

func NewStats() *Stats {
	return &Stats{
		ByCategory:         map[string]int64{},
		WikidataByCategory: map[string]int64{},
	}
}

func (s *Stats) Add(p Place) {
	s.Matched++
	s.ByCategory[p.Category]++
	if p.WikidataID != "" {
		s.WithWikidata++
		s.WikidataByCategory[p.Category]++
	}
	if p.Wikipedia != "" {
		s.WithWikipedia++
	}
}

// FromTags собирает Place из тегов и координат. Возвращает false, если
// объект не подходит: нет категории или нет имени.
func FromTags(id string, tags map[string]string, lat, lon float64) (Place, bool) {
	category, base, ok := Classify(tags)
	if !ok {
		return Place{}, false
	}

	name := Name(tags)
	if name == "" {
		// Безымянный объект показать в списке нечем.
		return Place{}, false
	}

	return Place{
		ID:         id,
		Category:   category,
		NameNo:     name,
		Lat:        lat,
		Lon:        lon,
		Importance: Importance(tags, base),
		WikidataID: tags["wikidata"],
		Wikipedia:  tags["wikipedia"],
		Website:    tags["website"],
		OpeningHrs: tags["opening_hours"],
		Season:     Season(tags),
		Difficulty: tags["sac_scale"],
		Tags:       Tags(tags, category),
		RawTags:    tags,
	}, true
}
