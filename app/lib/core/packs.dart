import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Региональные пакеты фотографий.
///
/// Зачем они есть. Снимки весят под сотню мегабайт — в бандле приложения
/// им не место: человек скачивает из стора сто мегабайт ради поездки по
/// одному фьорду. В бандле остаются только снимки топ-мест и городов,
/// остальное качается по кнопке перед поездкой (§5 спеки, уровень 3).
///
/// Чего здесь намеренно нет: автоматического скачивания и фоновых
/// обновлений. Приложение не тратит трафик без явного действия человека —
/// это решение записано в decisions.md и нарушать его нельзя. При выходе
/// новой версии пакета показывается пометка, и только.

/// Описание пакета из манифеста.
@immutable
class PackInfo {
  const PackInfo({
    required this.regionId,
    required this.nameNo,
    required this.nameEn,
    required this.packVersion,
    required this.file,
    required this.sizeBytes,
    required this.sha256,
    required this.photos,
    required this.places,
  });

  final String regionId;
  final String nameNo;
  final String nameEn;
  final int packVersion;
  final String file;
  final int sizeBytes;
  final String sha256;
  final int photos;
  final int places;

  factory PackInfo.fromJson(Map<String, dynamic> json) => PackInfo(
    regionId: json['region_id'] as String,
    nameNo: json['name_no'] as String? ?? '',
    nameEn: json['name_en'] as String? ?? '',
    packVersion: json['pack_version'] as int? ?? 1,
    file: json['file'] as String,
    sizeBytes: json['size_bytes'] as int? ?? 0,
    sha256: json['sha256'] as String? ?? '',
    photos: json['photos'] as int? ?? 0,
    places: json['places'] as int? ?? 0,
  );

  double get sizeMb => sizeBytes / (1024 * 1024);
}

/// Манифест: что вообще можно скачать.
@immutable
class PackManifest {
  const PackManifest({required this.builtAt, required this.packs});

  final String builtAt;
  final List<PackInfo> packs;

  factory PackManifest.fromJson(Map<String, dynamic> json) => PackManifest(
    builtAt: json['built_at'] as String? ?? '',
    packs: (json['packs'] as List<dynamic>? ?? [])
        .map((e) => PackInfo.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Состояние одного пакета на устройстве.
enum PackState {
  /// Не скачан.
  absent,

  /// Скачивается прямо сейчас.
  downloading,

  /// Скачан и распакован.
  installed,

  /// Скачан, но на сервере лежит версия новее. Приложение об этом
  /// сообщает и ничего не делает само.
  outdated,
}

@immutable
class PackStatus {
  const PackStatus({
    required this.info,
    required this.state,
    this.progress = 0,
    this.installedVersion,
    this.error,
  });

  final PackInfo info;
  final PackState state;

  /// 0..1 — доля скачанного. Нужна, чтобы показывать полосу: пакет
  /// на тридцать мегабайт по мобильной сети качается заметное время.
  final double progress;
  final int? installedVersion;
  final String? error;

  PackStatus copyWith({
    PackState? state,
    double? progress,
    int? installedVersion,
    String? error,
  }) => PackStatus(
    info: info,
    state: state ?? this.state,
    progress: progress ?? this.progress,
    installedVersion: installedVersion ?? this.installedVersion,
    error: error,
  );
}

/// Откуда качаются пакеты.
///
/// Пока это GitHub Releases: репозиторий публичный, ссылки прямые,
/// раздача идёт через тот же CDN, что и всё остальное на GitHub, и
/// платить не нужно вовсе. Для старта этого достаточно с запасом —
/// пакеты весят 85 МБ, а ограничений по трафику для публичных релизов
/// нет.
///
/// В документации проекта записан Cloudflare R2, и это по-прежнему
/// правильный ответ для нагрузки: у R2 нулевая плата за исходящий
/// трафик, тогда как у S3 она стала бы основной статьёй расходов при
/// росте. Переезд туда — это смена одной строки при сборке, поэтому
/// начинать с бесплатного GitHub разумнее, чем заводить бакет ради
/// проверки.
///
/// Адрес можно переопределить при сборке:
/// `flutter build apk --dart-define=PACKS_URL=https://...`
const packBaseUrl = String.fromEnvironment(
  'PACKS_URL',
  defaultValue:
      'https://github.com/tishchenkomaksym/norway-guide'
      '/releases/download/packs-v1',
);

/// Где лежит манифест.
///
/// Отдельно от [packBaseUrl], потому что манифест и пакеты не обязаны
/// лежать рядом: сейчас они выложены вложениями к описанию релиза
/// и получили несоседние адреса. Приложению это безразлично — оно
/// читает манифест, а дальше идёт по адресам, которые в нём записаны.
const manifestUrl = String.fromEnvironment(
  'MANIFEST_URL',
  defaultValue: 'https://raw.githubusercontent.com/tishchenkomaksym'
      '/norway-guide/main/packs/manifest.json',
);

/// Каталог, куда распаковываются снимки.
Future<Directory> packsDirectory() async {
  final dir = await getApplicationSupportDirectory();
  final packs = Directory(p.join(dir.path, 'packs'));
  if (!await packs.exists()) {
    await packs.create(recursive: true);
  }
  return packs;
}

/// Файл с отметками о скачанном: какой пакет какой версии установлен.
///
/// Отдельный json, а не база: сведения нужны до открытия базы — при
/// первом кадре экрана загрузок, — и терять их при обновлении контента
/// нельзя.
Future<File> _stateFile() async {
  final dir = await packsDirectory();
  return File(p.join(dir.path, 'installed.json'));
}

Future<Map<String, int>> readInstalled() async {
  try {
    final file = await _stateFile();
    if (!await file.exists()) return {};
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, v as int));
  } catch (_) {
    // Повреждённый файл не должен мешать работе: считаем, что ничего
    // не скачано, и человек скачает заново.
    return {};
  }
}

Future<void> _writeInstalled(Map<String, int> installed) async {
  final file = await _stateFile();
  await file.writeAsString(jsonEncode(installed), flush: true);
}

/// Скачивает и распаковывает пакет.
///
/// [onProgress] вызывается по мере загрузки — с долей от нуля до единицы.
///
/// Контрольная сумма проверяется до распаковки: оборвавшийся файл внешне
/// неотличим от целого, а распаковать мусор в папку со снимками — значит
/// получить битые картинки без единого сообщения об ошибке.
Future<void> downloadPack(
  PackInfo info, {
  void Function(double progress)? onProgress,
  http.Client? client,
}) async {
  final own = client == null;
  final http.Client c = client ?? http.Client();
  try {
    // Адрес файла может быть как именем («east.zip»), так и полной
    // ссылкой. Второе нужно, когда раздача лежит не одной папкой:
    // например, файлы выложены вложениями с разными адресами. Так же
    // это позволит перевезти раздачу на другой хост, поменяв только
    // манифест, без пересборки приложения.
    final url = info.file.startsWith('http')
        ? Uri.parse(info.file)
        : Uri.parse('$packBaseUrl/${info.file}');
    final request = http.Request('GET', url);
    final response = await c.send(request);

    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }

    final dir = await packsDirectory();
    final tmp = File(p.join(dir.path, '${info.regionId}.part'));
    final sink = tmp.openWrite();

    final total = response.contentLength ?? info.sizeBytes;
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.close();
    }

