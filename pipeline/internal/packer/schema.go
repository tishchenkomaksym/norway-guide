// Package packer собирает контентную базу и пакеты регионов.
package packer

// SchemaVersion записывается в PRAGMA user_version и обязана совпадать
// с schemaVersion класса AppDatabase в app/lib/data/database.dart.
//
// Если версии разойдутся, drift примет готовую базу за пустую и попытается
// создать таблицы заново — приложение упадёт при первом открытии.
const SchemaVersion = 1

// Schema — DDL контентной базы.
//
// ОБЯЗАН совпадать со схемой drift в app/lib/data/tables.dart: приложение
// открывает этот файл напрямую. Расхождение проявится не при сборке,
// а при первом запросе на устройстве — то есть поздно и не у нас.
//
// Имена колонок в snake_case, потому что drift именно так преобразует
// camelCase-поля Dart.
const Schema = `
CREATE TABLE IF NOT EXISTS regions (
    id           TEXT PRIMARY KEY,
    name_no      TEXT NOT NULL,
    bbox         TEXT NOT NULL,
    pack_size_mb INTEGER,
    pack_version INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS cities (
    id           TEXT PRIMARY KEY,
    region_id    TEXT NOT NULL REFERENCES regions(id),
    name_no      TEXT NOT NULL,
    lat          REAL NOT NULL,
    lon          REAL NOT NULL,
    population   INTEGER,
    hero_photo   TEXT
);

CREATE TABLE IF NOT EXISTS places (
    id            TEXT PRIMARY KEY,
    city_id       TEXT REFERENCES cities(id),
    region_id     TEXT NOT NULL REFERENCES regions(id),
    category      TEXT NOT NULL,
    name_no       TEXT NOT NULL,
    lat           REAL NOT NULL,
    lon           REAL NOT NULL,
    opening_hours TEXT,
    website       TEXT,
    wikidata_id   TEXT,
    entrance_fee  TEXT,
    season        TEXT,
    difficulty    TEXT,
    duration_min  INTEGER,
    importance    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS place_tags (
    place_id     TEXT NOT NULL REFERENCES places(id),
    tag          TEXT NOT NULL,
    PRIMARY KEY (place_id, tag)
);

CREATE TABLE IF NOT EXISTS photos (
    id           INTEGER PRIMARY KEY,
    place_id     TEXT REFERENCES places(id),
    city_id      TEXT REFERENCES cities(id),
    path_thumb   TEXT NOT NULL,
    path_full    TEXT NOT NULL,
    author       TEXT NOT NULL,
    license      TEXT NOT NULL,
    source_url   TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS routes (
    id           TEXT PRIMARY KEY,
    city_id      TEXT REFERENCES cities(id),
    duration_h   REAL,
    distance_km  REAL
);

CREATE TABLE IF NOT EXISTS route_stops (
    route_id     TEXT NOT NULL REFERENCES routes(id),
    place_id     TEXT NOT NULL REFERENCES places(id),
    ord          INTEGER NOT NULL,
    note         TEXT,
    PRIMARY KEY (route_id, ord)
);

CREATE TABLE IF NOT EXISTS translations (
    entity_type  TEXT NOT NULL,
    entity_id    TEXT NOT NULL,
    lang         TEXT NOT NULL,
    name         TEXT,
    summary      TEXT,
    description  TEXT,
    source       TEXT,
    quality      INTEGER NOT NULL DEFAULT 50,
    source_url   TEXT,
    rev_id       INTEGER,
    PRIMARY KEY (entity_type, entity_id, lang)
);

-- Пользовательская таблица.
--
-- На Этапе 2 переедет в отдельный файл и будет подключаться через ATTACH:
-- обновление контентного пакета не должно стирать избранное. Пока живёт
-- здесь, потому что drift ожидает её в том же подключении.
CREATE TABLE IF NOT EXISTS favorites (
    place_id     TEXT PRIMARY KEY,
    added_at     INTEGER NOT NULL,
    visited      INTEGER NOT NULL DEFAULT 0,
    user_note    TEXT
);

CREATE INDEX IF NOT EXISTS idx_tr_lookup  ON translations(entity_type, entity_id, lang);
CREATE INDEX IF NOT EXISTS idx_tr_lang    ON translations(lang, entity_type);
CREATE INDEX IF NOT EXISTS idx_places_region ON places(region_id);
CREATE INDEX IF NOT EXISTS idx_places_city   ON places(city_id);
CREATE INDEX IF NOT EXISTS idx_places_cat    ON places(category, importance DESC);
CREATE INDEX IF NOT EXISTS idx_places_geo    ON places(lat, lon);
CREATE INDEX IF NOT EXISTS idx_cities_region ON cities(region_id);
`

// SchemaFTS — полнотекстовый поиск.
//
// Одна строка на пару (объект, язык): искать надо по языку пользователя
// И по норвежскому И по английскому одновременно. Немец видит на указателе
// «Trolltunga», а не немецкое название, и ограничение выдачи локалью
// сломало бы самый частый сценарий.
//
// prefix='2 3' даёт префиксный поиск штатными средствами FTS5 — отдельный
// индекс под автодополнение не нужен.
const SchemaFTS = `
CREATE VIRTUAL TABLE IF NOT EXISTS search_fts USING fts5(
    entity_type UNINDEXED,
    entity_id   UNINDEXED,
    lang        UNINDEXED,
    name,
    description,
    prefix = '2 3',
    tokenize = 'unicode61 remove_diacritics 2'
);
`
