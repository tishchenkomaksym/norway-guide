import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Категории мест — единственное место, где они описаны.
///
/// Раньше метки и иконки были продублированы в экранах «Рядом со мной»
/// и «Обзор». Дубликат разошёлся бы при первой же правке: в одном экране
/// «Виды», в другом «Смотровая» — для одного и того же.
///
/// Ключи совпадают с колонкой places.category и приходят из пайплайна
/// (pipeline/internal/osm/categories.go). Менять их нельзя без пересборки
/// данных.
class PlaceCategory {
  const PlaceCategory(this.id, this.icon, this.color);

  final String id;
  final IconData icon;

  /// Цвет категории. Не случайный: взят от того, как объект выглядит
  /// в природе — фьорд глубокий синий, ледник ледяной голубой, тропа
  /// зелёная, церковь тёплая охра. Так плашка узнаётся боковым зрением,
  /// без чтения подписи.
  final Color color;
}

const placeCategories = <PlaceCategory>[
  PlaceCategory('museum', Icons.museum, Color(0xFF8E5BA6)),
  PlaceCategory('viewpoint', Icons.landscape, Color(0xFFE08A3C)),
  PlaceCategory('fjord', Icons.water, Color(0xFF1F6F8B)),
  PlaceCategory('waterfall', Icons.water_drop, Color(0xFF3EA6C4)),
  PlaceCategory('church', Icons.church, Color(0xFFA9743F)),
  PlaceCategory('hike', Icons.hiking, Color(0xFF4E8C4A)),
  PlaceCategory('glacier', Icons.ac_unit, Color(0xFF6FA8C7)),
  PlaceCategory('beach', Icons.beach_access, Color(0xFFD9B25A)),
];

/// Цвет категории; для неизвестной — нейтральный серо-синий.
Color colorForCategory(String id) =>
    _byId[id]?.color ?? const Color(0xFF6B7A85);

final _byId = {for (final c in placeCategories) c.id: c};

/// Название категории во множественном числе — для плашек фильтра.
///
/// Требует контекста, потому что переводится: категорий восемь, они видны
/// на каждом экране, и оставить их по-русски значило бы, что приложение
/// «локализовано» лишь наполовину.
String categoryLabel(BuildContext context, String id) {
  final l = L.of(context);
  switch (id) {
    case 'museum':
      return l.catMuseums;
    case 'viewpoint':
      return l.catViewpoints;
    case 'fjord':
      return l.catFjords;
    case 'waterfall':
      return l.catWaterfalls;
    case 'church':
      return l.catChurches;
    case 'hike':
      return l.catHikes;
    case 'glacier':
      return l.catGlaciers;
    case 'beach':
      return l.catBeaches;
    default:
      return l.catOther;
  }
}

/// Название в единственном числе — для карточки одного места.
String categorySingular(BuildContext context, String id) {
  final l = L.of(context);
  switch (id) {
    case 'museum':
      return l.catMuseum;
    case 'viewpoint':
      return l.catViewpoint;
    case 'fjord':
      return l.catFjord;
    case 'waterfall':
      return l.catWaterfall;
    case 'church':
      return l.catChurch;
    case 'hike':
      return l.catHike;
    case 'glacier':
      return l.catGlacier;
    case 'beach':
      return l.catBeach;
    default:
      return l.catOther;
  }
}

IconData iconForCategory(String id) => _byId[id]?.icon ?? Icons.place;

/// Упорядочивает категории по числу объектов, оставляя только известные.
///
/// Отбрасывание неизвестных ключей защищает от плашки-призрака, если
/// в данных заведётся категория, которой нет в этом списке.
List<String> orderedCategories(Map<String, int> counts) {
  final known = counts.keys.where(_byId.containsKey).toList();
  known.sort((a, b) => counts[b]!.compareTo(counts[a]!));
  return known;
}

/// Оценка места в звёздах по внешнему признанию.
///
/// Раньше звёзды считались из `importance`, а он складывается в том числе
/// из полноты разметки в OpenStreetMap: сколько тегов, есть ли часы работы
/// и сайт. Получалось смещение — городской музей с сайтом набирал четыре
/// звезды, а горное озеро редкой красоты не получало ни одной, потому что
/// тегов у него два. Человек при этом читает звёзды как «насколько тут
/// хорошо», и расхождение между тем, что мы считали, и тем, что он
/// понимал, было враньём по существу.
///
/// Теперь в счёт идёт только признание извне, которое от нашей разметки
/// не зависит:
///
/// - список Всемирного наследия ЮНЕСКО;
/// - место в курируемом топе самых посещаемых;
/// - на скольких языках о месте написали. Статья по-английски и
///   по-немецки означает, что место знают иностранцы, а не только
///   соседняя деревня.
///
/// Звёзд нет вовсе, если ни одного признака не набралось. Это честнее,
/// чем рисовать одну звезду всему подряд: отсутствие звёзд означает
/// «мы не знаем», а не «плохое место».
int? ratingStars({
  required bool unesco,
  required int topRank,
  required int langCount,
}) {
  // ЮНЕСКО и первая десятка топа — безусловные пять.
  if (unesco || (topRank > 0 && topRank <= 10)) return 5;
  // Остальной топ и места, о которых написали на трёх языках.
  if (topRank > 0 || langCount >= 3) return 4;
  if (langCount == 2) return 3;
  if (langCount == 1) return 2;
  return null;
}
