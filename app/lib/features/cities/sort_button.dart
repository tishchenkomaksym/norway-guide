import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/place_sort.dart';
import '../../l10n/app_localizations.dart';

/// Переключатель порядка списка мест.
///
/// Кнопка в шапке, а не панель над списком: сортировку меняют редко,
/// а место на экране в списке карточек дорого.
///
/// Порядок «по расстоянию» показывается только там, где расстояние
/// действительно посчитано — на экране «Рядом со мной». В городе и обзоре
/// страны его нет, и предлагать сортировку, которая ничего не изменит,
/// значит обманывать ожидание.
class SortButton extends ConsumerWidget {
  const SortButton({super.key, this.withDistance = false});

  final bool withDistance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final current = ref.watch(placeSortProvider);

    String label(PlaceSort sort) => switch (sort) {
      PlaceSort.rating => l.sortByRating,
      PlaceSort.distance => l.sortByDistance,
      PlaceSort.name => l.sortByName,
    };

    return PopupMenuButton<PlaceSort>(
      icon: const Icon(Icons.sort),
      tooltip: l.sortTooltip,
      initialValue: current,
      onSelected: (value) => ref.read(placeSortProvider.notifier).state = value,
      itemBuilder: (context) => [
        for (final sort in PlaceSort.values)
          if (sort != PlaceSort.distance || withDistance)
            PopupMenuItem(
              value: sort,
              child: Row(
                children: [
                  Icon(switch (sort) {
                    PlaceSort.rating => Icons.star_outline,
                    PlaceSort.distance => Icons.near_me_outlined,
                    PlaceSort.name => Icons.sort_by_alpha,
                  }, size: 18),
                  const SizedBox(width: 12),
                  Text(label(sort)),
                ],
              ),
            ),
      ],
    );
  }
}
