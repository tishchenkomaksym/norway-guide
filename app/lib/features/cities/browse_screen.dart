import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
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
      appBar: AppBar(title: const Text('Куда поехать')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<BrowseTab>(
              segments: const [
                ButtonSegment(
                  value: BrowseTab.cities,
                  label: Text('Города'),
                  icon: Icon(Icons.location_city, size: 18),
                ),
                ButtonSegment(
                  value: BrowseTab.places,
                  label: Text('Места'),
                  icon: Icon(Icons.photo_camera, size: 18),
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
                ? const _Empty(text: 'По выбранным категориям ничего не нашлось')
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

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final p = _controller.position;
      if (p.pixels >= p.maxScrollExtent - p.viewportDimension / 2) {
        setState(() => _visible += 6);
      }
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
          return const _Empty(text: 'Городов в этой сборке данных нет');
        }
        final count = _visible.clamp(0, list.length);
        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisExtent: 168,
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
                  'Показано $count из ${list.length}',
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
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientFor(city.nameNo),
                ),
              ),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.location_city,
                  color: Colors.white.withValues(alpha: 0.9), size: 22),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.nameNo,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(city.population, item.notableCount),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.place, size: 14, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${item.placeCount} мест',
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

  static String _subtitle(int? population, int notable) {
    if (population != null && population > 0) {
      return '${_thousands(population)} жителей';
    }
    // У туристических посёлков население в OSM часто не проставлено —
    // писать «0 жителей» было бы неверно.
    return notable > 0 ? 'Небольшой посёлок' : 'Населённый пункт';
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

String _thousands(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