    if (info.sha256.isNotEmpty) {
      final digest = await _sha256OfFile(tmp);
      if (digest != info.sha256) {
        await tmp.delete();
        throw const FormatException(
          'контрольная сумма не совпала — файл скачался повреждённым',
        );
      }
    }

    await _extract(tmp, dir);
    await tmp.delete();

    final installed = await readInstalled();
    installed[info.regionId] = info.packVersion;
    await _writeInstalled(installed);
  } finally {
    if (own) c.close();
  }
}

/// Удаляет скачанный пакет.
///
/// Удаляются только файлы, перечисленные в самом архиве… которого уже нет,
/// поэтому идём от обратного: список снимков пакета приложение не хранит,
/// а хранить его отдельно — лишняя сущность. Вместо этого файлы помечаются
/// принадлежностью к региону через отдельный список при распаковке.
Future<void> removePack(String regionId) async {
  final dir = await packsDirectory();
  final index = File(p.join(dir.path, '$regionId.files'));
  if (await index.exists()) {
    for (final name in await index.readAsLines()) {
      if (name.trim().isEmpty) continue;
      final f = File(p.join(dir.path, name.trim()));
      if (await f.exists()) await f.delete();
    }
    await index.delete();
  }
  final installed = await readInstalled();
  installed.remove(regionId);
  await _writeInstalled(installed);
}

Future<String> _sha256OfFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

/// Распаковывает архив в каталог и запоминает список файлов.
///
/// Список нужен, чтобы потом удалить ровно то, что принёс этот пакет:
/// каталог общий на все регионы, и снести его целиком значит стереть
/// чужие снимки.
Future<void> _extract(File archiveFile, Directory dir) async {
  final regionId = p.basenameWithoutExtension(archiveFile.path);
  final bytes = await archiveFile.readAsBytes();
  final archive = _decodeZip(bytes);

  final names = <String>[];
  for (final entry in archive) {
    if (!entry.isFile) continue;
    final name = p.basename(entry.name);
    final out = File(p.join(dir.path, name));
    await out.writeAsBytes(entry.content, flush: false);
    names.add(name);
  }

  final index = File(p.join(dir.path, '$regionId.files'));
  await index.writeAsString(names.join('\n'), flush: true);
}

List<ArchiveFile> _decodeZip(Uint8List bytes) =>
    ZipDecoder().decodeBytes(bytes).files;

/// Манифест с сервера.
///
/// Без сети возвращает то, что знает о скачанном: экран загрузок обязан
/// открываться офлайн и показывать, что уже лежит на устройстве.
final packManifestProvider = FutureProvider<PackManifest?>((ref) async {
  try {
    final response = await http
        .get(Uri.parse(manifestUrl))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return null;
    return PackManifest.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  } catch (_) {
    // Нет сети или сервер недоступен — это не ошибка приложения.
    return null;
  }
});

/// Что уже установлено: регион → версия пакета.
final installedPacksProvider = FutureProvider<Map<String, int>>((ref) async {
  return readInstalled();
});

/// Имена скачанных файлов снимков — чтобы отличать их от лежащих в бандле.
///
/// Читается один раз при старте и обновляется после установки пакета:
/// проверять существование файла на каждый кадр списка нельзя, это
/// обращение к диску на каждую карточку при прокрутке.
final downloadedPhotosProvider = FutureProvider<Set<String>>((ref) async {
  final dir = await packsDirectory();
  if (!await dir.exists()) return {};
  final names = <String>{};
  await for (final entry in dir.list()) {
    if (entry is File) {
      final name = p.basename(entry.path);
      if (name.endsWith('.jpg') ||
          name.endsWith('.png') ||
          name.endsWith('.webp')) {
        names.add(name);
      }
    }
  }
  return names;
});

/// Каталог со скачанными снимками — нужен, чтобы построить путь к файлу.
final packsDirProvider = FutureProvider<Directory>((ref) => packsDirectory());
