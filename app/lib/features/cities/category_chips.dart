import 'package:flutter/material.dart';

import '../../core/categories.dart';

/// Полоса плашек категорий.
///
/// Одна реализация на обзор страны и на экран города: раньше эти списки
/// жили в двух местах и уже начали расходиться в подписях.
///
/// Показываются только категории, в которых есть хотя бы [minCount] мест.
/// Плашка, за которой стоит один объект, обещает раздел, а открывает одну
/// карточку.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.counts,
    required this.selected,
    required this.onChanged,
    this.minCount = 2,
  });

  /// Категория → сколько в ней мест.
  final Map<String, int> counts;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final int minCount;

  @override
  Widget build(BuildContext context) {
    final visible = orderedCategories({
      for (final e in counts.entries)
        if (e.value >= minCount) e.key: e.value,
    });

    if (visible.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          for (final id in visible)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(iconForCategory(id), size: 16),
                label: Text('${categoryLabel(id)} · ${counts[id]}'),
                selected: selected.contains(id),
                onSelected: (on) {
                  final next = Set<String>.from(selected);
                  on ? next.add(id) : next.remove(id);
                  onChanged(next);
                },
              ),
            ),
        ],
      ),
    );
  }
}
