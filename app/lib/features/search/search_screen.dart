import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/place_photo.dart';
import '../../core/categories.dart';
import '../../core/profile.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';
import '../place/place_screen.dart';

/// Поиск по местам.
///
/// Ищет по 66 тысячам объектов через FTS5, поэтому запрос не отправляется
/// на каждую букву: задержка в 250 мс убирает промежуточные состояния вроде
/// «б», «бе», «бер», каждое из которых стоит полного прохода по индексу.
///
/// Ищем сразу по языку пользователя, норвежскому и английскому: человек
/// набирает то, что видит на указателе, а на указателе норвежское название.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider).trim();

    final l = L.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      _debounce?.cancel();
                      ref.read(searchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                  ),
          ),
          onChanged: (v) {
            _onChanged(v);
            setState(() {}); // чтобы появилась и пропала кнопка очистки
          },
        ),
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('${l.searchError}:\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (query.length < 2) return const _Hint();
          if (list.isEmpty) return _Nothing(query: query);

          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) => _ResultTile(item: list[i]),
          );
        },
      ),
    );
  }
}

class _ResultTile extends ConsumerWidget {
  const _ResultTile({required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ratingStars(item.place.importance);
    final color = colorForCategory(item.place.category);

    return ListTile(
      leading: SizedBox(
        width: 52,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.hasPhoto
              ? PlacePhoto(
                  path: item.photoPath!,
                  fallback: _Fill(color: color, item: item),
                )
              : _Fill(color: color, item: item),
        ),
      ),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                categorySingular(context, item.place.category),
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
              if (stars != null) ...[
                const SizedBox(width: 6),
                for (var i = 0; i < stars; i++)
                  Icon(Icons.star, size: 10, color: color),
              ],
            ],
          ),
          if (item.summary != null)
            Text(item.summary!, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: item.summary != null,
      onTap: () {
        ref.read(placeViewCountProvider.notifier).state++;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceScreen(placeId: item.place.id),
          ),
        );
      },
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({required this.color, required this.item});

  final Color color;
  final PlaceWithText item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Icon(iconForCategory(item.place.category), size: 22, color: color),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 44, color: scheme.outlineVariant),
            const SizedBox(height: 14),
            Text(
              L.of(context).searchPrompt,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              L.of(context).searchPromptDetail,
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

class _Nothing extends StatelessWidget {
  const _Nothing({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L.of(context).searchNothing(query),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              L.of(context).searchNothingDetail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
