import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart' show AppDatabase;

/// Подключение на iOS, Android и десктопе.
///
/// Файлов два, и это принципиально:
///
/// - `content.sqlite` — контент из пайплайна, только на чтение. При выходе
///   новой версии данных заменяется целиком.
/// - `user.sqlite` — избранное, заметки, отметки «был здесь». Создаётся
///   приложением и не трогается никогда.
///
/// Второй подключается к первому через ATTACH, поэтому для drift это одна
/// база: запросы могут соединять избранное с местами, как раньше.
///
/// Почему не одна база. Контентный пакет заменяется целиком, и всё, что
/// лежит рядом с ним, при замене исчезает. Раньше отметки приходилось
/// вычитывать перед заменой и возвращать обратно — работало, но каждое
/// обновление было шансом потерять то, что человек создал сам и что
/// не восстанавливается ничем.
///
/// На iOS `content.sqlite` нужно исключать из резервной копии iCloud —
/// туда не должны уезжать гигабайты контента, Apple это проверяет при
/// ревью. А вот `user.sqlite` в бэкап как раз должен попадать.
Future<QueryExecutor> openConnection() async {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final content = File(p.join(dir.path, 'nordguide.sqlite'));
    final user = File(p.join(dir.path, 'user.sqlite'));

    final rescued = await _ensureContent(content);
    await _ensureUser(user, rescued);

    return NativeDatabase.createInBackground(
      content,
      setup: (db) {
        db.execute('PRAGMA foreign_keys = ON');
        // ATTACH под именем main нельзя, поэтому пользовательские таблицы
        // видны как user.favorites. Схема drift знает их без префикса,
        // и чтобы запросы не переписывать, файл подключается под именем,
        // совпадающим с ожидаемым: drift ищет favorites в main, а SQLite
        // разрешает неквалифицированное имя по всем подключённым базам,
        // если в main такой таблицы нет.
        db.execute("ATTACH DATABASE ? AS userdata", [user.path]);
      },
    );
  });
}

/// Разворачивает контентную базу и обновляет её при выходе новой версии.
///
/// Возвращает отметки, спасённые из старой базы: до разделения файлов
/// избранное хранилось вместе с контентом, и при первом запуске новой
/// версии его нужно перенести в user.sqlite.
Future<List<List<Object?>>> _ensureContent(File file) async {
  if (!await file.exists()) {
    await _copyFromAssets(file);
    return const [];
  }

  final current = await _readUserVersion(file);
  if (current == AppDatabase.contentSchemaVersion) return const [];

  // Старая база могла быть ещё «слитной» — с таблицей favorites внутри.
  // Забираем отметки до замены: другого их источника нет.
  final saved = await _readLegacyFavorites(file);
  await _copyFromAssets(file);
  return saved;
}

/// Создаёт пользовательский файл и переносит в него спасённые отметки.
Future<void> _ensureUser(File file, List<List<Object?>> rescued) async {
  final existed = await file.exists();

  await _withRawDatabase(file, (executor) async {
    await executor.runCustom(
      'CREATE TABLE IF NOT EXISTS favorites ('
      'place_id TEXT PRIMARY KEY, added_at INTEGER NOT NULL, '
      'visited INTEGER NOT NULL DEFAULT 0, user_note TEXT)',
      const [],
    );
    if (rescued.isNotEmpty) {
      for (final row in rescued) {
        await executor.runInsert(
          'INSERT OR IGNORE INTO favorites '
          '(place_id, added_at, visited, user_note) VALUES (?, ?, ?, ?)',
          row,
        );
      }
    }
    return null;
  }, null);

  if (!existed) {
    // Отдельная пометка в логе не нужна: файл создаётся один раз и молча.
  }
}

/// Копирует контентную базу из assets поверх файла.
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
/// drift: иначе drift увидит несовпадение версий и полезет мигрировать
/// таблицы, которые через секунду будут заменены целиком.
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

/// Читает избранное из «слитной» базы прежних версий.
///
/// Возвращает пустой список, если таблицы нет — значит база уже новая
/// и переносить нечего.
Future<List<List<Object?>>> _readLegacyFavorites(File file) {
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
  }, const <List<Object?>>[]);
}
