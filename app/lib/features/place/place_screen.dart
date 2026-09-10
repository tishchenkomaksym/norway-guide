import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/categories.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../cities/place_grid.dart' show gradientFor;

/// Карточка места.
///
/// Текст показывается на том языке, который вообще нашёлся: цепочка
/// подстановки §8.4 отдаёт язык пользователя, иначе английский, иначе
/// норвежский. Переводы будут позже, а пока показать текст на чужом языке
/// честнее, чем не показать ничего — человек хотя бы поймёт, что это
/// за место, а имена собственные и цифры читаются на любом языке.
class PlaceScreen extends ConsumerWidget {
  const PlaceScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeProvider(placeId));
    final favorites = ref.watch(favoritesProvider);
    final isFavorite =
        favorites.valueOrNull?.any((f) => f.placeId == placeId) ?? false;

    return Scaffold(
      body: place.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Место не найдено'));
          }
          return CustomScrollView(
            slivers: [
              _Header(item: item, isFavorite: isFavorite),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                sliver: SliverList.list(
                  children: [
                    if (item.isFallback && item.summary != null)
                      const _LanguageNote(),
                    if (item.summary != null)
                      SelectableText(
                        item.summary!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                            ),
                      )
                    else
                      _NoText(category: item.place.category),
                    const SizedBox(height: 22),
                    _Facts(place: item.place),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Проложить маршрут'),
                      onPressed: () => _openExternalMap(
                        context,
                        item.place.lat,
                        item.place.lon,
                        item.name,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 14),
                        const SizedBox(width: 6),
                        SelectableText(
                          '${item.place.lat.toStringAsFixed(5)}, '
                          '${item.place.lon.toStringAsFixed(5)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.item, required this.isFavorite});

  final PlaceWithText item;
  final bool isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ratingStars(item.place.importance);

    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
          onPressed: () async {
            final db = await ref.read(databaseProvider.future);
            await db.toggleFavorite(item.place.id);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(52, 0, 52, 14),
        title: Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Фото с Commons, если оно есть. У части мест снимка нет
            // и не будет — тогда заливка цветом категории.
            if (item.hasPhoto)
              Image.asset(
                item.photoPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _CategoryFill(item: item),
              )
            else
              _CategoryFill(item: item),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x99000000)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 44,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      categorySingular(item.place.category),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12.5),
                    ),
                  ),
                  if (stars != null) ...[
                    const SizedBox(width: 8),
                    for (var i = 0; i < stars; i++)
                      const Icon(Icons.star, size: 14, color: Colors.white),
                  ],
                ],
              ),
            ),

            // Атрибуция прямо на снимке: требование CC BY-SA, и прятать её
            // в отдельный экран для конкретного фото было бы неправильно.
            if (item.hasPhoto)
              Positioned(
                right: 10,
                bottom: 46,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.photoAuthor} · ${item.photoLicense}',
                    style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFill extends StatelessWidget {
  const _CategoryFill({required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientFor(item.place.category),
            ),
          ),
        ),
        Center(
          child: Icon(
            iconForCategory(item.place.category),
            size: 64,
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
      ],
    );
  }
}

/// Пометка, что текст не на языке интерфейса.
///
/// Честная и негромкая: скрыть подмену языка было бы хуже — человек решил бы,
/// что приложение сломалось.
class _LanguageNote extends StatelessWidget {
  const _LanguageNote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.translate, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Перевода пока нет — текст на языке источника',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoText extends StatelessWidget {
  const _NoText({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.notes_outlined, size: 18, color: scheme.outline),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Описания для этого места пока нет. Координаты и маршрут '
            'работают — можно доехать и посмотреть самому.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: scheme.outline, height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String?)>[
      (Icons.schedule, 'Часы работы', place.openingHours),
      (Icons.payments_outlined, 'Вход', place.entranceFee),
      (Icons.trending_up, 'Сложность', place.difficulty),
      (
        Icons.timer_outlined,
        'Время',
        place.durationMin == null ? null : '${place.durationMin} мин'
      ),
      (Icons.calendar_month, 'Сезон', place.season),
      (Icons.link, 'Сайт', place.website),
    ];

    final visible = rows.where((r) => r.$3 != null && r.$3!.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (icon, label, value) in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 17,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    value!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Открывает координаты во внешнем картографическом приложении.
///
/// Требует интернета — честно говорим об этом, если открыть не удалось.
/// Координаты при этом остаются на экране и их можно скопировать.
Future<void> _openExternalMap(
  BuildContext context,
  double lat,
  double lon,
  String label,
) async {
  final encoded = Uri.encodeComponent(label);
  final uris = [
    Uri.parse('geo:$lat,$lon?q=$lat,$lon($encoded)'),
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon'),
  ];

  for (final uri in uris) {
    if (await canLaunchUrl(uri)) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    }
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть карты. Нужен интернет.')),
    );
  }
}
