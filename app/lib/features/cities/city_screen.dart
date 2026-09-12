import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/place_sort.dart';
import '../../core/providers.dart';
import '../../core/usage_stats.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../routes/route_screen.dart';
import 'category_chips.dart';
import 'sort_button.dart';
import 'place_grid.dart';

/// Что посмотреть в городе.
///
/// Те же плашки категорий, что и в обзоре страны, но считаются по местам
/// этого города: в Осло десяток музеев и ни одного ледника, и плашка
/// «Ледники» там была бы обманом.
class CityScreen extends ConsumerStatefulWidget {
  const CityScreen({super.key, required this.city});

  final City city;

  @override
  ConsumerState<CityScreen> createState() => _CityScreenState();
}

class _CityScreenState extends ConsumerState<CityScreen> {
  Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(placesInCityProvider(widget.city.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city.nameNo),
        actions: const [SortButton()],
      ),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  L.of(context).noPlacesInCity,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final counts = <String, int>{};
          for (final p in all) {
            counts[p.place.category] = (counts[p.place.category] ?? 0) + 1;
          }

          // Фильтр учитывает только категории, которые в городе есть.
          // Иначе выбор, сделанный в другом городе, оставил бы пустой экран
          // без видимой причины.
          final effective = _selected.intersection(counts.keys.toSet());
          final filtered = effective.isEmpty
              ? all
              : all.where((p) => effective.contains(p.place.category)).toList();
          final shown = sortPlaces(filtered, ref.watch(placeSortProvider));

          return Column(
            children: [
              // Прогулка стоит выше списка мест и выше фильтров: человек,
              // открывший город, чаще всего спрашивает «что успею за
              // полдня», а не «покажи все музеи». Если маршрута для
              // города нет — полоса просто не появляется.
              _RouteBanner(city: widget.city),
              CategoryChips(
                counts: counts,
                selected: _selected,
                onChanged: (next) => setState(() => _selected = next),
              ),
              Expanded(child: PagedPlaceGrid(items: shown)),
            ],
          );
        },
      ),
    );
  }
}

/// Полоса «готовая прогулка» над списком мест.
///
/// Появляется только там, где маршрут действительно составлен: для этого
/// в городе нужно несколько мест в шаговой доступности от центра, а таких
/// городов меньше сорока. Показывать пустую кнопку «маршрут» в остальных
/// значило бы обещать то, чего нет.
class _RouteBanner extends ConsumerWidget {
  const _RouteBanner({required this.city});

  final City city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(cityRouteProvider(city.id)).valueOrNull;
    if (route == null) return const SizedBox.shrink();

    final l = L.of(context);
    final theme = Theme.of(context);
    final parts = [
      if (route.durationH != null)
        l.routeAbout(route.durationH!.toStringAsFixed(1)),
      if (route.distanceKm != null)
        l.routeDistance(route.distanceKm!.toStringAsFixed(1)),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            ref
                .read(usageStatsProvider.notifier)
                .record(UsageEvent.routeOpened);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RouteScreen(route: route, cityName: city.nameNo),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.routeBannerTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (parts.isNotEmpty)
                        Text(
                          parts,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
