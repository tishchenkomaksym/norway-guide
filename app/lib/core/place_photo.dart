import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'packs.dart';

/// Снимок места — из бандла или из скачанного пакета.
///
/// Зачем отдельный виджет. После разделения на уровни один и тот же путь
/// в базе (`assets/photos/xxx.jpg`) может указывать на два разных места:
/// снимок топ-места лежит в бандле приложения, а снимок обычного места —
/// в каталоге скачанного регионального пакета. Разбираться в этом в каждом
/// списке и карточке — верный способ однажды показать пустоту там, где
/// фотография есть.
///
/// Порядок поиска: сначала скачанный файл, потом бандл. Именно в таком,
/// а не наоборот: если человек скачал регион, у него лежит свежая версия
/// снимка, и она должна побеждать.
///
/// Когда фотографии нет нигде — показывается [fallback]. Это не ошибка,
/// а обычное состояние: у части мест снимка нет вовсе, а у части он
/// появится после скачивания региона.
class PlacePhoto extends ConsumerWidget {
  const PlacePhoto({
    super.key,
    required this.path,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  /// Путь из базы: `assets/photos/имя.jpg`.
  final String path;

  /// Что показать, если снимка нет ни в бандле, ни среди скачанных.
  final Widget fallback;

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = p.basename(path);
    final downloaded = ref.watch(downloadedPhotosProvider).valueOrNull;
    final dir = ref.watch(packsDirProvider).valueOrNull;

    if (downloaded != null && dir != null && downloaded.contains(name)) {
      return Image.file(
        File(p.join(dir.path, name)),
        width: width,
        height: height,
        fit: fit,
        // Файл мог быть удалён вместе с пакетом между кадрами — тогда
        // пробуем бандл, а не показываем пустоту.
        errorBuilder: (_, _, _) => _fromBundle(),
      );
    }
    return _fromBundle();
  }

  Widget _fromBundle() => Image.asset(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, _, _) => fallback,
  );
}
