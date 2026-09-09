import 'package:drift/drift.dart';

import 'database.dart';
import 'connection_stub.dart'
    if (dart.library.io) 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart';

/// Открывает базу приложения.
///
/// ЭТАП 1: база одна, наполняется тестовыми данными. Разделение на два файла
/// (`content.sqlite` только на чтение + `user.sqlite` через ATTACH) вводится
/// на Этапе 2, когда появится реальный контентный пакет из пайплайна.
/// Разделение обязательно по существу: обновление контента не должно стирать
/// избранное и заметки пользователя.
Future<AppDatabase> openAppDatabase() async {
  return AppDatabase(await openConnection());
}

/// Реализуется платформенными файлами.
typedef ConnectionOpener = Future<QueryExecutor> Function();
