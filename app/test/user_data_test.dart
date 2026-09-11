import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/data/database.dart';
import 'package:path/path.dart' as p;

/// Пользовательские данные переживают замену контента.
///
/// Это единственные данные, которые создаёт сам человек: пайплайн может
/// пересобрать что угодно, а заметку о месте — никто. Контентный пакет
/// при обновлении заменяется целиком, поэтому избранное живёт в отдельном
/// файле и подключается через ATTACH.
///
/// Тест работает на настоящих файлах, а не в памяти: проверяется именно
/// то, что замена одного файла не трогает другой.
void main() {
  late Directory dir;
  late File content;
  late File user;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nordguide_test');
    content = File(p.join(dir.path, 'content.sqlite'));
    user = File(p.join(dir.path, 'user.sqlite'));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// Открывает пару файлов так же, как это делает приложение.
  Future<AppDatabase> open() async {
    final db = AppDatabase(
      NativeDatabase(
        content,
        setup: (raw) {
          raw.execute('PRAGMA foreign_keys = ON');
          raw.execute('ATTACH DATABASE ? AS userdata', [user.path]);
        },
      ),
    );
    return db;
  }

  test('избранное переживает замену контентной базы', () async {
    // Первый запуск: создаём контент и пользовательский файл.
    var db = await open();
    await db.into(db.regions).insert(
          RegionsCompanion.insert(
            id: 'r',
            nameNo: 'Region',
            bbox: '0,0,1,1',
            packVersion: 1,
          ),
        );
    await db.into(db.places).insert(
          PlacesCompanion.insert(
            id: 'osm:node/1',
            regionId: 'r',
            category: 'waterfall',
            nameNo: 'Vøringsfossen',
            lat: 60.42,
            lon: 7.24,
          ),
        );
    await db.toggleFavorite('osm:node/1');
    await db.setNote('osm:node/1', 'взять дождевик');
    expect(await db.watchFavorites().first, hasLength(1));
    await db.close();

    final userSizeBefore = await user.length();
    expect(userSizeBefore, greaterThan(0),
        reason: 'пользовательский файл должен быть создан отдельно');

    // Обновление контента: файл заменяется целиком, как это делает
    // приложение при выходе новой версии пакета.
    await content.delete();
    expect(await user.exists(), isTrue,
        reason: 'замена контента не должна касаться пользовательского файла');

    db = await open();
    await db.into(db.regions).insert(
          RegionsCompanion.insert(
            id: 'r',
            nameNo: 'Region v2',
            bbox: '0,0,1,1',
            packVersion: 2,
          ),
        );
    await db.into(db.places).insert(
          PlacesCompanion.insert(
            id: 'osm:node/1',
            regionId: 'r',
            category: 'waterfall',
            nameNo: 'Vøringsfossen',
            lat: 60.42,
            lon: 7.24,
          ),
        );

    final saved = await db.watchFavorites().first;
    expect(saved, hasLength(1), reason: 'избранное потеряно при обновлении');
    expect(saved.first.userNote, 'взять дождевик',
        reason: 'заметка пользователя потеряна при обновлении');
    await db.close();
  });

  test('избранное на место, исчезнувшее из нового пакета, не ломает базу',
      () async {
    // Внешнего ключа на places в пользовательском файле нет намеренно:
    // место может пропасть из нового пакета, и это не повод отказывать
    // в работе всей базе или молча стирать заметку.
    var db = await open();
    await db.into(db.regions).insert(
          RegionsCompanion.insert(
            id: 'r',
            nameNo: 'Region',
            bbox: '0,0,1,1',
            packVersion: 1,
          ),
        );
    await db.into(db.places).insert(
          PlacesCompanion.insert(
            id: 'osm:node/9',
            regionId: 'r',
            category: 'museum',
            nameNo: 'Исчезающий музей',
            lat: 60.0,
            lon: 5.0,
          ),
        );
    await db.toggleFavorite('osm:node/9');
    await db.close();

    // Новый пакет без этого места.
    await content.delete();
    db = await open();
    await db.into(db.regions).insert(
          RegionsCompanion.insert(
            id: 'r',
            nameNo: 'Region v2',
            bbox: '0,0,1,1',
            packVersion: 2,
          ),
        );

    expect(await db.watchFavorites().first, hasLength(1),
        reason: 'запись должна сохраниться даже без места в контенте');
    // Запрос, соединяющий избранное с местами, обязан работать и просто
    // не вернуть пропавшее место.
    final withData = await db.watchFavoritePlaces('ru').first;
    expect(withData, isEmpty);
    await db.close();
  });
}
