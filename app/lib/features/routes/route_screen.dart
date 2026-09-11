// Route прячем: так называется и класс Flutter для навигации, и наша
// таблица маршрутов из drift. В этом файле речь всегда о втором,
// а MaterialPageRoute и Navigator работают и без импорта первого.
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/gpx.dart';
import '../../core/gpx_share.dart';
import '../../core/place_photo.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../place/place_screen.dart';

/// Пешая прогулка по городу.
///
/// Чем это не является: навигацией. Приложение не знает ни улиц, ни
/// переходов, ни расписаний — оно показывает порядок обхода и время
/// «на глаз». Проложить дорогу между точками по-прежнему предлагается
/// внешним картам, кнопкой в карточке места.
///
/// Числа приблизительные и подписаны как «около»: расстояние считается
/// по прямой с поправкой на извилистость улиц, время осмотра — по типу
/// места. Показывать «3 часа 47 минут» было бы точностью, которой
/// у нас нет.
class RouteScreen extends ConsumerWidget {
  const RouteScreen({super.key, required this.route, required this.cityName});

  final Route route;
  final String cityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final stops = ref.watch(routeStopsProvider(route.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.routeTitle(cityName)),
        actions: [
          // Экспорт доступен, только когда остановки уже прочитаны:
          // предлагать поделиться пустым файлом незачем.
          if (stops.valueOrNull?.isNotEmpty ?? false)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: l.gpxExport,
              onPressed: () => shareGpx(
                context,
                fileName: '$cityName.gpx',
                content: GpxBuilder.route(
                  name: l.routeTitle(cityName),
                  stops: stops.value!,
                  description: l.gpxDescription,
                ),
                subject: l.routeTitle(cityName),
              ),
            ),
        ],
      ),
      body: stops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('${l.loadError}:\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l.routeEmpty));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: list.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _Summary(route: route, stops: list.length);
              return _StopTile(
                item: list[i - 1],
                number: i,
                isLast: i == list.length,
              );
            },
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.route, required this.stops});

  final Route route;
  final int stops;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_walk,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                [
                  if (route.durationH != null)
                    l.routeAbout(route.durationH!.toStringAsFixed(1)),
                  if (route.distanceKm != null)
                    l.routeDistance(route.distanceKm!.toStringAsFixed(1)),
                  l.routeStops(stops),
                ].join(' · '),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.routeNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Одна остановка: номер, снимок, название, тип.
///
/// Вертикальная линия между номерами делает из списка именно
/// последовательность — без неё это просто ещё один список мест.
class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.item,
    required this.number,
    required this.isLast,
  });

  final PlaceWithText item;
  final int number;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaceScreen(placeId: item.place.id)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: item.hasPhoto
                            ? PlacePhoto(
                                path: item.photoPath!,
                                width: 56,
                                height: 56,
                                fallback: _Fill(item: item),
                              )
                            : _Fill(item: item),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            categorySingular(context, item.place.category),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        iconForCategory(item.place.category),
        size: 22,
        color: theme.colorScheme.outline,
      ),
    );
  }
}
