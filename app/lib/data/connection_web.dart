import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'database.dart' show AppDatabase;

/// Подключение в браузере: SQLite собран в WebAssembly, хранилище — OPFS
/// или IndexedDB, что выберет сам drift.
///
/// Требует `web/sqlite3.wasm` и `web/drift_worker.js` — они лежат в
/// репозитории и обязаны соответствовать версии drift из pubspec.lock.
///
/// Важно помнить при отладке: это НЕ та же реализация, что на устройстве.
/// Модель хранения другая, и офлайн-поведение здесь проверять нельзя —
/// только на реальном телефоне в авиарежиме.
Future<QueryExecutor> openConnection() async {
  final result = await WasmDatabase.open(
    databaseName: 'nordguide',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
    // Вызывается только когда базы ещё нет: содержимое готовит Go-пайплайн,
    // приложение его не создаёт.
    initializeDatabase: () async {
      try {
        final data = await rootBundle.load('assets/db/content.sqlite');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } catch (_) {
        // Базы в assets нет — она не хранится в git и собирается пайплайном.
        // Возвращаем null: drift создаст пустую, а seed подставит тестовые
        // данные, чтобы приложение осталось запускаемым.
        return null;
      }
    },
  );

  // Та же ловушка, что была на устройстве: initializeDatabase вызывается
  // только когда базы ещё нет, поэтому в браузере навсегда оставался бы
  // слепок от первого запуска. На телефоне это скрыло целый новый раздел.
  //
  // В браузере файл подменить нельзя, поэтому просто предупреждаем: web —
  // среда разработки, релиз идёт на Android и iOS, а очистить хранилище
  // сайта разработчик умеет. Молчать об этом нельзя: расхождение выглядит
  // как «код не работает», хотя работает старая база.
  try {
    final rows = await result.resolvedExecutor.runSelect(
      'PRAGMA user_version',
      const [],
    );
    final version = rows.isEmpty ? 0 : rows.first.values.first;
    if (version != AppDatabase.contentSchemaVersion) {
      // ignore: avoid_print
      print(
        'drift web: в хранилище база версии $version, '
        'код ждёт ${AppDatabase.contentSchemaVersion}. '
        'Очистите данные сайта, иначе видны старые данные.',
      );
    }
  } catch (_) {
    // Версию прочитать не удалось — не повод не запускаться.
  }

  if (result.missingFeatures.isNotEmpty) {
    // Не падаем: drift подберёт рабочий вариант хранения, просто менее
    // удобный. Сообщение полезно при разборе странностей на чужом браузере.
    // ignore: avoid_print
    print('drift web: отсутствуют возможности ${result.missingFeatures}');
  }

  return result.resolvedExecutor;
}
