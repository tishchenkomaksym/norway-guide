import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';

/// Отдаёт GPX наружу через системный лист «Поделиться».
///
/// Почему именно так, а не «сохранить в папку». У Android и iOS нет
/// общего понятия «папка загрузок», куда приложение может просто
/// положить файл: на iOS его вообще некуда класть так, чтобы человек
/// потом нашёл. Системный лист решает это одинаково на обеих системах —
/// человек сам выбирает, куда файл уходит: в OsmAnd, в почту, в облако.
///
/// Файл пишется во временный каталог. Он не предназначен для хранения:
/// система вычистит его, когда решит, и это правильно — копия уже уехала
/// туда, куда человек её отправил.
Future<void> shareGpx(
  BuildContext context, {
  required String fileName,
  required String content,
  required String subject,
}) async {
  final l = L.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, _safeName(fileName)));
    // Явно UTF-8: имена норвежских мест иначе превратятся в вопросы.
    await file.writeAsString(content, flush: true);

    // Тип указываем явно: без него Android отдаёт файл как
    // «application/octet-stream», и навигаторы не предлагают себя
    // в списке приложений, которыми его можно открыть.
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/gpx+xml')],
      subject: subject,
    );
  } catch (e) {
    // Делиться нечем или человек отменил — не повод показывать
    // текст исключения.
    messenger.showSnackBar(SnackBar(content: Text(l.gpxFailed)));
  }
}

/// Имя файла без символов, которые ломают файловые системы.
///
/// Норвежские буквы оставляем: «Vøringsfossen.gpx» откроется везде,
/// а вот двоеточие в имени не переживёт ни Windows, ни архив.
String _safeName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-').trim();
  return cleaned.isEmpty ? 'route.gpx' : cleaned;
}
