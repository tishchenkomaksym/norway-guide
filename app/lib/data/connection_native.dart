import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart' show AppDatabase;

/// Подключение на iOS, Android и десктопе.
///
/// База не создаётся пустой, а копируется готовой из assets: содержимое
/// готовит Go-пайплайн, приложение его только читает.
///
/// На iOS файл нужно исключать из резервной копии iCloud — иначе туда
/// поедут гигабайты контента, и Apple это отдельно проверяет при ревью.
/// Пока база маленькая, но пометку надо ставить с самого начала.
Future<QueryExecutor> openConnection() async {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nordguide.sqlite'));

    await _ensureContent(file);

    return NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  });
}

/// Разворачивает базу из assets и обновляет её при выходе новой версии.
///
/// Раньше файл копировался только когда его ещё нет. Это тихо ломало любое
/// обновление контента: на устройстве навсегда оставалась база от первой
/// установки. Топ-20 не появился на телефоне именно поэтому — колонки
/// `top_rank` в старом файле не было, а новый файл туда не попадал.
///
/// Версия сравнивается по `PRAGMA user_version`, которую проставляет
/// пайплайн (`packer.SchemaVersion`).
///
/// Обновление контента не должно стирать избранное, а оно пока лежит в том
/// же файле, что и контент. Поэтому перед заменой отметки вычитываются
/// и возвращаются обратно. Правильное решение — отдельный файл БД для
/// пользовательских данных через ATTACH; до него избранное переносится
/// руками, и терять его нельзя.
Future<void> _ensureContent(File file) async {
  if (!await file.exists()) {
    await _copyFromAssets(file);
    return;
  }

  final current = await _readUserVersion(file);
  if (current == AppDatabase.contentSchemaVersion) return;

  final saved = await _readFavorites(file);
  final replaced = await _copyFromAssets(file);
  if (replaced && saved.isNotEmpty) {
    await _restoreFavorites(file, saved);
  }
}

/// Копирует базу из assets поверх файла. Возвращает false, если ассета нет.
Future<bool> _copyFromAssets(File file) async {
  try {
    final data = await rootBundle.load('assets/db/content.sqlite');
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return true;
  } catch (_) {
    // Базы в assets нет — она не хранится в git и собирается пайплайном.
    // Приложение должно остаться запускаемым: drift создаст пустую базу,
    // а seed подставит тестовые данные.
    return false;
  }
}

/// Пользователь исполнителя, который ничего не мигрирует.
///
/// Нужен, чтобы открыть файл и выполнить пару запросов, не втягивая схему
/// drift: если открыть старую базу как [AppDatabase], drift увидит
/// несовпадение версий и полезет мигрировать таблицы, которые мы через
/// секунду заменим целиком.
///
/// Прямой `package:sqlite3` здесь не годится, хотя выглядит проще: его
/// импорт роняет тестовый изолят на загрузке, и все тесты файла начинают
/// сообщать «did not complete» без единой понятной причины.
class _RawUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) =>
      Future.value();
}

Future<T> _withRawDatabase<T>(
  File file,
  Future<T> Function(QueryExecutor executor) action,
  T fallback,
) async {
  final executor = NativeDatabase(file);
  try {
    await executor.ensureOpen(_RawUser());
    return await action(executor);
  } catch (_) {
    return fallback;
  } finally {
    await executor.close();
  }
}

Future<int> _readUserVersion(File file) {
  return _withRawDatabase(file, (executor) async {
    final rows = await executor.runSelect('PRAGMA user_version', const []);
    if (rows.isEmpty) return 0;
    final value = rows.first.values.first;
    return value is int ? value : 0;
    // Файл повреждён или это не база — вернётся -1, и его заменят новым.
  }, -1);
}

Future<List<List<Object?>>> _readFavorites(File file) {
  return _withRawDatabase(file, (executor) async {
    final rows = await executor.runSelect(
      'SELECT place_id, added_at, visited, user_note FROM favorites',
      const [],
    );
    return rows
        .map(
          (r) => [r['place_id'], r['added_at'], r['visited'], r['user_note']],
        )
        .toList();
    // Таблицы ещё нет (первая установка) — переносить нечего, и это
    // не повод отменять обновление контента.
  }, const <List<Object?>>[]);
}

Future<void> _restoreFavorites(File file, List<List<Object?>> saved) async {
  await _withRawDatabase(file, (executor) async {
    for (final row in saved) {
      await executor.runInsert(
        'INSERT OR REPLACE INTO favorites '
        '(place_id, added_at, visited, user_note) VALUES (?, ?, ?, ?)',
        row,
      );
    }
    return null;
    // Не удалось вернуть отметки — приложение всё равно должно открыться
    // с новым контентом.
  }, null);
}
