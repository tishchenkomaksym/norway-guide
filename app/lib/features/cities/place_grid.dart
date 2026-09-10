import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/categories.dart';
import '../../core/profile.dart';
import '../../data/database.dart';
import '../place/place_screen.dart';

/// Сетка карточек мест с подгрузкой по мере прокрутки.
///
/// Показываем первые шесть, дальше добавляем порциями при подходе к концу
/// списка. На экране города или в обзоре мест бывают сотни — строить их все
/// сразу незачем, а на слабом телефоне ещё и заметно.
class PagedPlaceGrid extends StatefulWidget {
  const PagedPlaceGrid({
    super.key,
    required this.items,
    this.pageSize = 6,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  final List<PlaceWithText> items;
  final int pageSize;
  final EdgeInsets padding;

  @override
  State<PagedPlaceGrid> createState() => _PagedPlaceGridState();
}

class _PagedPlaceGridState extends State<PagedPlaceGrid> {
  final _controller = ScrollController();
  late int _visible = widget.pageSize;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _fillViewport();
  }

  /// Если первая порция помещается на экран целиком, прокручивать нечего —
  /// и подгрузка не запустится никогда. На широком мониторе шесть карточек
  /// как раз умещаются в один экран, и список выглядит обрезанным.
  ///
  /// Поэтому после кадра добавляем ещё, пока не появится что прокручивать.
  void _fillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_visible >= widget.items.length) return;
      if (_controller.position.maxScrollExtent > 0) return;

      setState(() {
        _visible = (_visible + widget.pageSize).clamp(0, widget.items.length);
      });
      _fillViewport();
    });
  }

  @override
  void didUpdateWidget(PagedPlaceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сменился фильтр — показываем снова с начала, иначе пользователь
    // окажется в середине уже другого списка.
    if (!identical(oldWidget.items, widget.items)) {
      _visible = widget.pageSize;
      if (_controller.hasClients) _controller.jumpTo(0);
      _fillViewport();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_visible >= widget.items.length) return;
    final position = _controller.position;
    // Подгружаем заранее, за пол-экрана до конца: так подгрузка незаметна,
    // а не выглядит как рывок в конце списка.
    if (position.pixels >= position.maxScrollExtent - position.viewportDimension / 2) {
      setState(() {
        _visible = (_visible + widget.pageSize).clamp(0, widget.items.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _visible.clamp(0, widget.items.length);
    final hasMore = count < widget.items.length;

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _controller,
            padding: widget.padding,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 208,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: count,
            itemBuilder: (context, i) => PlaceCard(item: widget.items[i]),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Показано $count из ${widget.items.length}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
      ],
    );
  }
}

/// Карточка одного места.
class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.item});

  final PlaceWithText item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final stars = ratingStars(item.place.importance);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          ref.read(placeViewCountProvider.notifier).state++;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlaceScreen(placeId: item.place.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientFor(item.place.category),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(iconForCategory(item.place.category),
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categorySingular(item.place.category),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (stars != null) _Stars(count: stars),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        item.summary ?? 'Описание пока не загружено',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  item.summary == null ? scheme.outline : null,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isFallback && item.summary != null)
                      Text(
                        'На другом языке',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          const Icon(Icons.star, size: 11, color: Colors.white),
      ],
    );
  }
}

/// Градиент для шапки карточки места — от цвета категории.
///
/// Раньше оттенок выводился из хэша строки, и водопад мог оказаться
/// розовым. Теперь цвет один и тот же и в плашке фильтра, и на карточке,
/// и в шапке места: категория узнаётся по цвету, а не только по подписи.
List<Color> gradientFor(String category) {
  final base = colorForCategory(category);
  final hsl = HSLColor.fromColor(base);
  return [
    hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor(),
    hsl
        .withHue((hsl.hue + 18) % 360)
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .toColor(),
  ];
}

/// Градиент для карточки города: у городов категории нет, поэтому оттенок
/// выводится из названия — зато он постоянный, и город узнаётся в списке.
List<Color> gradientForName(String name) {
  var hash = 0;
  for (final code in name.codeUnits) {
    hash = (hash * 31 + code) & 0x7fffffff;
  }
  // Сужаем диапазон до холодной части круга: приложение про фьорды,
  // и салатовые с розовыми карточки в нём выглядят чужеродно.
  final hue = 175 + (hash % 90).toDouble();
  return [
    HSLColor.fromAHSL(1, hue, 0.34, 0.38).toColor(),
    HSLColor.fromAHSL(1, (hue + 22) % 360, 0.32, 0.52).toColor(),
  ];
}
