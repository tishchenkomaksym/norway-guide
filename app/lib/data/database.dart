import 'dart:math' as math;

import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// Место вместе с текстом на нужном языке и расстоянием до пользователя.
///
/// Собирается запросом, а не хранится: язык и позиция меняются, дублировать
/// их в таблице незачем.
class PlaceWithText {
  const PlaceWithText({
    required this.place,
    required this.name,
    required this.summary,
    required this.isFallback,
    this.distanceMeters,
    this.bearingDeg,
    this.photoPath,
    this.photoAuthor,
    this.photoLicense,
  });

  final Place place;

  /// Имя на языке пользователя, либо en, либо норвежское — по цепочке §8.4.
  final String name;
  final String? summary;

  /// Текста на языке пользователя не нашлось, показан запасной. UI помечает
  /// это honest-подписью вида «Описание доступно только на английском».
  final bool isFallback;

  /// Заполняется только запросами «рядом со мной».
  final double? distanceMeters;

  /// Направление на объект от пользователя, градусы от севера по часовой.
  final double? bearingDeg;

  /// Путь к фотографии в assets и её атрибуция. Показывать снимок без
  /// автора и лицензии нельзя (§7 спеки), поэтому они ходят вместе.
  final String? photoPath;
  final String? photoAuthor;
  final String? photoLicense;

  bool get hasPhoto => photoPath != null && photoAuthor != null;

  PlaceWithText copyWith({double? distanceMeters, double? bearingDeg}) {
    return PlaceWithText(
      place: place,
      name: name,
      summary: summary,
      isFallback: isFallback,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      bearingDeg: bearingDeg ?? this.bearingDeg,
      photoPath: photoPath,
      photoAuthor: photoAuthor,
      photoLicense: photoLicense,
    );
  }
}

/// Место в избранном: сам объект плюс то, что добавил пользователь.
class FavoritePlace {
  const FavoritePlace({
    required this.place,
    required this.addedAt,
    required this.visited,
    this.note,
  });

  final PlaceWithText place;
  final DateTime addedAt;

  /// Отметка «уже был здесь».
  final bool visited;

  /// Личная заметка. Единственные данные, которые человек создаёт сам,
  /// поэтому терять их при обновлении контента нельзя.
  final String? note;
}

/// Город для карточки обзора: сам город плюс сколько в нём интересного.
class CityCard {
  const CityCard({
    required this.city,
    required this.placeCount,
    required this.notableCount,
    required this.touristScore,
    this.photoPath,
    this.photoAuthor,
    this.photoLicense,
  });

  /// Заглавное фото города и его атрибуция — ходят вместе, потому что
  /// показывать снимок без автора и лицензии нельзя (§7 спеки).
  final String? photoPath;
  final String? photoAuthor;
  final String? photoLicense;

  bool get hasPhoto => photoPath != null && photoAuthor != null;

  final City city;

  /// Всего мест, привязанных к городу.
  final int placeCount;

  /// Из них заметных — то, что стоит показать приезжему.
  final int notableCount;

  /// Оценка туристической ценности; по ней строится порядок в обзоре.
  final int touristScore;
}

/// Общая часть запросов о местах: цепочка подстановки языков §8.4 и фото.
///
/// Вынесена, потому что нужна в четырёх запросах — «рядом», «в городе»,
/// «топ страны» и карточка. Четыре копии разошлись бы при первой правке.
const _placeColumns = '''
       COALESCE(t_user.name, t_en.name, p.name_no)             AS res_name,
       COALESCE(t_user.summary, t_en.summary, t_no.summary)    AS res_summary,
       CASE WHEN t_user.summary IS NULL THEN 1 ELSE 0 END      AS is_fallback,
       ph.path_thumb                                           AS photo_path,
       ph.author                                               AS photo_author,
       ph.license                                              AS photo_license
''';

const _placeJoins = '''
  LEFT JOIN translations t_user
         ON t_user.entity_type = 'place' AND t_user.entity_id = p.id AND t_user.lang = ?
  LEFT JOIN translations t_en
         ON t_en.entity_type   = 'place' AND t_en.entity_id   = p.id AND t_en.lang   = 'en'
  LEFT JOIN translations t_no
         ON t_no.entity_type   = 'place' AND t_no.entity_id   = p.id AND t_no.lang   = 'no'
  LEFT JOIN photos ph ON ph.place_id = p.id
''';

