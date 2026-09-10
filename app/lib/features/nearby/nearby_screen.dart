import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/categories.dart';
import '../../core/profile.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../cities/browse_screen.dart';
import '../cities/category_chips.dart';
import '../emergency/emergency_button.dart';
import '../favorites/favorites_screen.dart';
import '../place/place_screen.dart';
import '../profile/profile_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../rules/rules_screen.dart';
import '../search/search_screen.dart';
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
    if (gps.valueOrNull?.isOk ?? false) return;

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
    final hasPosition = mock != null || (position.valueOrNull?.isOk ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(mock == null
            ? L.of(context).nearbyScreenTitle
            : L.of(context).nearbyScreenTitleAt(mock.name)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: L.of(context).searchTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: L.of(context).favoritesTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          // Здесь кнопка нужнее всего: этот экран открывают в пути.
          const EmergencyButton(),
          IconButton(
            icon: const Icon(Icons.edit_location_alt),
            tooltip: L.of(context).setCityTooltip,
            onPressed: () => showLocationPicker(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: L.of(context).useGpsTooltip,
            onPressed: () {
              ref.read(mockPositionProvider.notifier).set(null);
              ref.invalidate(positionProvider);
              ref.invalidate(nearbyPlacesProvider);
            },
          ),
          const _ModeButton(),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: L.of(context).interestsTooltip,
            onPressed: () => showProfileSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasPosition) _NoLocationBanner(problem: position.valueOrNull?.problem),
          const _ModeHint(),
          const _CategoryFilter(),
          Expanded(
            child: places.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('${L.of(context).loadError}:\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const _NothingNearby();
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

/// Пустой список: рядом ничего нет.
///
/// В базу попадают только места с описанием или фотографией, поэтому
/// каталог — несколько тысяч точек на всю страну, а не десятки тысяч.
/// В глухих местах пустой экран — нормальный ответ, а не сбой, и он
/// обязан отличать две разные причины.
///
/// Раньше здесь стояла строка «ничего не найдено по фильтрам». Когда
/// фильтры не выбраны, она врёт: человек начинает их искать и снимать,
/// хотя снимать нечего. Поэтому текст зависит от того, что выбрано,
/// и всегда предлагает выход — сброс фильтров либо переход к городам.
class _NothingNearby extends ConsumerWidget {
  const _NothingNearby();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final selected = ref.watch(categoryFilterProvider);
    final filtered = selected.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.filter_alt_off_outlined : Icons.explore_off_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              filtered ? l.nothingInFilters : l.nothingNearby,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              filtered ? l.nothingInFiltersHint : l.nothingNearbyHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 18),
            if (filtered)
              FilledButton.tonal(
                onPressed: () =>
                    ref.read(categoryFilterProvider.notifier).state = {},
                child: Text(l.resetFilters),
              )
            else
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const BrowseScreen()),
                ),
                child: Text(l.browseTitle),
              ),
          ],
        ),
      ),
    );
  }
}

/// Переключатель режима — показывается, только если человек отметил
/// рыбалку или охоту. Кому эти режимы не нужны, лишней кнопки не увидит.
class _ModeButton extends ConsumerWidget {
  const _ModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableModesProvider);
    if (available.length < 2) return const SizedBox.shrink();

    final current = ref.watch(modeProvider);
    final l = L.of(context);

    String label(AppMode m) => switch (m) {
          AppMode.tourist => l.modeTourist,
          AppMode.fishing => l.modeFishing,
          AppMode.hunting => l.modeHunting,
        };

    return PopupMenuButton<AppMode>(
      icon: Icon(switch (current) {
        AppMode.fishing => Icons.set_meal,
        AppMode.hunting => Icons.forest,
        AppMode.tourist => Icons.explore_outlined,
      }),
      tooltip: l.modeSwitch,
      initialValue: current,
      onSelected: (m) => ref.read(modeProvider.notifier).set(m),
      itemBuilder: (context) => [
        for (final m in available)
          PopupMenuItem<AppMode>(
            value: m,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: m == current ? const Icon(Icons.check, size: 18) : null,
                ),
                Text(label(m)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Объяснение, почему список выглядит иначе обычного.
///
/// Без него человек решит, что приложение сломалось: города пропали,
/// а причина не названа.
class _ModeHint extends ConsumerWidget {
  const _ModeHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(modeProvider);
    if (mode == AppMode.tourist) return const SizedBox.shrink();

    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final activity = mode.activity;

    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            mode == AppMode.fishing ? Icons.set_meal : Icons.forest,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode == AppMode.fishing
                      ? l.modeFishingHint
                      : l.modeHuntingHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (activity != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: Text(l.modeRulesButton),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RulesScreen(activity: activity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Объяснение, почему местоположение не определилось, и что с этим делать.
///
/// Раньше здесь была одна фраза на все случаи. Человек с выключенной
/// геолокацией и человек в помещении без сигнала видели одно и то же
/// и одинаково не понимали, что чинить.
class _NoLocationBanner extends ConsumerWidget {
  const _NoLocationBanner({this.problem});

  final LocationProblem? problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    // Стиль создаётся здесь, а не в top-level переменной: та вычисляется
    // при загрузке библиотеки, до инициализации привязок Flutter, и роняет
    // тестовый изолят без внятного сообщения.
    final compact = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final (text, canOpenSettings) = switch (problem) {
      LocationProblem.serviceOff => (l.locServiceOff, true),
      LocationProblem.denied => (l.locDenied, false),
      LocationProblem.deniedForever => (l.locDeniedForever, true),
      LocationProblem.unavailable => (l.locUnavailable, false),
      null => (l.locationUnknown, false),
    };

    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_disabled, size: 18,
                    color: scheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Выбор города первым: он работает всегда, а разрешения
                // и настройки — только иногда.
                TextButton.icon(
                  style: compact,
                  icon: const Icon(Icons.edit_location_alt, size: 16),
                  label: Text(l.locSetCity),
                  onPressed: () => showLocationPicker(context, ref),
                ),
                TextButton.icon(
                  style: compact,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(l.locRetry),
                  onPressed: () {
                    ref.invalidate(positionProvider);
                    ref.invalidate(nearbyPlacesProvider);
                  },
                ),
                if (canOpenSettings)
                  TextButton.icon(
                    style: compact,
                    icon: const Icon(Icons.settings, size: 16),
                    label: Text(l.locOpenSettings),
                    onPressed: () => problem == LocationProblem.serviceOff
                        ? Geolocator.openLocationSettings()
                        : Geolocator.openAppSettings(),
                  ),
              ],
            ),
          ],
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
                L.of(context).otherLanguageShort,
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
