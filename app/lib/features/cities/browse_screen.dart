import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../search/search_screen.dart';
import 'category_chips.dart';
import 'city_screen.dart';
import 'place_grid.dart';

/// Обзор страны: города и достопримечательности карточками.
///
/// Карточки, а не списки: человек выбирает, куда поехать, и список строк
/// для этого плохо годится. Карточка держит название, описание и признаки
/// места в одном блоке.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, this.initialTab = BrowseTab.cities});

  final BrowseTab initialTab;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

enum BrowseTab { cities, places }

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  late BrowseTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L.of(context).browseTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: L.of(context).searchTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<BrowseTab>(
              segments: [
                ButtonSegment(
                  value: BrowseTab.cities,
                  label: Text(L.of(context).tabCities),
                  icon: const Icon(Icons.location_city, size: 18),
                ),
                ButtonSegment(
                  value: BrowseTab.places,
                  label: Text(L.of(context).tabPlaces),
                  icon: const Icon(Icons.photo_camera, size: 18),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          Expanded(
            child: _tab == BrowseTab.cities
                ? const _CitiesGrid()
                : const _PlacesTab(),
          ),
        ],
      ),
    );
  }
}

class _PlacesTab extends ConsumerWidget {
  const _PlacesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(topCategoriesProvider).valueOrNull;
    final selected = ref.watch(topCategoryFilterProvider);
    final places = ref.watch(topPlacesProvider);

    return Column(
      children: [
        if (counts != null)
          CategoryChips(
            counts: counts,
            selected: selected,
            onChanged: (next) =>
                ref.read(topCategoryFilterProvider.notifier).state = next,
          )
        else
          const SizedBox(height: 52),
        Expanded(
          child: places.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
            data: (list) => list.isEmpty
                ? _Empty(text: L.of(context).nothingInCategories)
                : PagedPlaceGrid(items: list),
          ),
        ),
      ],
    );
  }
}

class _CitiesGrid extends ConsumerStatefulWidget {
  const _CitiesGrid();

  @override
  ConsumerState<_CitiesGrid> createState() => _CitiesGridState();
}

class _CitiesGridState extends ConsumerState<_CitiesGrid> {
  final _controller = ScrollController();
  int _visible = 6;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_visible >= _total) return;
      final p = _controller.position;
      if (p.pixels >= p.maxScrollExtent - p.viewportDimension / 2) {
        setState(() => _visible += 6);
      }
    });
  }

  /// Шесть карточек на широком экране помещаются целиком, прокручивать
  /// нечего — и подгрузка не начнётся. Досыпаем, пока не появится прокрутка.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_visible >= _total) return;
      if (_controller.position.maxScrollExtent > 0) return;
      setState(() => _visible += 6);
      _fillViewport();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(cityCardsProvider);

    return cities.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (list) {
        if (list.isEmpty) {
          return _Empty(text: L.of(context).noCities);
        }
        _total = list.length;
        _fillViewport();
        final count = _visible.clamp(0, list.length);
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 180,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: count,
                itemBuilder: (context, i) => _CityCardTile(item: list[i]),
              ),
            ),
            if (count < list.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  L.of(context).shownOf(count, list.length),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CityCardTile extends StatelessWidget {
  const _CityCardTile({required this.item});

  final CityCard item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final city = item.city;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CityScreen(city: city)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Фотография города, если она есть. Заливка — запасной вариант:
            // у большинства мелких посёлков снимка в Commons нет.
            SizedBox(
              height: 96,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.hasPhoto)
                    Image.asset(
                      item.photoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _CityFill(name: city.nameNo),
                    )
                  else
                    _CityFill(name: city.nameNo),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x8C000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 8,
                    child: Text(
                      city.nameNo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(blurRadius: 4, color: Color(0xB3000000)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subtitle(context, city.population, item.notableCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          L.of(context).placesCount(item.placeCount),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        if (item.notableCount > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.star, size: 13, color: scheme.tertiary),
                          const SizedBox(width: 3),
                          Text(
                            '${item.notableCount}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Размер города словами, а не числом жителей.
  ///
  /// Точное население показывать нельзя: в OSM у норвежских городов стоит
  /// население *tettsted* — сплошной городской застройки, которая переходит
  /// границы коммун. У Осло там 1,1 млн, хотя в самой коммуне около 717 тыс.
  /// Для гида это и не нужно: человеку важно, крупный это город или посёлок,
  /// а не цифра из статистического бюллетеня.
  static String _subtitle(BuildContext context, int? population, int notable) {
    final l = L.of(context);
    final pop = population ?? 0;
    if (pop >= 100000) return l.cityLarge;
    if (pop >= 20000) return l.cityMedium;
    if (pop >= 5000) return l.citySmall;
    if (pop >= 1000) return l.cityVillage;
    if (pop > 0) return l.cityHamlet;
    // У туристических мест население в OSM часто не проставлено вовсе —
    // писать «0 жителей» было бы неверно.
    return notable > 0 ? l.cityTourist : l.cityGeneric;
  }
}

/// Заливка вместо фотографии города.
class _CityFill extends StatelessWidget {
  const _CityFill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientForName(name),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.location_city,
          size: 30,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

