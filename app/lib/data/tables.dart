import 'package:drift/drift.dart';

/// Таблицы контентной базы. Она поставляется готовой и открывается только на
/// чтение — приложение её никогда не пишет.
///
/// Схема повторяет §4 спецификации. Ключевой инвариант: все тексты живут в
/// [Translations], в основных таблицах остаётся только `nameNo` как канонический
/// ключ. Колонок вида `name_en` или `description_ru` здесь быть не должно.

@DataClassName('Region')
class Regions extends Table {
  /// 'vestland', 'nordland'
  TextColumn get id => text()();
  TextColumn get nameNo => text()();

  /// 'minLon,minLat,maxLon,maxLat'
  TextColumn get bbox => text()();
  IntColumn get packSizeMb => integer().nullable()();
  IntColumn get packVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('City')
class Cities extends Table {
  TextColumn get id => text()();
  TextColumn get regionId => text().references(Regions, #id)();
  TextColumn get nameNo => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  IntColumn get population => integer().nullable()();

  /// Относительный путь к файлу, не URL.
  TextColumn get heroPhoto => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Place')
class Places extends Table {
  /// Канонический идентификатор вида 'osm:node/123456'.
  TextColumn get id => text()();
  TextColumn get cityId => text().nullable().references(Cities, #id)();
  TextColumn get regionId => text().references(Regions, #id)();

  /// fjord|museum|waterfall|viewpoint|church|hike|beach|glacier
  TextColumn get category => text()();
  TextColumn get nameNo => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get openingHours => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get wikidataId => text().nullable()();
  TextColumn get entranceFee => text().nullable()();

  /// 'jun-sep' для горных дорог, закрытых зимой.
  TextColumn get season => text().nullable()();

  /// Для троп.
  TextColumn get difficulty => text().nullable()();
  IntColumn get durationMin => integer().nullable()();

  /// 0..100 — сортировка выдачи и приоритет офлайн-загрузки.
  IntColumn get importance => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Мультитеги поверх категории: одной категории мало, «музей с детьми» и
/// «музей для ценителя» — разные объекты. Нужны для профилей пользователя
/// (см. docs/onboarding-profiles.md): kids_friendly, unesco, fishing,
/// winter_open, near_port, wheelchair.
@DataClassName('PlaceTag')
class PlaceTags extends Table {
  TextColumn get placeId => text().references(Places, #id)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {placeId, tag};
}

@DataClassName('Photo')
class Photos extends Table {
  IntColumn get id => integer()();
  TextColumn get placeId => text().nullable().references(Places, #id)();
  TextColumn get cityId => text().nullable().references(Cities, #id)();

  /// 320px webp
  TextColumn get pathThumb => text()();

  /// 1280px webp
  TextColumn get pathFull => text()();

  /// Автор и лицензия обязательны: без них фото не имеет права попасть
  /// в базу (§7 спеки, требование CC-атрибуции).
  TextColumn get author => text()();
  TextColumn get license => text()();
  TextColumn get sourceUrl => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Route')
class Routes extends Table {
  TextColumn get id => text()();
  TextColumn get cityId => text().nullable().references(Cities, #id)();
  RealColumn get durationH => real().nullable()();
  RealColumn get distanceKm => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RouteStop')
class RouteStops extends Table {
  TextColumn get routeId => text().references(Routes, #id)();
  TextColumn get placeId => text().references(Places, #id)();
  IntColumn get ord => integer()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {routeId, ord};
}

/// Единая таблица переводов для всех сущностей.
///
/// `entityType`: 'place' | 'city' | 'region' | 'route' | 'category'.
/// `quality`: 0..100, машинный перевод (`source='mt'`) держим ниже 50, чтобы
/// позже заменить его человеческим без пересборки базы.
@DataClassName('Translation')
class Translations extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// 'en','no','de','es','ru','zh'
  TextColumn get lang => text()();
  TextColumn get name => text().nullable()();

  /// Короткий самостоятельный текст для списка и офлайн-уровня. Не обрезанное
  /// начало статьи: офлайн это единственное, что человек увидит.
  TextColumn get summary => text().nullable()();

  /// Полный текст карточки. Догружается по клику при наличии сети.
  TextColumn get description => text().nullable()();

  /// 'wikivoyage' | 'wikipedia' | 'manual' | 'mt'
  TextColumn get source => text().nullable()();
  IntColumn get quality => integer().withDefault(const Constant(50))();

  @override
  Set<Column> get primaryKey => {entityType, entityId, lang};
}

/// Где проверять правила рыбалки и охоты для конкретного места.
///
/// В таблице намеренно нет полей «можно» или «нельзя»: разрешение зависит
/// от коммуны, владельца воды, сезона и вида, и автоматически определить его
/// нельзя. Приложение, которое скажет «здесь можно», а человек получит
/// штраф, хуже отсутствия функции.
@DataClassName('PlaceRule')
class PlaceRules extends Table {
  TextColumn get placeId => text().references(Places, #id)();

  /// fishing | hunting
  TextColumn get activity => text()();
  TextColumn get kommuneNumber => text()();
  TextColumn get kommuneName => text()();
  TextColumn get countyName => text().nullable()();
  TextColumn get kommunePhone => text().nullable()();
  TextColumn get kommuneWebsite => text().nullable()();

  /// Дата получения контактов. Показывается пользователю: сведения
  /// устаревают, и он должен видеть, насколько они свежие.
  TextColumn get checkedAt => text()();

  @override
  Set<Column> get primaryKey => {placeId, activity};
}

/// Правила, действующие по всей стране.
///
/// Источник и ответственный орган обязательны: правило, которое нельзя
/// перепроверить, показывать нечестно.
@DataClassName('NationalRule')
class NationalRules extends Table {
  IntColumn get id => integer()();
  TextColumn get activity => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get authority => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Пользовательская таблица. Живёт в ОТДЕЛЬНОМ файле БД и подключается через
/// ATTACH: обновление контентного пакета не должно стирать данные пользователя.
@DataClassName('Favorite')
class Favorites extends Table {
  TextColumn get placeId => text()();
  IntColumn get addedAt => integer()();
  BoolColumn get visited => boolean().withDefault(const Constant(false))();
  TextColumn get userNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {placeId};
}
