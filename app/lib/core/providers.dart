import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/connection.dart';
import '../data/database.dart';
import '../data/seed_data.dart';
import 'profile.dart';

/// Языки, на которых говорит приложение (§8.2 спеки).
const supportedLanguages = ['en', 'no', 'de', 'es', 'ru', 'zh'];

/// Приводит локаль системы к одному из поддерживаемых языков.
///
/// Сопоставление по коду без региона: `de-AT` → `de`, `zh-Hans-CN` → `zh`.
/// Норвежские `nb` (букмол) и `nn` (нюнорск) оба ведут на `no` — иначе
/// половина норвежских телефонов получит английский в приложении о Норвегии.
/// Всё, чего нет в списке, получает английский.
String resolveLanguage(ui.Locale locale) {
  final code = locale.languageCode.toLowerCase();
  if (code == 'nb' || code == 'nn' || code == 'no') return 'no';
  if (supportedLanguages.contains(code)) return code;
  return 'en';
}

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();
  // База приходит готовой из пайплайна. Тестовые данные подставляются
  // только если она почему-то пуста — например, при разработке без
  // собранного assets/db/content.sqlite.
  await seedIfEmpty(db);
  ref.onDispose(db.close);
  return db;
});

/// Текущий язык контента и интерфейса.
///
/// Начальное значение — язык системы; выбор пользователя в настройках
/// имеет приоритет и переопределяет его.
final languageProvider = StateProvider<String>((ref) {
  return resolveLanguage(
    WidgetsBinding.instance.platformDispatcher.locale,
  );
});

/// Позиция пользователя. Работает офлайн: GPS не требует сети.
///
/// Если разрешение не выдано или геолокация выключена, возвращает null —
/// экран в этом случае показывает список по важности, а не пустоту.
final positionProvider = FutureProvider<Position?>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  } catch (_) {
    // Геолокация — не критичный путь. Ошибка не должна ломать экран.
    return null;
  }
});

/// Выбранные категории фильтра; пустое множество означает «все».
final categoryFilterProvider = StateProvider<Set<String>>((ref) => {});

/// Точка на карте с названием — для отладочной подмены положения.
typedef NamedPoint = ({String name, double lat, double lon});

/// Положение, указанное пользователем вручную. null — использовать GPS.
///
/// Нужно не только для отладки: GPS недоступен на десктопе, разрешение может
/// быть не выдано, а в помещении определение бывает неточным. Указанный
/// вручную город имеет приоритет над GPS, пока пользователь сам не вернёт
/// автоопределение.
final mockPositionProvider = StateProvider<NamedPoint?>((ref) => null);

/// Точка, от которой ведётся поиск, и радиус вокруг неё.
///
/// Приоритет: указанный вручную город → GPS → центр страны с большим радиусом.
/// Последний вариант оставляет экран полезным, когда положение неизвестно.
final searchOriginProvider =
    FutureProvider<({double lat, double lon, double radiusKm})>((ref) async {
  final manual = ref.watch(mockPositionProvider);
  if (manual != null) {
    return (lat: manual.lat, lon: manual.lon, radiusKm: 200.0);
  }

  final position = await ref.watch(positionProvider.future);
  if (position != null) {
    return (
      lat: position.latitude,
      lon: position.longitude,
      radiusKm: 200.0,
    );
  }

  return (lat: 64.5, lon: 11.0, radiusKm: 2000.0);
});

/// Все места вокруг точки, без учёта фильтра категорий.
///
/// Отдельно от [nearbyPlacesProvider], потому что список доступных категорий
/// должен считаться до применения фильтра — иначе выбор одной категории
/// скрыл бы все остальные кнопки.
final placesAroundProvider = FutureProvider<List<PlaceWithText>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  final origin = await ref.watch(searchOriginProvider.future);

  return db.placesNearby(
    lat: origin.lat,
    lon: origin.lon,
    lang: lang,
    radiusKm: origin.radiusKm,
  );
});

/// Категории, по которым рядом реально что-то есть, и сколько именно.
///
/// Кнопки фильтра для пустых категорий не показываем: предлагать «Ледники»
/// там, где ледников нет, — это обещание, которое экран не выполнит.
final nearbyCategoryCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final places = await ref.watch(placesAroundProvider.future);
  final counts = <String, int>{};
  for (final p in places) {
    counts[p.place.category] = (counts[p.place.category] ?? 0) + 1;
  }
  return counts;
});

