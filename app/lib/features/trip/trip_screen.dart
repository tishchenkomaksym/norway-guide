import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/trip_photos.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import 'trip_map.dart';

/// «Моя поездка по Норвегии».
///
/// Собирает воедино то, что человек сделал сам: места, где он побывал,
/// и снимки, которые он снял. Всё лежит на телефоне и никуда не уходит —
/// пока он сам не решит поделиться картинкой.
///
/// Карта здесь не интерактивная и не должна ею быть. Это открытка: контур
/// страны, точки поездки, несколько фотографий и число мест. Её задача —
/// выглядеть так, чтобы захотелось показать, а не позволять разглядывать
/// детали.
class TripScreen extends ConsumerStatefulWidget {
  const TripScreen({super.key});

  @override
  ConsumerState<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends ConsumerState<TripScreen> {
  /// Ключ области, которую превращаем в картинку при отправке.
  final _cardKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final photos = ref.watch(tripPhotosProvider).valueOrNull ?? const [];
    final visited = ref.watch(visitedPlacesProvider).valueOrNull ?? const [];

    final isEmpty = photos.isEmpty && visited.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tripTitle),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: _sharing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              tooltip: l.tripShare,
              onPressed: _sharing ? null : _shareCard,
            ),
        ],
      ),
      body: isEmpty
          ? _Empty(onAdd: _addPhoto)
          : ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: [
                // То, что уйдёт картинкой. Ключ стоит здесь, а не на всём
                // экране: в открытку не должны попасть кнопки и списки.
                RepaintBoundary(
                  key: _cardKey,
                  child: _TripCard(photos: photos, visited: visited),
                ),
                if (photos.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      l.tripPhotos(photos.length),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  _PhotoGrid(photos: photos),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPhoto,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(l.tripAddPhoto),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final l = L.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.tripTakePhoto),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.tripFromGallery),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    // Messenger берётся до асинхронного вызова: после него context может
    // уже не жить, а показывать сообщение через мёртвый контекст —
    // верный способ получить исключение вместо сообщения об ошибке.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(tripPhotoServiceProvider).add(source: source);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.tripPhotoFailed)));
    }
  }

  /// Превращает открытку в картинку и отдаёт системному листу «Поделиться».
  ///
  /// Снимается втрое крупнее экрана: картинка, сохранённая в разрешении
  /// телефона, в ленте выглядит мыльной, а лишний вес здесь ничего
  /// не стоит — файл живёт секунды.
  Future<void> _shareCard() async {
    setState(() => _sharing = true);
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('нет данных изображения');

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'norway-trip.png'));
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], subject: l.tripTitle);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.tripShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

/// Сама открытка: карта, числа и несколько снимков.
class _TripCard extends ConsumerWidget {
  const _TripCard({required this.photos, required this.visited});

  final List<TripPhoto> photos;
  final List<PlaceWithText> visited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);

    // Открытка рисуется в тёмных тонах независимо от темы приложения:
    // так она одинаково выглядит у всех и не зависит от того, была ли
    // включена ночная тема в момент отправки.
    const background = Color(0xFF0B1B2B);
    const land = Color(0xFF16324A);
    const border = Color(0xFF2E5A7D);
    const accent = Color(0xFF4FC3F7);
    const photoAccent = Color(0xFFFFB74D);

    final points = <TripPoint>[
      for (final place in visited)
        TripPoint(
          lat: place.place.lat,
          lon: place.place.lon,
          label: place.name,
          hasPhoto: photos.any((ph) => ph.placeId == place.place.id),
        ),
      // Снимки без привязки к месту, но с координатами, тоже на карте:
      // это могла быть стоянка у фьорда, которой нет в каталоге.
      for (final photo in photos)
        if (photo.placeId == null && photo.lat != null && photo.lon != null)
          TripPoint(lat: photo.lat!, lon: photo.lon!, hasPhoto: true),
    ];

    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tripCardTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),

          // Карта и снимки рядом: карта показывает, где человек был,
          // снимки — что он там видел. По отдельности ни то, ни другое
          // не выглядит историей.
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: FutureBuilder<NorwayShape>(
                    future: NorwayShape.load(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return CustomPaint(
                        painter: TripMapPainter(
                          shape: snapshot.data!,
                          points: points,
                          landColor: land,
                          borderColor: border,
                          pointColor: accent,
                          photoPointColor: photoAccent,
                          backgroundColor: background,
                        ),
                      );
                    },
                  ),
                ),
                if (photos.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _PhotoStrip(photos: photos)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '${visited.length}', label: l.tripPlacesVisited),
              const SizedBox(width: 24),
              _Stat(value: '${photos.length}', label: l.tripPhotosTaken),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Norway Explore',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Три последних снимка столбиком рядом с картой.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});

  final List<TripPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final shown = photos.take(3).toList();
    return Column(
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(shown[i].path),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFF16324A)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Все снимки поездки сеткой.
class _PhotoGrid extends ConsumerWidget {
  const _PhotoGrid({required this.photos});

  final List<TripPhoto> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, i) {
        final photo = photos[i];
        return GestureDetector(
          onLongPress: () => _confirmRemove(context, ref, photo),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    TripPhoto photo,
  ) async {
    final l = L.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.tripPhotoRemove),
        content: Text(l.tripPhotoRemoveDetail),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.exportSheetCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.downloadsRemove),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tripPhotoServiceProvider).remove(photo);
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              l.tripEmptyTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.tripEmptyDetail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Кнопка в центре, а не только плавающая в углу: на пустом
            // экране человек смотрит туда, где текст.
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(l.tripAddPhoto),
            ),
          ],
        ),
      ),
    );
  }
}
