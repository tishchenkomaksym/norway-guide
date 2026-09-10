import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

    if (!await file.exists()) {
      final data = await rootBundle.load('assets/db/content.sqlite');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }

    return NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  });
}
