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
  const PlaceCategory(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

const placeCategories = <PlaceCategory>[
  PlaceCategory('museum', 'Музеи', Icons.museum),
  PlaceCategory('viewpoint', 'Смотровые', Icons.landscape),
  PlaceCategory('fjord', 'Фьорды', Icons.water),
  PlaceCategory('waterfall', 'Водопады', Icons.water_drop),
  PlaceCategory('church', 'Церкви', Icons.church),
  PlaceCategory('hike', 'Тропы', Icons.hiking),
  PlaceCategory('glacier', 'Ледники', Icons.ac_unit),
  PlaceCategory('beach', 'Пляжи', Icons.beach_access),
];

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
