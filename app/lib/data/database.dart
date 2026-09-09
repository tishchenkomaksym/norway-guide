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
}

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
             COALESCE(t_user.name, t_en.name, p.name_no)             AS res_name,
             COALESCE(t_user.summary, t_en.summary, t_no.summary)    AS res_summary,
             CASE WHEN t_user.summary IS NULL THEN 1 ELSE 0 END      AS is_fallback
      FROM places p
      LEFT JOIN translations t_user
             ON t_user.entity_type = 'place' AND t_user.entity_id = p.id AND t_user.lang = ?
      LEFT JOIN translations t_en
             ON t_en.entity_type   = 'place' AND t_en.entity_id   = p.id AND t_en.lang   = 'en'
      LEFT JOIN translations t_no
             ON t_no.entity_type   = 'place' AND t_no.entity_id   = p.id AND t_no.lang   = 'no'
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
      readsFrom: {places, translations},
    ).get();

    final result = <PlaceWithText>[];
    for (final row in rows) {
      final place = places.map(row.data);
      final d = distanceMeters(lat, lon, place.lat, place.lon);
      if (d > radiusKm * 1000) continue; // bbox — квадрат, радиус — круг
      result.add(
        PlaceWithText(
          place: place,
          name: row.read<String>('res_name'),
          summary: row.readNullable<String>('res_summary'),
          isFallback: row.read<int>('is_fallback') == 1,
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
    final rows = await customSelect(
      '''
      SELECT p.*,
             COALESCE(t_user.name, t_en.name, p.name_no)                 AS res_name,
             COALESCE(t_user.description, t_en.description,
                      t_no.description, t_user.summary, t_en.summary)    AS res_text,
             CASE WHEN t_user.description IS NULL THEN 1 ELSE 0 END      AS is_fallback
      FROM places p
      LEFT JOIN translations t_user
             ON t_user.entity_type = 'place' AND t_user.entity_id = p.id AND t_user.lang = ?
      LEFT JOIN translations t_en
             ON t_en.entity_type   = 'place' AND t_en.entity_id   = p.id AND t_en.lang   = 'en'
      LEFT JOIN translations t_no
             ON t_no.entity_type   = 'place' AND t_no.entity_id   = p.id AND t_no.lang   = 'no'
      WHERE p.id = ?
      ''',
      variables: [Variable<String>(lang), Variable<String>(id)],
      readsFrom: {places, translations},
    ).get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    return PlaceWithText(
      place: places.map(row.data),
      name: row.read<String>('res_name'),
      summary: row.readNullable<String>('res_text'),
      isFallback: row.read<int>('is_fallback') == 1,
    );
  }

  Future<List<Place>> allPlaces() => select(places).get();

  /// Города по убыванию населения: крупные интереснее большинству, а внутри
  /// приложения это ещё и стабильный порядок, не зависящий от языка.
  Future<List<City>> citiesByPopulation() {
    return (select(cities)
          ..orderBy([
            (c) => OrderingTerm(
                  expression: c.population,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// Места одного города с текстом по цепочке §8.4, по убыванию значимости.
  Future<List<PlaceWithText>> placesInCity(String cityId, String lang) async {
    final rows = await customSelect(
      '''
      SELECT p.*,
             COALESCE(t_user.name, t_en.name, p.name_no)             AS res_name,
             COALESCE(t_user.summary, t_en.summary, t_no.summary)    AS res_summary,
             CASE WHEN t_user.summary IS NULL THEN 1 ELSE 0 END      AS is_fallback
      FROM places p
      LEFT JOIN translations t_user
             ON t_user.entity_type = 'place' AND t_user.entity_id = p.id AND t_user.lang = ?
      LEFT JOIN translations t_en
             ON t_en.entity_type   = 'place' AND t_en.entity_id   = p.id AND t_en.lang   = 'en'
      LEFT JOIN translations t_no
             ON t_no.entity_type   = 'place' AND t_no.entity_id   = p.id AND t_no.lang   = 'no'
      WHERE p.city_id = ?
      ORDER BY p.importance DESC
      ''',
      variables: [Variable<String>(lang), Variable<String>(cityId)],
      readsFrom: {places, translations},
    ).get();

    return rows
        .map(
          (row) => PlaceWithText(
            place: places.map(row.data),
            name: row.read<String>('res_name'),
            summary: row.readNullable<String>('res_summary'),
            isFallback: row.read<int>('is_fallback') == 1,
          ),
        )
        .toList();
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
