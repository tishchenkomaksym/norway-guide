import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

/// Личная оценка места — пять звёзд в карточке.
///
/// Это оценка для себя, а не отзыв для других: она никуда не отправляется
/// и никем, кроме владельца телефона, не видна. На экране про это ничего
/// не написано намеренно — строка «никуда не отправляется» под каждой
/// кнопкой превращается в шум, который перестают читать. Человек и так
/// не ждёт, что его личная пометка уедет наружу; объяснять надо там, где
/// ожидание может быть другим.
///
/// Смысл — в дневнике поездки. Через полгода человек не вспомнит, какой
/// из четырёх фьордов был тем самым; звёзды вместе с заметкой отвечают
/// на этот вопрос. Вместе с отметкой «был здесь» это единственные данные
/// в приложении, которые нельзя восстановить ниоткуда.
///
/// Появляется только у места, добавленного в избранное: хранить оценку
/// негде, пока записи нет, а добавлять её молча при нажатии на звезду —
/// значит делать за человека то, о чём он не просил. Поэтому невыбранное
/// место показывает подсказку вместо звёзд.
class RatingRow extends ConsumerWidget {
  const RatingRow({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider).valueOrNull;

    if (favorites == null) return const SizedBox.shrink();

    final entry = favorites.where((f) => f.placeId == placeId).toList();
    if (entry.isEmpty) {
      // Места нет в избранном — звёзды хранить негде.
      return const SizedBox.shrink();
    }

    final rating = entry.first.rating;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rating > 0 ? l.ratingYours : l.ratingPrompt,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(),
                  iconSize: 30,
                  icon: Icon(
                    star <= rating ? Icons.star : Icons.star_border,
                    color: star <= rating
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  // Повторное нажатие на ту же звезду снимает оценку:
                  // иначе поставленную по ошибке пятёрку нечем убрать.
                  onPressed: () async {
                    final db = await ref.read(databaseProvider.future);
                    await db.setRating(placeId, star == rating ? 0 : star);
                  },
                ),
              if (rating > 0) ...[
                const SizedBox(width: 8),
                Text(
                  l.ratingVisited,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
