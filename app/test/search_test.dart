import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/data/database.dart';

/// Поиск принимает то, что человек набрал, и подставляет это в синтаксис
/// FTS5, где значимы кавычки, звёздочки, двоеточия и слова AND/OR/NOT.
/// Неэкранированный ввод роняет запрос прямо во время набора.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Минимальная схема: drift создаст таблицы, FTS добавляем руками —
    // виртуальные таблицы вне его модели.
    await db.customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS search_fts USING fts5(
        entity_type UNINDEXED, entity_id UNINDEXED, lang UNINDEXED,
        name, description,
        prefix = '2 3', tokenize = 'unicode61 remove_diacritics 2')
    ''');

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
            category: 'viewpoint',
            nameNo: 'Preikestolen',
            lat: 58.98,
            lon: 6.18,
            importance: const Value(98),
          ),
        );
    await db
        .into(db.translations)
        .insert(
          TranslationsCompanion.insert(
            entityType: 'place',
            entityId: 'osm:node/1',
            lang: 'en',
            name: const Value('Pulpit Rock'),
            summary: const Value('Flat cliff above the Lysefjord.'),
          ),
        );
    await db.customStatement(
      "INSERT INTO search_fts (entity_type, entity_id, lang, name, description) "
      "VALUES ('place', 'osm:node/1', 'en', 'Pulpit Rock', "
      "'Flat cliff above the Lysefjord.')",
    );
  });

  tearDown(() async => db.close());

  test('находит по началу слова', () async {
    final r = await db.searchPlaces('pulp', 'ru');
    expect(r, hasLength(1));
    expect(r.first.place.nameNo, 'Preikestolen');
  });

  test('находит по слову из описания', () async {
    final r = await db.searchPlaces('lysefjord', 'ru');
    expect(r, hasLength(1));
  });

  test('регистр не важен', () async {
    expect(await db.searchPlaces('PULPIT', 'ru'), hasLength(1));
  });

  test('кавычки в запросе не ломают поиск', () async {
    // Без экранирования это синтаксическая ошибка FTS5.
    expect(await db.searchPlaces('pulpit"', 'ru'), hasLength(1));
    expect(await db.searchPlaces('"', 'ru'), isEmpty);
  });

  test(
    'операторы FTS трактуются как обычные слова, а не как синтаксис',
    () async {
      // Слова AND, OR и NOT в синтаксисе FTS5 значимы. После экранирования
      // они становятся обычными словами: запрос не падает, а просто не
      // находит текст, где этих слов нет.
      expect(await db.searchPlaces('AND', 'ru'), isEmpty);
      expect(await db.searchPlaces('pulpit OR rock', 'ru'), isEmpty);

      // При этом слова из текста находятся, и семантика именно «все слова»:
      // «Bergen museum» должно искать музеи Бергена, а не всё подряд.
      expect(await db.searchPlaces('pulpit rock', 'ru'), hasLength(1));
      expect(await db.searchPlaces('pulpit fjord', 'ru'), isEmpty);
    },
  );

  test('спецсимволы не ломают запрос', () async {
    for (final q in ['*', '()', 'a:b', '^', 'NEAR(', '- -']) {
      // Главное — не исключение: пустая выдача здесь допустима.
      await db.searchPlaces(q, 'ru');
    }
  });

  test('пустой и короткий запрос ничего не находят', () async {
    expect(await db.searchPlaces('', 'ru'), isEmpty);
    expect(await db.searchPlaces('   ', 'ru'), isEmpty);
  });
}
