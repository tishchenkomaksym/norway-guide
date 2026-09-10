import 'package:flutter/material.dart';

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
  const PlaceCategory(this.id, this.label, this.icon, this.color);

  final String id;
  final String label;
  final IconData icon;

  /// Цвет категории. Не случайный: взят от того, как объект выглядит
  /// в природе — фьорд глубокий синий, ледник ледяной голубой, тропа
  /// зелёная, церковь тёплая охра. Так плашка узнаётся боковым зрением,
  /// без чтения подписи.
  final Color color;
}

const placeCategories = <PlaceCategory>[
  PlaceCategory('museum', 'Музеи', Icons.museum, Color(0xFF8E5BA6)),
  PlaceCategory('viewpoint', 'Смотровые', Icons.landscape, Color(0xFFE08A3C)),
  PlaceCategory('fjord', 'Фьорды', Icons.water, Color(0xFF1F6F8B)),
  PlaceCategory('waterfall', 'Водопады', Icons.water_drop, Color(0xFF3EA6C4)),
  PlaceCategory('church', 'Церкви', Icons.church, Color(0xFFA9743F)),
  PlaceCategory('hike', 'Тропы', Icons.hiking, Color(0xFF4E8C4A)),
  PlaceCategory('glacier', 'Ледники', Icons.ac_unit, Color(0xFF6FA8C7)),
  PlaceCategory('beach', 'Пляжи', Icons.beach_access, Color(0xFFD9B25A)),
];

/// Цвет категории; для неизвестной — нейтральный серо-синий.
Color colorForCategory(String id) => _byId[id]?.color ?? const Color(0xFF6B7A85);

final _byId = {for (final c in placeCategories) c.id: c};

/// Название категории во множественном числе — для плашек фильтра.
String categoryLabel(String id) => _byId[id]?.label ?? 'Другое';

/// Название в единственном числе — для карточки одного места.
String categorySingular(String id) {
  const singular = {
    'museum': 'Музей',
    'viewpoint': 'Смотровая',
    'fjord': 'Фьорд',
    'waterfall': 'Водопад',
    'church': 'Церковь',
    'hike': 'Тропа',
    'glacier': 'Ледник',
    'beach': 'Пляж',
  };
  return singular[id] ?? 'Место';
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

/// Оценка места в звёздах, 1..5, из importance (0..100).
///
/// Не выдумка: importance складывается пайплайном из типа объекта, наличия
/// статьи в Wikidata и Wikipedia, статуса наследия и ЮНЕСКО. То есть это
/// мера известности, а не чья-то субъективная оценка красоты.
///
/// Порог 45 для одной звезды не случайный: ниже него лежат объекты вообще
/// без внешних признаков известности, и рисовать им звёзды было бы враньём.
int? ratingStars(int importance) {
  if (importance < 45) return null;
  if (importance >= 90) return 5;
  if (importance >= 78) return 4;
  if (importance >= 66) return 3;
  if (importance >= 55) return 2;
  return 1;
}
