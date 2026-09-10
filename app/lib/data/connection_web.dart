import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;

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
      final data = await rootBundle.load('assets/db/content.sqlite');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    },
  );

  if (result.missingFeatures.isNotEmpty) {
    // Не падаем: drift подберёт рабочий вариант хранения, просто менее
    // удобный. Сообщение полезно при разборе странностей на чужом браузере.
    // ignore: avoid_print
    print('drift web: отсутствуют возможности ${result.missingFeatures}');
  }

  return result.resolvedExecutor;
}
