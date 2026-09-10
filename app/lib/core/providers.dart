import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/connection.dart';
import '../data/database.dart';
import '../data/seed_data.dart';
import 'mode.dart';
import 'settings.dart';

export 'mode.dart' show AppMode, modeProvider, availableModesProvider;
export 'settings.dart'
    show languageProvider, mockPositionProvider, profileProvider,
        prefsProvider, NamedPoint, resolveLanguage, supportedLanguages;

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = await openAppDatabase();
  // База приходит готовой из пайплайна. Тестовые данные подставляются
  // только если она почему-то пуста — например, при разработке без
  // собранного assets/db/content.sqlite.
  await seedIfEmpty(db);
  ref.onDispose(db.close);
  return db;
});

/// Почему местоположение не определилось.
///
/// Раньше все случаи сводились к null, и человек видел одно и то же
/// «положение неизвестно» — независимо от того, выключен ли GPS, отклонено
/// ли разрешение или просто нет сигнала. Починить он при этом ничего
/// не мог, потому что не знал, что чинить.
enum LocationProblem {
  /// Геолокация выключена в настройках телефона.
  serviceOff,

  /// Разрешение не выдано, но спросить ещё можно.
  denied,

  /// Разрешение отклонено навсегда — только через настройки приложения.
  deniedForever,

  /// Разрешение есть, но координаты получить не удалось: нет сигнала,
  /// вышло время ожидания, сбой датчика.
  unavailable,
}

class PositionResult {
  const PositionResult({this.position, this.problem});

  final Position? position;
  final LocationProblem? problem;

  bool get isOk => position != null;
}

/// Позиция пользователя. Работает офлайн: GPS не требует сети.
///
/// Никогда не бросает исключение: экран обязан остаться рабочим и без
/// координат, показав список по важности вместо ближайших мест.
final positionProvider = FutureProvider<PositionResult>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const PositionResult(problem: LocationProblem.serviceOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const PositionResult(problem: LocationProblem.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      return const PositionResult(problem: LocationProblem.denied);
    }

    // Ограничение по времени обязательно: в помещении GPS может искать
    // спутники минутами, и экран всё это время висел бы в загрузке.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    return PositionResult(position: position);
  } catch (_) {
    // Сюда попадает и таймаут, и отсутствие сигнала, и сбой датчика.
    // Для пользователя разница невелика: координат нет, но приложение
    // работает.
    return const PositionResult(problem: LocationProblem.unavailable);
  }
});

/// Выбранные категории фильтра; пустое множество означает «все».
final categoryFilterProvider = StateProvider<Set<String>>((ref) => {});

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

  final result = await ref.watch(positionProvider.future);
  final position = result.position;
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
  final modeCategories = ref.watch(modeProvider).categories;

  final counts = <String, int>{};
  for (final p in places) {
    // Плашки считаем по тому, что видно в текущем режиме: предлагать
    // рыбаку фильтр «Музеи», когда музеи скрыты, было бы издевательством.
    if (modeCategories.isNotEmpty &&
        !modeCategories.contains(p.place.category)) {
      continue;
    }
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

/// Самые посещаемые места страны — курируемый топ-20.
///
/// Не зависит ни от фильтра категорий, ни от режима: это ответ на вопрос
/// «что смотрят в Норвегии вообще», и урезать его настройками бессмысленно.
final mostVisitedProvider = FutureProvider<List<PlaceWithText>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final lang = ref.watch(languageProvider);
  return db.mostVisitedPlaces(lang);
});

/// Все фотографии места — для галереи в карточке.
final placePhotosProvider =
    FutureProvider.family<List<Photo>, String>((ref, placeId) async {
  final db = await ref.watch(databaseProvider.future);
  return db.photosForPlace(placeId);
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

  // Режим сужает выдачу до того, ради чего человек открыл приложение:
  // рыбаку не нужны музеи вперемешку с озёрами. Переключиться обратно
  // можно кнопкой в шапке — тот, кто отметил и рыбалку, и музеи, ничего
  // не теряет.
  final mode = ref.watch(modeProvider);
  final modeCategories = mode.categories;
  final inMode = modeCategories.isEmpty
      ? all
      : all.where((p) => modeCategories.contains(p.place.category)).toList();

  final effective = selected.intersection(available);
  final filtered = effective.isEmpty
      ? inMode
      : inMode.where((p) => effective.contains(p.place.category)).toList();

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

/// Национальные правила по виду деятельности.
final nationalRulesProvider =
    FutureProvider.family<List<NationalRule>, String>((ref, activity) async {
  final db = await ref.watch(databaseProvider.future);
  return db.nationalRulesFor(activity);
});

/// Правила для конкретного места: коммуна и её контакты.
final placeRuleProvider =
    FutureProvider.family<PlaceRule?, String>((ref, placeId) async {
  final db = await ref.watch(databaseProvider.future);
  final rules = await db.rulesForPlace(placeId);
  return rules.isEmpty ? null : rules.first;
});

/// Коммуна там, где человек находится сейчас.
///
/// Нужна для охоты: она привязана к территории, а не к достопримечательности.
/// Берём ближайшую известную — точность до коммуны здесь достаточна, а экран
/// показывает её название, чтобы человек сам увидел, если оно не то.
final nearestKommuneRuleProvider = FutureProvider<PlaceRule?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final origin = await ref.watch(searchOriginProvider.future);
  return db.nearestKommune(origin.lat, origin.lon);
});

/// Виды деятельности, для которых у места есть сведения о правилах.
final placeActivitiesProvider =
    FutureProvider.family<List<String>, String>((ref, placeId) async {
  final db = await ref.watch(databaseProvider.future);
  final rules = await db.rulesForPlace(placeId);
  return rules.map((r) => r.activity).toList();
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
