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
