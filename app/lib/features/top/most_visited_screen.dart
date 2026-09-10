import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../place/place_screen.dart';

/// Экран «Самое посещаемое» — курируемый топ-20 достопримечательностей.
///
/// Зачем отдельный экран, если есть вкладка «Места». Та сортирует по
/// `importance`, то есть по полноте разметки в OSM, и отвечает на вопрос
/// «насколько объект известен». Человек, который первый раз едет в Норвегию,
/// спрашивает другое: «что здесь смотрят все». Ответ на этот вопрос из
/// разметки не выводится — Тролльтунга размечена одной точкой и по формальной
/// шкале проигрывает районной церкви, хотя к ней идут десятки тысяч человек.
///
/// Поэтому список задан руками в пайплайне (`internal/toplist`), а порядок
/// хранится в колонке `top_rank`. Он не переставляется от того, что кто-то
/// дополнил теги в OSM.
class MostVisitedScreen extends ConsumerWidget {
  const MostVisitedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final places = ref.watch(mostVisitedProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.mostVisitedTitle)),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('${l.loadError}:\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l.mostVisitedEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == 0) return const _Explanation();
              return _TopTile(item: list[i - 1]);
            },
          );
        },
      ),
    );
  }
}

/// Пояснение, откуда взялся порядок.
///
/// Список составлен руками, и это надо сказать прямо: иначе он выглядит как
/// вычисленный рейтинг, которому можно предъявить претензию за то, что
/// чей-то любимый фьорд оказался на пятнадцатом месте.
class _Explanation extends StatelessWidget {
  const _Explanation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Text(
        L.of(context).mostVisitedNote,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _TopTile extends StatelessWidget {
  const _TopTile({required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    final place = item.place;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaceScreen(placeId: place.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Номер в топе — то, ради чего человек сюда зашёл.
                      Text(
                        '${place.topRank}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(iconForCategory(place.category),
                          size: 13, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        categoryLabel(context, place.category),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (place.unesco == 1) ...[
                        const SizedBox(width: 8),
                        _Badge(text: l.unescoShort),
                      ],
                    ],
                  ),
                  if (item.summary != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.summary!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Цифра посещаемости показывается только вместе с годом:
                  // «300 000 человек» без года — это не факт, а впечатление.
                  // Ноль означает, что надёжного числа нет.
                  if (place.visitors > 0 && place.visitorsYear > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.visitorsPerYear(
                          place.visitors, '${place.visitorsYear}'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const size = 64.0;

    Widget fallback() => Container(
          width: size,
          height: size,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            iconForCategory(item.place.category),
            color: theme.colorScheme.outline,
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.hasPhoto
          ? Image.asset(
              item.photoPath!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback(),
            )
          : fallback(),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
