import 'package:drift/drift.dart';

/// Заглушка для платформ, где нет ни dart:io, ни dart:js_interop.
/// Реально не выбирается никогда — нужна только для условного импорта.
Future<QueryExecutor> openConnection() async {
  throw UnsupportedError('Платформа не поддерживается');
}