/// Просто набор доступных категорий — для отсечения устаревшего выбора.
final availableCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final counts = await ref.watch(nearbyCategoryCountsProvider.future);
  return counts.keys.toSet();
});

final placeTagsProvider = FutureProvider<Map<String, Set<String>>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.allPlaceTags();
});

/// Города для обзора, по убыванию туристической ценности.
final cityCardsProvider = FutureProvider<List<CityCard>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.cityCards();
});

/// Категории среди заметных мест: категория → сколько в ней объектов.
///
/// Плашка показывается, только если за ней стоит не меньше двух мест:
/// одинокий пляж на всю страну — не категория, а случайность.
final topCategoriesProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final counts = await db.topCategoryCounts();
  return {
    for (final e in counts.entries)
      if (e.value >= 2) e.key: e.value,
  };
});

/// Выбранные категории во вкладке «Достопримечательности».
/// Отдельно от фильтра на экране «Рядом»: это разные экраны с разной задачей,
/// и общий фильтр между ними сбивал бы с толку.
final topCategoryFilterProvider = StateProvider<Set<String>>((ref) => {});

/// Самые заметные места страны — вкладка «Достопримечательности».
final topPlacesProvider = FutureProvider<List<PlaceWithText>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  final selected = ref.watch(topCategoryFilterProvider);
  return db.topPlaces(lang, categories: selected.toList());
});

/// Места выбранного города, по убыванию значимости.
final placesInCityProvider =
    FutureProvider.family<List<PlaceWithText>, String>((ref, cityId) async {
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  return db.placesInCity(cityId, lang);
});

/// Места рядом с пользователем с учётом выбранных категорий и профиля.
///
/// Учитываются только те категории, которые рядом вообще есть. Иначе выбор,
/// сделанный в другом городе, остался бы висеть невидимым фильтром: кнопка
/// пропала вместе с категорией, а список молча опустел.
///
/// Профиль меняет **порядок**, но ничего не убирает из списка: подходящие
/// интересам места как бы становятся ближе. Коэффициент 0.35 подобран так,
/// чтобы расстояние осталось главным — на экране «рядом со мной» музей за
/// 80 км не должен обгонять водопад за 3 км только потому, что человек
/// отметил интерес к музеям.
final nearbyPlacesProvider = FutureProvider<List<PlaceWithText>>((ref) async {
  final all = await ref.watch(placesAroundProvider.future);
  final available = await ref.watch(availableCategoriesProvider.future);
  final selected = ref.watch(categoryFilterProvider);
  final profile = ref.watch(profileProvider);
  final tags = await ref.watch(placeTagsProvider.future);

  final effective = selected.intersection(available);
  final filtered = effective.isEmpty
      ? all
      : all.where((p) => effective.contains(p.place.category)).toList();

  if (profile.isEmpty) return filtered;

  final ranked = List<PlaceWithText>.from(filtered);
  double rank(PlaceWithText p) {
    final boost = profile.boostFor(
      p.place.category,
      tags[p.place.id] ?? const <String>{},
    );
    final distance = p.distanceMeters ?? 0;
    return distance / (1 + boost * 0.35);
  }

  ranked.sort((a, b) => rank(a).compareTo(rank(b)));
  return ranked;
});

/// Текст в строке поиска. Обновляется с задержкой — см. экран поиска.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Результаты поиска.
///
/// Меньше двух символов не ищем: по одной букве находится половина базы,
/// и выдача бесполезна, а запрос при этом самый тяжёлый.
final searchResultsProvider = FutureProvider<List<PlaceWithText>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length < 2) return [];

  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  return db.searchPlaces(query, lang);
});

final placeProvider =
    FutureProvider.family<PlaceWithText?, String>((ref, id) async {
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  return db.placeById(id, lang);
});

final favoritesProvider = StreamProvider<List<Favorite>>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  yield* db.watchFavorites();
});

/// Избранное вместе с данными мест — для экрана «Моя поездка».
final favoritePlacesProvider =
    StreamProvider<List<FavoritePlace>>((ref) async* {
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  yield* db.watchFavoritePlaces(lang);
});
