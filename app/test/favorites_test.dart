// Value скрываем адресно: drift экспортирует isNull, и он конфликтует
// с матчером из test.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/data/database.dart';

/// Избранное — единственные данные, которые создаёт сам пользователь.
/// Пайплайн может пересобрать что угодно, а заметку о месте — никто,
/// поэтому проверяется именно сохранность.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.regions)
        .insert(
          RegionsCompanion.insert(
            id: 'r',
            nameNo: 'Region',
            bbox: '0,0,1,1',
            packVersion: 1,
          ),
        );
    await db
        .into(db.places)
        .insert(
          PlacesCompanion.insert(
            id: 'osm:node/1',
            regionId: 'r',
            category: 'waterfall',
            nameNo: 'Vøringsfossen',
            lat: 60.42,
            lon: 7.24,
            importance: const Value(85),
          ),
        );
  });

  tearDown(() async => db.close());

  test('сердечко добавляет и убирает место', () async {
    await db.toggleFavorite('osm:node/1');
    expect(await db.watchFavorites().first, hasLength(1));

    await db.toggleFavorite('osm:node/1');
    expect(await db.watchFavorites().first, isEmpty);
  });

  test('избранное отдаётся вместе с данными места', () async {
    await db.toggleFavorite('osm:node/1');
    final list = await db.watchFavoritePlaces('ru').first;

    expect(list, hasLength(1));
    // Перевода нет — работает цепочка подстановки до норвежского имени.
    expect(list.first.place.name, 'Vøringsfossen');
    expect(list.first.place.place.category, 'waterfall');
    expect(list.first.visited, isFalse);
  });

  test('отметка «был здесь» сохраняется', () async {
    await db.toggleFavorite('osm:node/1');
    await db.setVisited('osm:node/1', true);

    final list = await db.watchFavoritePlaces('ru').first;
    expect(list.first.visited, isTrue);
  });

  test('заметка сохраняется и стирается', () async {
    await db.toggleFavorite('osm:node/1');
    await db.setNote('osm:node/1', 'Парковка платная, 100 крон');

    var list = await db.watchFavoritePlaces('ru').first;
    expect(list.first.note, 'Парковка платная, 100 крон');

    // Пустая строка означает «убрать заметку», а не сохранить пустоту.
    await db.setNote('osm:node/1', '   ');
    list = await db.watchFavoritePlaces('ru').first;
    expect(list.first.note, isNull);
  });

  test('удаление из избранного не трогает само место', () async {
    await db.toggleFavorite('osm:node/1');
    await db.removeFavorite('osm:node/1');

    expect(await db.watchFavoritePlaces('ru').first, isEmpty);
    // Место остаётся в каталоге: удалялась закладка, а не объект.
    expect(await db.allPlaces(), hasLength(1));
  });

  test('список обновляется без повторного запроса', () async {
    final stream = db.watchFavoritePlaces('ru');
    final future = stream.skip(1).first;

    await db.toggleFavorite('osm:node/1');
    expect(await future, hasLength(1));
  });
}
