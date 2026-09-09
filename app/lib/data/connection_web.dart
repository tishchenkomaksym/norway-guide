import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Подключение в браузере: SQLite собран в WebAssembly, хранилище — OPFS
/// или IndexedDB, что выберет сам drift.
///
/// Требует `web/sqlite3.wasm` и `web/drift_worker.js` — они лежат в репозитории.
///
/// Важно помнить при отладке: это НЕ та же реализация, что на устройстве.
/// Модель хранения другая, и офлайн-поведение здесь проверять нельзя —
/// только на реальном телефоне в авиарежиме.
Future<QueryExecutor> openConnection() async {
  final result = await WasmDatabase.open(
    databaseName: 'nordguide',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );

  if (result.missingFeatures.isNotEmpty) {
    // Не падаем: drift подберёт рабочий вариант хранения, просто менее удобный.
    // ignore: avoid_print
    print('drift web: отсутствуют возможности ${result.missingFeatures}');
  }

  return result.resolvedExecutor;
}
