import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/profile.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../cities/category_chips.dart';
import '../emergency/emergency_button.dart';
import '../place/place_screen.dart';
import '../profile/profile_sheet.dart';
import 'location_picker.dart';

/// Главный экран: что интересного рядом.
///
/// Заменяет интерактивную карту в MVP. Работает полностью офлайн — GPS не
/// требует сети, координаты лежат в локальной базе.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  bool _askedOnce = false;

  /// Спрашиваем город один раз при старте, если положение так и не
  /// определилось. Повторно не пристаём — менять его можно кнопкой в шапке.
  void _askLocationIfNeeded() {
    if (_askedOnce) return;
    final gps = ref.read(positionProvider);
    if (gps.isLoading) return;
    if (ref.read(mockPositionProvider) != null) return;
    if (gps.valueOrNull != null) return;

    _askedOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLocationPicker(context, ref);
    });
  }

  /// Спрашиваем про интересы, когда человек уже полистал приложение.
  void _askProfileIfReady() {
    if (!ref.read(shouldAskProfileProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showProfileSheet(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    _askLocationIfNeeded();
    ref.listen(shouldAskProfileProvider, (_, should) {
      if (should) _askProfileIfReady();
    });
    final places = ref.watch(nearbyPlacesProvider);
    final position = ref.watch(positionProvider);
    final mock = ref.watch(mockPositionProvider);
    final hasPosition = mock != null || position.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(mock == null ? 'Рядом со мной' : 'Рядом: ${mock.name}'),
        actions: [
          // Здесь кнопка нужнее всего: этот экран открывают в пути.
          const EmergencyButton(),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            tooltip: 'Указать город',
            onPressed: () => showLocationPicker(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Определить по GPS',
            onPressed: () {
              ref.read(mockPositionProvider.notifier).state = null;
              ref.invalidate(positionProvider);
              ref.invalidate(nearbyPlacesProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Мои интересы',
            onPressed: () => showProfileSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasPosition) const _NoLocationBanner(),
          const _CategoryFilter(),
          Expanded(
            child: places.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Не удалось загрузить места:\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('Ничего не найдено по выбранным фильтрам'),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _PlaceTile(item: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLocationBanner extends ConsumerWidget {
  const _NoLocationBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () => showLocationPicker(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.edit_location_alt, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Положение неизвестно. Нажмите, чтобы указать город',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryFilterProvider);
    final counts = ref.watch(nearbyCategoryCountsProvider).valueOrNull;

    // Пока категории не посчитаны, не мигаем полным набором кнопок.
    if (counts == null) return const SizedBox(height: 52);

    // minCount 1: рядом с человеком единственный водопад — это повод
    // показать плашку, а не спрятать её. Порог в два объекта уместен
    // в обзоре страны, но не здесь.
    return CategoryChips(
      counts: counts,
      selected: selected,
      minCount: 1,
      onChanged: (next) =>
          ref.read(categoryFilterProvider.notifier).state = next,
    );
  }
}

class _PlaceTile extends ConsumerWidget {
  const _PlaceTile({required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distance = item.distanceMeters;

    return ListTile(
      leading: CircleAvatar(
        child: Icon(iconForCategory(item.place.category), size: 20),
      ),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.summary != null)
            Text(
              item.summary!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (item.isFallback)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Описание доступно только на другом языке',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
        ],
      ),
      trailing: distance == null
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatDistance(distance)),
                if (item.bearingDeg != null)
                  Text(
                    compassLabel(item.bearingDeg!),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
      onTap: () {
        // Счётчик просмотров — сигнал заинтересованности, по которому позже
        // задаётся вопрос об интересах.
        ref.read(placeViewCountProvider.notifier).state++;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceScreen(placeId: item.place.id),
          ),
        );
      },
    );
  }
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} м';
  if (meters < 10000) return '${(meters / 1000).toStringAsFixed(1)} км';
  return '${(meters / 1000).round()} км';
}

const _compassPoints = [
  'С', 'СВ', 'В', 'ЮВ', 'Ю', 'ЮЗ', 'З', 'СЗ',
];

String compassLabel(double bearing) {
  final index = ((bearing + 22.5) % 360 ~/ 45).clamp(0, 7);
  return _compassPoints[index];
}
