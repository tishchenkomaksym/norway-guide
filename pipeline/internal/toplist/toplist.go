// Package toplist — курируемый список самых посещаемых мест Норвегии.
//
// Зачем список задан руками, а не выведен из данных. Наш `importance`
// считается по признакам разметки: есть ли статья в Wikipedia, отмечен ли
// объект как наследие, насколько подробно размечен в OSM. Это хорошая
// оценка «насколько объект известен», но она не отвечает на вопрос «куда
// на самом деле едут люди». Тролльтунга размечена одной точкой и по
// формальным признакам проигрывает районной церкви, хотя к ней идут
// десятки тысяч человек в год.
//
// Вторая причина — автоматическое извлечение из OSM просто не видит часть
// главных достопримечательностей. Наши категории покрывают фьорды, музеи,
// водопады, смотровые, церкви, тропы, пляжи, ледники, озёра и реки. Парк
// скульптур, лыжный трамплин, горная дорога, железная дорога и архипелаг
// не попадают ни в одну из них. Из двадцати пяти проверенных объектов
// девять отсутствовали в извлечении — включая Нордкапп, Лофотены,
// Тролльстиген и Фломскую железную дорогу.
//
// Поэтому список задан явно, с координатами и идентификаторами Wikidata.
// Тексты и фотографии для него добираются обычным путём — через enrich
// и media, а не пишутся руками.
//
// О числах посещаемости. Единой официальной статистики по
// достопримечательностям Норвегии не публикуется: SSB считает ночёвки и
// поездки, а не входы в конкретные места. Числа ниже собраны из разных
// источников и в разные годы, поэтому у каждого проставлен год и ссылка,
// а там, где надёжного числа нет, стоит ноль — и приложение просто не
// показывает цифру. Выдумывать посещаемость нельзя: она выглядит как факт
// и будет процитирована.
//
// Чего здесь намеренно нет: рейтингов и отзывов с TripAdvisor, Visit
// Norway и Lonely Planet. Их контент защищён, сбор запрещён (§7 спеки).
// Сам факт «место популярно» — общеизвестное знание, а не их собственность,
// и именно он здесь и зафиксирован.
package toplist

// Attraction — место из курируемого списка.
//
// Rank — позиция в топе, 1 — самое посещаемое. Порядок задан руками
// и осознанно: он смешивает посещаемость там, где она известна, со
// статусом ЮНЕСКО и узнаваемостью.
//
// Rank == 0 значит «нужно в каталоге, но не в топе». Так помечаются
// объекты, которых нет в извлечении из OSM и которые попадают в базу
// только отсюда: убрать их из списка — значит удалить из приложения.
type Attraction struct {
	Rank         int     `json:"rank"`
	QID          string  `json:"qid"`
	Name         string  `json:"name"`
	Lat          float64 `json:"lat"`
	Lon          float64 `json:"lon"`
	Category     string  `json:"category"`
	Visitors     int     `json:"visitors"`      // 0 — надёжного числа нет
	VisitorsYear int     `json:"visitors_year"` // год, к которому относится число
	// Source — где проверить число посещаемости или статус.
	// Обязателен: без него цифру показывать нельзя.
	Source string `json:"source"`
	// UNESCO — объект списка Всемирного наследия.
	UNESCO bool `json:"unesco"`
}

