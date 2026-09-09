import 'package:drift/drift.dart';

import 'database.dart';

/// Тестовые данные для Этапа 1.
///
/// Настоящий контент придёт из Go-пайплайна (`content.sqlite`). Эти два десятка
/// объектов существуют только чтобы экраны было чем наполнить, пока пайплайна
/// нет. Координаты реальные — экран «Рядом со мной» должен показывать
/// осмысленные расстояния при отладке.
///
/// Тексты намеренно короткие и на разных языках, чтобы сразу видеть работу
/// fallback-цепочки §8.4: у части объектов нет русского, у части — только
/// норвежское имя.
Future<void> seedIfEmpty(AppDatabase db) async {
  final existing = await db.allPlaces();
  if (existing.isNotEmpty) return;

  await db.batch((b) {
    b.insertAll(db.regions, [
      RegionsCompanion.insert(
        id: 'vestland',
        nameNo: 'Vestland',
        bbox: '4.0,59.5,8.5,62.5',
        packVersion: 1,
      ),
      RegionsCompanion.insert(
        id: 'rogaland',
        nameNo: 'Rogaland',
        bbox: '5.0,58.2,7.5,59.8',
        packVersion: 1,
      ),
      RegionsCompanion.insert(
        id: 'oslo',
        nameNo: 'Oslo',
        bbox: '10.4,59.8,11.0,60.1',
        packVersion: 1,
      ),
    ]);

    b.insertAll(db.cities, [
      CitiesCompanion.insert(
        id: 'city:bergen',
        regionId: 'vestland',
        nameNo: 'Bergen',
        lat: 60.3913,
        lon: 5.3221,
        population: const Value(289330),
      ),
      CitiesCompanion.insert(
        id: 'city:stavanger',
        regionId: 'rogaland',
        nameNo: 'Stavanger',
        lat: 58.9700,
        lon: 5.7331,
        population: const Value(144699),
      ),
      CitiesCompanion.insert(
        id: 'city:oslo',
        regionId: 'oslo',
        nameNo: 'Oslo',
        lat: 59.9139,
        lon: 10.7522,
        population: const Value(709037),
      ),
    ]);

    b.insertAll(db.places, [
      _place('osm:way/1', 'vestland', 'city:bergen', 'fjord', 'Nærøyfjorden',
          60.9167, 6.9333, 95),
      _place('osm:node/2', 'vestland', 'city:bergen', 'viewpoint', 'Fløyen',
          60.3961, 5.3419, 70),
      _place('osm:way/3', 'vestland', 'city:bergen', 'church', 'Bryggen',
          60.3971, 5.3241, 90),
      _place('osm:node/4', 'vestland', null, 'waterfall', 'Vøringsfossen',
          60.4258, 7.2492, 85),
      _place('osm:node/5', 'vestland', null, 'glacier', 'Nigardsbreen',
          61.6833, 7.2333, 80),
      _place('osm:way/6', 'rogaland', 'city:stavanger', 'viewpoint',
          'Preikestolen', 58.9864, 6.1897, 98,
          difficulty: 'moderate', durationMin: 240),
      _place('osm:way/7', 'rogaland', 'city:stavanger', 'hike', 'Kjeragbolten',
          59.0344, 6.5906, 88,
          difficulty: 'hard', durationMin: 420, season: 'jun-sep'),
      _place('osm:node/8', 'rogaland', 'city:stavanger', 'museum',
          'Norsk Oljemuseum', 58.9750, 5.7311, 60),
      _place('osm:node/9', 'oslo', 'city:oslo', 'museum', 'Munchmuseet',
          59.9061, 10.7553, 75),
      _place('osm:node/10', 'oslo', 'city:oslo', 'museum', 'Frammuseet',
          59.9026, 10.6994, 72),
      _place('osm:way/11', 'oslo', 'city:oslo', 'viewpoint',
          'Holmenkollbakken', 59.9639, 10.6675, 68),
      _place('osm:way/12', 'oslo', 'city:oslo', 'church', 'Akershus festning',
          59.9075, 10.7364, 70),
      _place('osm:node/13', 'vestland', null, 'hike', 'Trolltunga', 60.1242,
          6.7400, 92,
          difficulty: 'hard', durationMin: 600, season: 'jun-sep'),
      _place('osm:node/14', 'vestland', null, 'waterfall', 'Låtefossen',
          59.9481, 6.5808, 55),
      _place('osm:node/15', 'oslo', 'city:oslo', 'viewpoint',
          'Vigelandsanlegget', 59.9270, 10.7005, 78),
    ]);

    // Переводы: en есть у всех, ru только у части, de у половины —
    // чтобы fallback-цепочка была видна сразу.
    b.insertAll(db.translations, [
      ..._tr('osm:way/1', 'en', 'Nærøyfjord',
          'Narrow arm of the Sognefjord, UNESCO World Heritage since 2005.'),
      ..._tr('osm:way/1', 'ru', 'Нерёй-фьорд',
          'Узкий рукав Согне-фьорда, объект ЮНЕСКО с 2005 года.'),
      ..._tr('osm:node/2', 'en', 'Mount Fløyen',
          'City mountain above Bergen, reachable by funicular.'),
      ..._tr('osm:way/3', 'en', 'Bryggen',
          'Hanseatic wharf in Bergen, UNESCO World Heritage.'),
      ..._tr('osm:way/3', 'de', 'Bryggen',
          'Hanseatisches Viertel in Bergen, UNESCO-Welterbe.'),
      ..._tr('osm:node/4', 'en', 'Vøringsfossen',
          'One of the best known waterfalls in Norway, 182 m drop.'),
      ..._tr('osm:node/5', 'en', 'Nigardsbreen',
          'Accessible arm of the Jostedalsbreen glacier.'),
      ..._tr('osm:way/6', 'en', 'Pulpit Rock',
          'Flat cliff 604 m above the Lysefjord. Four hour round trip.'),
      ..._tr('osm:way/6', 'ru', 'Прекестулен',
          'Плоская скала в 604 м над Люсе-фьордом. Четыре часа туда и обратно.'),
      ..._tr('osm:way/6', 'de', 'Preikestolen',
          'Felsplateau 604 m über dem Lysefjord.'),
      ..._tr('osm:way/7', 'en', 'Kjeragbolten',
          'Boulder wedged in a mountain crevasse above the Lysefjord.'),
      ..._tr('osm:node/8', 'en', 'Norwegian Petroleum Museum',
          'Museum about oil and gas in the North Sea.'),
      ..._tr('osm:node/9', 'en', 'Munch Museum',
          'Home to the largest collection of works by Edvard Munch.'),
      ..._tr('osm:node/9', 'ru', 'Музей Мунка',
          'Крупнейшее собрание работ Эдварда Мунка.'),
      ..._tr('osm:node/10', 'en', 'Fram Museum',
          'Museum around the polar ship Fram.'),
      ..._tr('osm:way/11', 'en', 'Holmenkollen Ski Jump',
          'Ski jumping hill with a viewing platform over Oslo.'),
      ..._tr('osm:way/12', 'en', 'Akershus Fortress',
          'Medieval castle guarding the Oslo harbour.'),
      ..._tr('osm:node/13', 'en', 'Trolltunga',
          'Rock shelf jutting horizontally out of a mountain, 700 m above lake Ringedalsvatnet.'),
      ..._tr('osm:node/13', 'de', 'Trolltunga',
          'Horizontal herausragende Felsklippe, 700 m über dem Ringedalsvatnet.'),
      ..._tr('osm:node/14', 'en', 'Låtefossen',
          'Twin waterfall next to the road in Odda.'),
      ..._tr('osm:node/15', 'en', 'Vigeland Park',
          'Sculpture park with more than 200 works by Gustav Vigeland.'),
    ]);

    b.insertAll(db.placeTags, [
      PlaceTagsCompanion.insert(placeId: 'osm:way/1', tag: 'unesco'),
      PlaceTagsCompanion.insert(placeId: 'osm:way/3', tag: 'unesco'),
      PlaceTagsCompanion.insert(placeId: 'osm:way/3', tag: 'near_port'),
      PlaceTagsCompanion.insert(placeId: 'osm:node/8', tag: 'kids_friendly'),
      PlaceTagsCompanion.insert(placeId: 'osm:node/8', tag: 'near_port'),
      PlaceTagsCompanion.insert(placeId: 'osm:node/9', tag: 'winter_open'),
      PlaceTagsCompanion.insert(placeId: 'osm:node/10', tag: 'kids_friendly'),
      PlaceTagsCompanion.insert(placeId: 'osm:node/15', tag: 'kids_friendly'),
      PlaceTagsCompanion.insert(placeId: 'osm:node/2', tag: 'near_port'),
    ]);
  });
}

PlacesCompanion _place(
  String id,
  String regionId,
  String? cityId,
  String category,
  String nameNo,
  double lat,
  double lon,
  int importance, {
  String? difficulty,
  int? durationMin,
  String? season,
}) {
  return PlacesCompanion.insert(
    id: id,
    regionId: regionId,
    cityId: Value(cityId),
    category: category,
    nameNo: nameNo,
    lat: lat,
    lon: lon,
    importance: Value(importance),
    difficulty: Value(difficulty),
    durationMin: Value(durationMin),
    season: Value(season),
  );
}

List<TranslationsCompanion> _tr(
  String id,
  String lang,
  String name,
  String summary,
) {
  return [
    TranslationsCompanion.insert(
      entityType: 'place',
      entityId: id,
      lang: lang,
      name: Value(name),
      summary: Value(summary),
      description: Value(summary),
      source: const Value('manual'),
      quality: const Value(100),
    ),
  ];
}
