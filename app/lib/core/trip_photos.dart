import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import 'providers.dart';

/// Собственные снимки человека — «моя поездка».
///
/// Что это и чем не является. Это личный дневник, а не социальная сеть:
/// снимки лежат на телефоне, никуда не отправляются и никому, кроме
/// владельца, не видны. Приложение лишь привязывает их к местам и в конце
/// собирает карту поездки, которой человек может поделиться — картинкой,
/// сам решая, публиковать её или нет.
///
/// Почему так, а не общий альбом. Общие фотографии означают сервер,
/// модерацию и ответственность за чужой контент — всё то, чего у проекта
/// принципиально нет. Добавить социальную часть поверх личного дневника
/// можно будет всегда, когда появятся люди, которым есть что показывать.
/// Обратно — уже нет: отобрать возможность, к которой привыкли, нельзя.

/// Куда складываются снимки.
///
/// В каталоге приложения, а не в общей галерее телефона. Снимок, сделанный
/// через приложение, и так попадает в галерею — системная камера кладёт
/// его туда сама. Здесь хранится копия, привязанная к поездке: она не
/// исчезнет, если человек почистит галерею, и не засорит её, если он
/// удалит поездку.
Future<Directory> tripPhotosDirectory() async {
  final dir = await getApplicationSupportDirectory();
  final photos = Directory(p.join(dir.path, 'trip'));
  if (!await photos.exists()) {
    await photos.create(recursive: true);
  }
  return photos;
}

/// Снять или выбрать фотографию и привязать её к поездке.
///
/// Координаты берутся из текущего положения, а если его нет — от места,
/// к которому снимок привязан. Без координат снимок тоже принимается:
/// фотография ужина в Бергене не обязана иметь точку на карте, чтобы
/// попасть в память о поездке.
class TripPhotoService {
  TripPhotoService(this._ref);

  final Ref _ref;
  final _picker = ImagePicker();

  Future<bool> add({
    required ImageSource source,
    String? placeId,
    double? placeLat,
    double? placeLon,
  }) async {
    // Снимки ужимаются при съёмке: телефоны делают кадры по 4–8 МБ,
    // а для карты поездки и просмотра на экране хватает вдвое меньшего
    // размера. Человек, снявший за поездку двести кадров, не должен
    // обнаружить, что приложение заняло гигабайт.
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return false;

    final dir = await tripPhotosDirectory();
    final name =
        'trip_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path)}';
    final saved = File(p.join(dir.path, name));
    await saved.writeAsBytes(await file.readAsBytes(), flush: true);

    final position = _ref.read(positionProvider).valueOrNull?.position;
    final db = await _ref.read(databaseProvider.future);

    await db.addTripPhoto(
      path: saved.path,
      takenAt: DateTime.now(),
      placeId: placeId,
      lat: position?.latitude ?? placeLat,
      lon: position?.longitude ?? placeLon,
    );

    _ref.invalidate(tripPhotosProvider);
    return true;
  }

  /// Удалить снимок вместе с файлом.
  ///
  /// Файл удаляется тоже: оставлять его на диске после того, как человек
  /// убрал снимок из поездки, — тихо занимать место без причины.
  Future<void> remove(TripPhoto photo) async {
    final db = await _ref.read(databaseProvider.future);
    await db.removeTripPhoto(photo.id);
    try {
      final file = File(photo.path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Файла уже нет или он недоступен — запись всё равно убрана.
    }
    _ref.invalidate(tripPhotosProvider);
  }
}

final tripPhotoServiceProvider = Provider(TripPhotoService.new);

/// Все снимки поездки, новые сверху.
final tripPhotosProvider = StreamProvider<List<TripPhoto>>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  yield* db.watchTripPhotos();
});

/// Снимки, привязанные к конкретному месту.
final placeTripPhotosProvider = FutureProvider.family<List<TripPhoto>, String>((
  ref,
  placeId,
) async {
  // Зависимость от общего списка нужна, чтобы карточка места
  // обновлялась сразу после съёмки.
  ref.watch(tripPhotosProvider);
  final db = await ref.watch(databaseProvider.future);
  return db.tripPhotosForPlace(placeId);
});

/// Места, где человек был: отмеченные как посещённые или со снимками.
final visitedPlacesProvider = FutureProvider<List<PlaceWithText>>((ref) async {
  ref.watch(tripPhotosProvider);
  ref.watch(favoritesProvider);
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  return db.visitedPlaces(lang);
});