@DriftDatabase(
  tables: [
    Regions,
    Cities,
    Places,
    PlaceTags,
    Photos,
    Routes,
    RouteStops,
    Translations,
    Favorites,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  /// Цепочка подстановки языков по §8.4 спеки: язык пользователя → en → no →
  /// имя из OSM как есть. Приложение никогда не показывает пустой экран.
  ///
  /// Возвращает места, отсортированные по расстоянию от точки. Расстояние
  /// считается в SQL по формуле гаверсинуса, чтобы не тащить в Dart тысячи
  /// строк ради сортировки.
  ///
  /// [radiusKm] отсекает по грубому bbox до расчёта тригонометрии — это даёт
  /// использовать индекс по (lat, lon) вместо полного скана.
  Future<List<PlaceWithText>> placesNearby({
    required double lat,
    required double lon,
    required String lang,
    double radiusKm = 50,
    List<String>? categories,
    int limit = 100,
  }) async {
    // Градус широты ≈ 111.32 км всюду; градус долготы сжимается к полюсам,
    // а Норвегия лежит очень высоко — на 70° он уже втрое короче. Без учёта
    // косинуса bbox на севере оказался бы втрое уже нужного.
    final latDelta = radiusKm / 111.32;
    final cosLat = _cosDeg(lat).abs();
    final lonDelta = cosLat < 0.01 ? 180.0 : radiusKm / (111.32 * cosLat);

    final categoryFilter = categories == null || categories.isEmpty
        ? ''
        : 'AND p.category IN (${categories.map((_) => '?').join(',')})';

    // Расстояние считаем в Dart, а не в SQL: тригонометрия в SQLite доступна
    // только при сборке с SQLITE_ENABLE_MATH_FUNCTIONS, чего нельзя гарантировать
    // на всех платформах. bbox отсекает выборку до сотен строк, поэтому
    // сортировка в Dart дешевле, чем зависимость от опций сборки.
    final rows = await customSelect(
      '''
      SELECT p.*,
      $_placeColumns
      FROM places p
      $_placeJoins
      WHERE p.lat BETWEEN ? AND ?
        AND p.lon BETWEEN ? AND ?
        $categoryFilter
      ''',
      variables: [
        Variable<String>(lang),
        Variable<double>(lat - latDelta),
        Variable<double>(lat + latDelta),
        Variable<double>(lon - lonDelta),
        Variable<double>(lon + lonDelta),
        if (categories != null)
          for (final c in categories) Variable<String>(c),
      ],
      readsFrom: {places, translations, photos},
    ).get();

    final result = <PlaceWithText>[];
    for (final row in rows) {
      final place = places.map(row.data);
      final d = distanceMeters(lat, lon, place.lat, place.lon);
      if (d > radiusKm * 1000) continue; // bbox — квадрат, радиус — круг
      result.add(
        _mapPlace(row).copyWith(
          distanceMeters: d,
          bearingDeg: bearingDegrees(lat, lon, place.lat, place.lon),
        ),
      );
    }
    result.sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
    return result.length > limit ? result.sublist(0, limit) : result;
  }

  /// Одно место с полным текстом для карточки.
  Future<PlaceWithText?> placeById(String id, String lang) async {
    // Здесь берём полный текст, а не summary: это карточка, где человек
    // хочет прочитать про место, а не пробежать список.
    final rows = await customSelect(
      '''
      SELECT p.*,
             COALESCE(t_user.name, t_en.name, p.name_no)                 AS res_name,
             COALESCE(t_user.description, t_en.description,
                      t_no.description, t_user.summary, t_en.summary)    AS res_summary,
             CASE WHEN t_user.description IS NULL THEN 1 ELSE 0 END      AS is_fallback,
             ph.path_full                                                AS photo_path,
             ph.author                                                   AS photo_author,
             ph.license                                                  AS photo_license
      FROM places p
      $_placeJoins
      WHERE p.id = ?
      ''',
      variables: [Variable<String>(lang), Variable<String>(id)],
      readsFrom: {places, translations, photos},
    ).get();

    if (rows.isEmpty) return null;
    return _mapPlace(rows.first);
  }

  /// Полнотекстовый поиск по местам.
  ///
  /// Ищем по языку пользователя И по норвежскому И по английскому
  /// одновременно. Это не избыточность: немец видит на указателе
  /// «Trolltunga», а не немецкое название, и ограничение выдачи локалью
  /// сломало бы самый частый сценарий — набрать то, что написано на
  /// дорожном знаке.
  ///
  /// Ранжирование: сначала совпадение по имени (bm25 с большим весом),
  /// затем значимость места. Иначе безымянный ручей с описанием, где
  /// упомянут Берген, обгонял бы сам Берген.
  Future<List<PlaceWithText>> searchPlaces(String query, String lang,
      {int limit = 40}) async {
    final match = _toFtsQuery(query);
    if (match == null) return [];

    // Запрос плоский, без вложенных выборок: bm25 работает только когда
    // FTS-таблица является прямым источником запроса. И в подзапросе,
    // и внутри агрегата SQLite отвечает «unable to use function bm25».
    //
    // Один объект может совпасть сразу на нескольких языках, поэтому
    // берём с запасом и схлопываем дубликаты в Dart.
    final rows = await customSelect(
      '''
      SELECT p.*,
      $_placeColumns,
             bm25(search_fts, 10.0, 1.0) AS rank
      FROM search_fts
      JOIN places p ON p.id = search_fts.entity_id
      $_placeJoins
      WHERE search_fts MATCH ?
        AND search_fts.entity_type = 'place'
        AND search_fts.lang IN (?, 'en', 'no')
      ORDER BY rank, p.importance DESC
      LIMIT ?
      ''',
      variables: [
        Variable<String>(lang),
        Variable<String>(match),
        Variable<String>(lang),
        Variable<int>(limit * 3),
      ],
      readsFrom: {places, translations, photos},
    ).get();

    final seen = <String>{};
    final result = <PlaceWithText>[];
    for (final row in rows) {
      final place = _mapPlace(row);
      if (!seen.add(place.place.id)) continue;
      result.add(place);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Превращает пользовательский ввод в запрос FTS5.
  ///
  /// Экранирование обязательно: в синтаксисе FTS5 значимы кавычки,
  /// звёздочка, двоеточие, скобки и слова AND/OR/NOT. Набранное человеком
  /// «AND» или случайная кавычка иначе роняют запрос с ошибкой синтаксиса
  /// прямо во время набора.
  ///
  /// Каждое слово берётся в кавычки и получает `*` — префиксный поиск:
  /// «прек» находит «Прекестулен», пока человек ещё печатает.
  static String? _toFtsQuery(String input) {
    final words = input
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;

    return words.map((w) => '"${w.replaceAll('"', '')}"*').join(' ');
  }

  /// Разбирает строку общего запроса о месте.
  PlaceWithText _mapPlace(QueryRow row) {
    return PlaceWithText(
      place: places.map(row.data),
      name: row.read<String>('res_name'),
      summary: row.readNullable<String>('res_summary'),
      isFallback: row.read<int>('is_fallback') == 1,
      photoPath: row.readNullable<String>('photo_path'),
      photoAuthor: row.readNullable<String>('photo_author'),
      photoLicense: row.readNullable<String>('photo_license'),
    );
  }

  Future<List<Place>> allPlaces() => select(places).get();

  /// Города для обзора, отсортированные по туристической ценности.
  ///
  /// Порядок определяет НЕ население. Гейрангер — двести жителей и мировая
  /// известность; пригород Kleppestø — двадцать пять тысяч жителей и смотреть
  /// там нечего. Сортировка по населению поставила бы их наоборот.
  ///
  /// Оценка складывается из:
  ///   * значимости лучшего места в городе — главный сигнал, именно ради
  ///     него человек туда едет;
  ///   * числа заметных мест — один водопад это повод заехать, десять музеев
  ///     это повод остаться;
  ///   * населения — небольшой бонус: в крупном городе есть жильё, транспорт
  ///     и еда, и при прочих равных он удобнее.
  Future<List<CityCard>> cityCards({
    int notableImportance = 65,
    int minNotable = 1,
    int minPopulation = 20000,
  }) async {
    final rows = await customSelect(
      '''
      WITH city_stats AS (
        SELECT c.id,
               (SELECT COUNT(*) FROM places p WHERE p.city_id = c.id) AS place_count,
               (SELECT COUNT(*) FROM places p
                 WHERE p.city_id = c.id AND p.importance >= ?)        AS notable_count,
               (SELECT COALESCE(MAX(p.importance), 0) FROM places p
                 WHERE p.city_id = c.id)                              AS best_place
        FROM cities c
      )
      SELECT c.*,
             s.place_count,
             s.notable_count,
             s.best_place,
             ph.path_thumb AS photo_path,
             ph.author     AS photo_author,
             ph.license    AS photo_license,
             (s.best_place
              + MIN(s.notable_count, 10) * 4
              + CASE
                  WHEN c.population >= 100000 THEN 20
                  WHEN c.population >= 20000  THEN 12
                  WHEN c.population >= 5000   THEN 6
                  ELSE 0
                END) AS tourist_score
      FROM cities c
      JOIN city_stats s ON s.id = c.id
      LEFT JOIN photos ph ON ph.city_id = c.id
      WHERE s.notable_count >= ? OR c.population >= ?
      ORDER BY tourist_score DESC, s.place_count DESC
      ''',
      variables: [
        Variable<int>(notableImportance),
        Variable<int>(minNotable),
        Variable<int>(minPopulation),
      ],
      readsFrom: {cities, places, photos},
    ).get();

    return rows
        .map(
          (row) => CityCard(
            city: cities.map(row.data),
            placeCount: row.read<int>('place_count'),
            notableCount: row.read<int>('notable_count'),
            touristScore: row.read<int>('tourist_score'),
            photoPath: row.readNullable<String>('photo_path'),
            photoAuthor: row.readNullable<String>('photo_author'),
            photoLicense: row.readNullable<String>('photo_license'),
          ),
        )
        .toList();
  }

  /// Категории среди заметных мест и сколько их в каждой.
  ///
  /// Нужно, чтобы показывать плашку категории только когда за ней что-то
  /// стоит: одинокий пляж на всю страну — не категория, а случайность.
  Future<Map<String, int>> topCategoryCounts({int minImportance = 55}) async {
    final rows = await customSelect(
      '''
      SELECT category, COUNT(*) AS n
      FROM places
      WHERE importance >= ?
      GROUP BY category
      ORDER BY n DESC
      ''',
      variables: [Variable<int>(minImportance)],
      readsFrom: {places},
    ).get();

    return {
      for (final row in rows) row.read<String>('category'): row.read<int>('n'),
    };
  }

  /// Самые заметные места по всей базе — для вкладки «Достопримечательности».
  Future<List<PlaceWithText>> topPlaces(
    String lang, {
    int limit = 120,
    List<String>? categories,
  }) async {
    final categoryFilter = categories == null || categories.isEmpty
        ? ''
        : 'WHERE p.category IN (${categories.map((_) => '?').join(',')})';

    final rows = await customSelect(
      '''
      SELECT p.*,
      $_placeColumns
      FROM places p
      $_placeJoins
      $categoryFilter
      ORDER BY p.importance DESC
      LIMIT ?
      ''',
      variables: [
        Variable<String>(lang),
        if (categories != null)
          for (final c in categories) Variable<String>(c),
        Variable<int>(limit),
      ],
      readsFrom: {places, translations, photos},
    ).get();

    return rows.map(_mapPlace).toList();
  }

  /// Места одного города с текстом по цепочке §8.4, по убыванию значимости.
  Future<List<PlaceWithText>> placesInCity(String cityId, String lang) async {
    final rows = await customSelect(
      '''
      SELECT p.*,
      $_placeColumns
      FROM places p
      $_placeJoins
      WHERE p.city_id = ?
      ORDER BY p.importance DESC
      ''',
      variables: [Variable<String>(lang), Variable<String>(cityId)],
      readsFrom: {places, translations, photos},
    ).get();

    return rows.map(_mapPlace).toList();
  }

  /// Все мультитеги одной выборкой: `placeId → {tag}`.
  ///
  /// Тегов на порядки меньше, чем мест, поэтому дешевле прочитать их разом,
  /// чем джойнить на каждый запрос ранжирования.
  Future<Map<String, Set<String>>> allPlaceTags() async {
    final rows = await select(placeTags).get();
    final map = <String, Set<String>>{};
    for (final row in rows) {
      map.putIfAbsent(row.placeId, () => <String>{}).add(row.tag);
    }
    return map;
  }

  Stream<List<Favorite>> watchFavorites() => select(favorites).watch();

  /// Избранное вместе с данными мест.
  ///
  /// Это и есть довод в пользу одного подключения к двум файлам базы
  /// (см. CLAUDE.md): избранное лежит в пользовательской БД, места —
  /// в контентной, а джойн между ними обычный. Иначе пришлось бы тянуть
  /// сотни идентификаторов в `WHERE id IN (...)`.
  ///
  /// Стрим, а не разовый запрос: список обязан обновляться сразу после
  /// того, как человек снял сердечко на карточке места.
  Stream<List<FavoritePlace>> watchFavoritePlaces(String lang) {
    return customSelect(
      '''
      SELECT p.*,
      $_placeColumns,
             f.added_at  AS fav_added_at,
             f.visited   AS fav_visited,
             f.user_note AS fav_note
      FROM favorites f
      JOIN places p ON p.id = f.place_id
      $_placeJoins
      ORDER BY f.added_at DESC
      ''',
      variables: [Variable<String>(lang)],
      readsFrom: {favorites, places, translations, photos},
    ).watch().map(
          (rows) => rows
              .map(
                (row) => FavoritePlace(
                  place: _mapPlace(row),
                  addedAt: DateTime.fromMillisecondsSinceEpoch(
                      row.read<int>('fav_added_at')),
                  visited: row.read<int>('fav_visited') == 1,
                  note: row.readNullable<String>('fav_note'),
                ),
              )
              .toList(),
        );
  }

  Future<void> setVisited(String placeId, bool visited) {
    return (update(favorites)..where((f) => f.placeId.equals(placeId)))
        .write(FavoritesCompanion(visited: Value(visited)));
  }

  Future<void> setNote(String placeId, String? note) {
    return (update(favorites)..where((f) => f.placeId.equals(placeId)))
        .write(FavoritesCompanion(
      userNote: Value(note == null || note.trim().isEmpty ? null : note.trim()),
    ));
  }

  Future<void> removeFavorite(String placeId) {
    return (delete(favorites)..where((f) => f.placeId.equals(placeId))).go();
  }

  Future<void> toggleFavorite(String placeId) async {
    final existing = await (select(favorites)
          ..where((f) => f.placeId.equals(placeId)))
        .getSingleOrNull();
    if (existing == null) {
      await into(favorites).insert(
        FavoritesCompanion.insert(
          placeId: placeId,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } else {
      await (delete(favorites)..where((f) => f.placeId.equals(placeId))).go();
    }
  }
}

const _degToRad = math.pi / 180.0;

double _cosDeg(double deg) => math.cos(deg * _degToRad);

/// Расстояние по гаверсинусу, в метрах.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = (lat2 - lat1) * _degToRad;
  final dLon = (lon2 - lon1) * _degToRad;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * _degToRad) *
          math.cos(lat2 * _degToRad) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Направление на объект, в градусах от севера по часовой стрелке.
double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  final dLon = (lon2 - lon1) * _degToRad;
  final y = math.sin(dLon) * math.cos(lat2 * _degToRad);
  final x = math.cos(lat1 * _degToRad) * math.sin(lat2 * _degToRad) -
      math.sin(lat1 * _degToRad) * math.cos(lat2 * _degToRad) * math.cos(dLon);
  final deg = math.atan2(y, x) / _degToRad;
  return (deg + 360) % 360;
}
