import 'package:flutter/material.dart';

import '../../core/categories.dart';

/// Полоса плашек категорий.
///
/// Одна реализация на обзор страны, экран города и «Рядом со мной»: раньше
/// эти списки жили в разных местах и уже начали расходиться в подписях.
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

    final anySelected = selected.isNotEmpty;

    return SizedBox(
      height: 62,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        children: [
          // Кнопка сброса появляется только когда есть что сбрасывать:
          // постоянная «Все» съедала бы место у самих категорий.
          if (anySelected)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ResetChip(onTap: () => onChanged({})),
            ),
          for (final id in visible)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                id: id,
                count: counts[id]!,
                selected: selected.contains(id),
                onTap: () {
                  final next = Set<String>.from(selected);
                  next.contains(id) ? next.remove(id) : next.add(id);
                  onChanged(next);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Плашка категории.
///
/// Выбранная заливается цветом категории, невыбранная остаётся светлой
/// с цветной иконкой. Так видно и то, что выбрано, и то, что это за
/// категория, — без чтения подписи.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.id,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorForCategory(id);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final background = selected
        ? color
        : (dark ? color.withValues(alpha: 0.16) : color.withValues(alpha: 0.10));
    final foreground = selected
        ? Colors.white
        : (dark ? color.withValues(alpha: 0.95) : _darken(color));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? color : color.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconForCategory(id), size: 17, color: foreground),
                const SizedBox(width: 7),
                Text(
                  categoryLabel(id),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                // Счётчик отдельной каплей, а не в тексте: число вида «· 30099»
                // сливалось с названием и мешало читать.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : scheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _compact(count),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetChip extends StatelessWidget {
  const _ResetChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 5),
              Text(
                'Сбросить',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Тридцать тысяч музеев в подписи выглядят как ошибка. Сокращаем.
String _compact(int n) {
  if (n >= 1000) {
    final k = n / 1000;
    return k >= 10 ? '${k.round()}к' : '${k.toStringAsFixed(1)}к';
  }
  return '$n';
}

/// Затемняет цвет для текста на светлой подложке: исходные оттенки
/// подобраны под заливку и на белом читаются плохо.
Color _darken(Color color) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
}
