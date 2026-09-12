import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/data/database.dart';

/// Запросы, возвращающие места вместе с фотографиями.
///
/// Эти запросы написаны сырым SQL внутри строк, поэтому анализатор их не
/// проверяет: опечатка в имени колонки доживает до устройства и падает уже
/// у человека в руках. Ровно так и вышло — подзапрос выбора одной
/// фотографии не отдавал `path_full`, и карточка любого места показывала
/// текст исключения вместо снимка и описания.
///
/// Второй повод для этих тестов — дубликаты. Пока у места была одна
/// фотография, обычный `LEFT JOIN photos` работал правильно; с появлением
/// галереи он начал бы размножать само место по числу снимков.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    await db.into(db.regions).insert(
          RegionsCompanion.insert(
            id: 'r',
            nameNo: 'Region',
            bbox: '0,0,1,1',
            packVersion: 1,
          ),
        );
    await db.into(db.cities).insert(
          CitiesCompanion.insert(
            id: 'city:1',
            regionId: 'r',
            nameNo: 'Bergen',
            lat: 60.39,
            lon: 5.32,
            population: const Value(280000),
          ),
        );
    await db.into(db.places).insert(
          PlacesCompanion.insert(
            id: 'osm:way/1',
            regionId: 'r',
            cityId: const Value('city:1'),
            category: 'viewpoint',
            nameNo: 'Preikestolen',
            lat: 58.98,
            lon: 6.19,
            importance: const Value(90),
            topRank: const Value(1),
            visitors: const Value(300000),
            visitorsYear: const Value(2024),
            unesco: const Value(0),
          ),
        );
    await db.into(db.translations).insert(
          TranslationsCompanion.insert(
            entityType: 'place',
            entityId: 'osm:way/1',
            lang: 'en',
            name: const Value('Preikestolen'),
            summary: const Value('A cliff above Lysefjorden.'),
            // Описания хранятся сжатыми; несжатые байты тоже читаются —
            // на это в decompressText есть запасной путь.
            description: Value(
              Uint8List.fromList(utf8.encode('A cliff above Lysefjorden.')),
            ),
            source: const Value('wikipedia'),
          ),
        );

    // Три снимка у одного места — то, ради чего заводилась галерея.
    for (var i = 1; i <= 3; i++) {
      await db.into(db.photos).insert(
            PhotosCompanion.insert(
              id: Value(i),
              placeId: const Value('osm:way/1'),
              pathThumb: 'assets/photos/p_$i.jpg',
              pathFull: 'assets/photos/p_$i.jpg',
              author: 'Автор $i',
              license: 'CC BY-SA 4.0',
              sourceUrl: 'https://commons.wikimedia.org/wiki/File:p_$i.jpg',
            ),
          );
    }
  });

  tearDown(() async => db.close());

  test('карточка места открывается и отдаёт снимок', () async {
    final item = await db.placeById('osm:way/1', 'en');

    expect(item, isNotNull, reason: 'место должно находиться по идентификатору');
    expect(item!.name, 'Preikestolen');
    expect(item.summary, isNotNull);
    expect(item.photoPath, isNotNull, reason: 'в шапке карточки нужен снимок');
    expect(item.photoAuthor, isNotNull, reason: 'CC BY-SA требует атрибуции');
  });

  test('несколько снимков не размножают место в списках', () async {
    final nearby = await db.placesNearby(
      lat: 58.98,
      lon: 6.19,
      lang: 'en',
      radiusKm: 50,
    );
    expect(nearby.where((p) => p.place.id == 'osm:way/1'), hasLength(1));

    final top = await db.topPlaces('en');
    expect(top.where((p) => p.place.id == 'osm:way/1'), hasLength(1));

    final inCity = await db.placesInCity('city:1', 'en');
    expect(inCity.where((p) => p.place.id == 'osm:way/1'), hasLength(1));
  });

  test('топ самых посещаемых отдаётся по порядку и с числами', () async {
    final top = await db.mostVisitedPlaces('en');

    expect(top, hasLength(1));
    expect(top.first.place.topRank, 1);
    expect(top.first.place.visitors, 300000);
    expect(top.first.place.visitorsYear, 2024,
        reason: 'число посещаемости без года показывать нельзя');
  });

  test('галерея отдаёт все снимки места', () async {
    final photos = await db.photosForPlace('osm:way/1');

    expect(photos, hasLength(3));
    // У каждого снимка свой автор: подпись обязана меняться при листании,
    // иначе второму кадру приписывается автор первого.
    expect(photos.map((p) => p.author).toSet(), hasLength(3));
  });

  test('город с местами попадает в список', () async {
    final cards = await db.cityCards();
    expect(cards.where((c) => c.city.id == 'city:1'), hasLength(1));
  });
}
