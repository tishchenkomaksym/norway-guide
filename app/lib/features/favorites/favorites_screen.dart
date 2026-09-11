import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/place_photo.dart';
import '../../core/categories.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../place/place_screen.dart';

/// Моя поездка: сохранённые места, отметки «был здесь» и личные заметки.
///
/// Это единственный экран, где данные создаёт сам человек. Всё остальное
/// приложение может пересобрать пайплайн, а заметку — никто.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritePlacesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(L.of(context).favoritesTitle)),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (list) {
          if (list.isEmpty) return const _Empty();

          final planned = list.where((f) => !f.visited).toList();
          final visited = list.where((f) => f.visited).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (planned.isNotEmpty) ...[
                _SectionHeader(
                  title: L.of(context).favoritesWant,
                  count: planned.length,
                ),
                for (final f in planned) _FavoriteTile(item: f),
              ],
              if (visited.isNotEmpty) ...[
                _SectionHeader(
                  title: L.of(context).favoritesVisited,
                  count: visited.length,
                ),
                for (final f in visited) _FavoriteTile(item: f),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.item});

  final FavoritePlace item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = item.place;
    final color = colorForCategory(place.place.category);

    return Dismissible(
      key: ValueKey(place.place.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) async {
        final db = await ref.read(databaseProvider.future);
        await db.removeFavorite(place.place.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L.of(context).removedFromTrip(place.name)),
              action: SnackBarAction(
                label: L.of(context).undo,
                // Заметку восстановить не получится — она удалена вместе
                // с записью. Возвращаем хотя бы само место.
                onPressed: () => db.toggleFavorite(place.place.id),
              ),
            ),
          );
        }
      },
      child: ListTile(
        leading: SizedBox(
          width: 52,
          height: 52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: place.hasPhoto
                ? PlacePhoto(
                    path: place.photoPath!,
                    fallback: _Fill(color: color, place: place),
                  )
                : _Fill(color: color, place: place),
          ),
        ),
        title: Text(
          place.name,
          style: TextStyle(
            decoration: item.visited ? TextDecoration.lineThrough : null,
            color: item.visited ? Theme.of(context).colorScheme.outline : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categorySingular(context, place.place.category),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            if (item.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 13,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: item.note != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.note == null ? Icons.note_add_outlined : Icons.edit_note,
                size: 20,
              ),
              tooltip: L.of(context).noteTooltip,
              onPressed: () => _editNote(context, ref, item),
            ),
            IconButton(
              icon: Icon(
                item.visited ? Icons.check_circle : Icons.check_circle_outline,
                size: 22,
                color: item.visited ? Colors.green : null,
              ),
              tooltip: item.visited
                  ? L.of(context).markNotVisited
                  : L.of(context).markVisited,
              onPressed: () async {
                final db = await ref.read(databaseProvider.future);
                await db.setVisited(place.place.id, !item.visited);
              },
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceScreen(placeId: place.place.id),
          ),
        ),
      ),
    );
  }
}

Future<void> _editNote(
  BuildContext context,
  WidgetRef ref,
  FavoritePlace item,
) async {
  final controller = TextEditingController(text: item.note ?? '');

  final result = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item.place.name),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: L.of(context).noteHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L.of(context).cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(L.of(context).save),
        ),
      ],
    ),
  );

  controller.dispose();
  if (result == null) return;

  final db = await ref.read(databaseProvider.future);
  await db.setNote(item.place.place.id, result);
}

class _Fill extends StatelessWidget {
  const _Fill({required this.color, required this.place});

  final Color color;
  final PlaceWithText place;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Icon(
        iconForCategory(place.place.category),
        size: 22,
        color: color,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 46, color: scheme.outlineVariant),
            const SizedBox(height: 14),
            Text(
              L.of(context).favoritesEmpty,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              L.of(context).favoritesEmptyDetail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
