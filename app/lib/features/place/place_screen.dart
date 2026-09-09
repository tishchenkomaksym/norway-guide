import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';

/// Карточка места.
///
/// Навигацию отдаём внешним картам (`geo:` на Android, `maps://` на iOS) —
/// своей маршрутизации у приложения нет и не планируется.
class PlaceScreen extends ConsumerWidget {
  const PlaceScreen({super.key, required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(placeProvider(placeId));
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.valueOrNull
            ?.any((f) => f.placeId == placeId) ??
        false;

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
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: () async {
                      final db = await ref.read(databaseProvider.future);
                      await db.toggleFavorite(placeId);
                    },
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.list(
                  children: [
                    if (item.isFallback)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Описание пока доступно только на другом языке',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    if (item.summary != null) Text(item.summary!),
                    const SizedBox(height: 16),
                    _Facts(item: item),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 8),
                    Text(
                      '${item.place.lat.toStringAsFixed(5)}, '
                      '${item.place.lon.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall,
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

class _Facts extends StatelessWidget {
  const _Facts({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final place = item.place;
    final rows = <(String, String?)>[
      ('Категория', place.category as String?),
      ('Сложность', place.difficulty as String?),
      (
        'Время',
        place.durationMin == null ? null : '${place.durationMin} мин'
      ),
      ('Сезон', place.season as String?),
      ('Часы работы', place.openingHours as String?),
      ('Вход', place.entranceFee as String?),
    ];

    final visible = rows.where((r) => r.$2 != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, value) in visible)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Expanded(child: Text(value!)),
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
/// Координаты при этом остаются на экране и их можно переписать вручную.
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
      const SnackBar(
        content: Text('Не удалось открыть карты. Нужен интернет.'),
      ),
    );
  }
}
