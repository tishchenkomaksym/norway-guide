import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import 'category_chips.dart';
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
      appBar: AppBar(title: Text(widget.city.nameNo)),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Для этого города мест пока нет',
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
          final shown = effective.isEmpty
              ? all
              : all
                  .where((p) => effective.contains(p.place.category))
                  .toList();

          return Column(
            children: [
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