// All — топ-25. Порядок значим: он и есть Rank.
var All = []Attraction{
	{
		Rank: 1, QID: "Q746223", Name: "Preikestolen",
		Lat: 58.9864, Lon: 6.1904, Category: "viewpoint",
		Visitors: 300000, VisitorsYear: 2024,
		Source: "https://en.wikipedia.org/wiki/Preikestolen",
	},
	{
		Rank: 2, QID: "Q193989", Name: "Geirangerfjorden",
		Lat: 62.1008, Lon: 7.0947, Category: "fjord",
		UNESCO: true,
		Source: "https://whc.unesco.org/en/list/1195/",
	},
	{
		Rank: 3, QID: "Q153430", Name: "Bryggen",
		Lat: 60.3975, Lon: 5.3242, Category: "museum",
		UNESCO: true,
		Source: "https://whc.unesco.org/en/list/59/",
	},
	{
		Rank: 4, QID: "Q117767", Name: "Fløibanen",
		Lat: 60.3967, Lon: 5.3272, Category: "viewpoint",
		Visitors: 1131707, VisitorsYear: 2007,
		Source: "https://en.wikipedia.org/wiki/Fl%C3%B8ibanen",
	},
	{
		Rank: 5, QID: "Q1512593", Name: "Trolltunga",
		Lat: 60.1242, Lon: 6.7400, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/Trolltunga",
	},
	{
		Rank: 6, QID: "Q212205", Name: "Nærøyfjord",
		Lat: 60.9167, Lon: 6.9333, Category: "fjord",
		UNESCO: true,
		Source: "https://whc.unesco.org/en/list/1195/",
	},
	{
		Rank: 7, QID: "Q7460945", Name: "Vigelandsanlegget",
		Lat: 59.9269, Lon: 10.6997, Category: "museum",
		Source: "https://en.wikipedia.org/wiki/Vigeland_installation",
	},
	{
		Rank: 8, QID: "Q4069", Name: "Nordkapp",
		Lat: 71.1725, Lon: 25.7844, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/North_Cape_(Norway)",
	},
	{
		Rank: 9, QID: "Q186822", Name: "Lofoten",
		Lat: 68.3333, Lon: 14.6667, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/Lofoten",
	},
	{
		// Рейне стоит отдельной строкой, хотя Лофотены уже в списке выше.
		// Архипелаг — это направление, а Рейне — конкретная точка, ради
		// которой туда едут: самая фотографируемая деревня страны.
		// Растворять её в регионе неправильно, человек ищет именно её.
		Rank: 10, QID: "Q593597", Name: "Reine",
		Lat: 67.9322, Lon: 13.0894, Category: "viewpoint",
		Source: "https://no.wikipedia.org/wiki/Reine",
	},
	{
		Rank: 11, QID: "Q215023", Name: "Nidarosdomen",
		Lat: 63.4269, Lon: 10.3969, Category: "church",
		Source: "https://en.wikipedia.org/wiki/Nidaros_Cathedral",
	},
	{
		Rank: 12, QID: "Q33572", Name: "Holmenkollbakken",
		Lat: 59.9639, Lon: 10.6667, Category: "viewpoint",
		Visitors: 686857, VisitorsYear: 2007,
		Source: "https://en.wikipedia.org/wiki/Holmenkollbakken",
	},
	{
		Rank: 13, QID: "Q940332", Name: "Trollstigen",
		Lat: 62.4575, Lon: 7.6708, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/Trollstigen",
	},
	{
		Rank: 14, QID: "Q402957", Name: "Flåmsbana",
		Lat: 60.8636, Lon: 7.1136, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/Fl%C3%A5m_Line",
	},
	{
		Rank: 15, QID: "Q756561", Name: "Atlanterhavsveien",
		Lat: 63.0125, Lon: 7.3506, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/Atlantic_Ocean_Road",
	},
	{
		Rank: 16, QID: "Q38588", Name: "Vøringsfossen",
		Lat: 60.4267, Lon: 7.2506, Category: "waterfall",
		Source: "https://en.wikipedia.org/wiki/V%C3%B8ringsfossen",
	},
	{
		Rank: 17, QID: "Q1477173", Name: "Kjeragbolten",
		Lat: 59.0342, Lon: 6.5931, Category: "viewpoint",
		Source: "https://en.wikipedia.org/wiki/Kjeragbolten",
	},
	{
		Rank: 18, QID: "Q43280", Name: "Operahuset i Oslo",
		Lat: 59.9075, Lon: 10.7528, Category: "museum",
		Source: "https://en.wikipedia.org/wiki/Oslo_Opera_House",
	},
	{
		Rank: 19, QID: "Q844926", Name: "Munchmuseet",
		Lat: 59.9061, Lon: 10.7556, Category: "museum",
		Source: "https://en.wikipedia.org/wiki/Munch_Museum",
	},
	{
		Rank: 20, QID: "Q210678", Name: "Urnes stavkyrkje",
		Lat: 61.2981, Lon: 7.3222, Category: "church",
		UNESCO: true,
		Source: "https://whc.unesco.org/en/list/58/",
	},
	{
		Rank: 21, QID: "Q644464", Name: "Akershus festning",
		Lat: 59.9078, Lon: 10.7364, Category: "museum",
		Source: "https://en.wikipedia.org/wiki/Akershus_Fortress",
	},
	{
		// Согне-фьорд — самый длинный и глубокий фьорд страны, 205 км.
		// Нерёй-фьорд из списка ЮНЕСКО выше — его боковой рукав, но сам
		// Согне-фьорд отдельное направление: Флом, Балестранд, Ундредал.
		Rank: 22, QID: "Q208495", Name: "Sognefjorden",
		Lat: 61.1000, Lon: 5.1667, Category: "fjord",
		Source: "https://en.wikipedia.org/wiki/Sognefjord",
	},
	{
		// Рёрус — горнозаводской город с деревянной застройкой XVII века,
		// объект ЮНЕСКО. Единственный в топе объект вне побережья и
		// единственный, куда едут зимой ради самого города.
		Rank: 23, QID: "Q108999", Name: "Røros",
		Lat: 62.5742, Lon: 11.3831, Category: "museum",
		UNESCO: true,
		Source: "https://whc.unesco.org/en/list/55/",
	},
	{
		// Бессегген — самый ходимый маршрут Норвегии: гребень между двумя
		// озёрами разного цвета в Йотунхеймене. В списке нет ни одного
		// горного похода вне скальных площадок, а это отдельный повод
		// приехать в страну.
		Rank: 24, QID: "Q830100", Name: "Besseggen",
		Lat: 61.5042, Lon: 8.7320, Category: "hike",
		Source: "https://en.wikipedia.org/wiki/Besseggen",
	},
	{
		// Хардангер-фьорд — «сад Норвегии», цветение яблонь в мае.
		// Тролльтунга и Вёрингсфоссен из списка стоят на нём, но сам
		// фьорд — самостоятельное направление с другим сезоном.
		Rank: 25, QID: "Q841491", Name: "Hardangerfjorden",
		Lat: 60.1667, Lon: 6.0000, Category: "fjord",
		Source: "https://en.wikipedia.org/wiki/Hardangerfjord",
	},
}

// ByQID возвращает место топа по идентификатору Wikidata.
func ByQID(qid string) (Attraction, bool) {
	for _, a := range All {
		if a.QID == qid {
			return a, true
		}
	}
	return Attraction{}, false
}
