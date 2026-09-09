# nordguide

Офлайн-гид по Норвегии: карта, города, достопримечательности, маршруты — всё работает
без интернета. Содержимое скачивается один раз пакетами по регионам.

## Документация

Начните с карты документов: [`docs/README.md`](docs/README.md)

- [Состояние проекта](docs/status.md) — что сделано и что дальше
- [Журнал решений](docs/decisions.md) — чем текущий план отличается от спеки
- [Спецификация](docs/norway-offline-guide-spec.md) — исходный документ
- [Разработка](docs/development.md) — как запустить

## Что где

- `pipeline/` — Go: готовит контент (OSM → Wikidata/Wikivoyage → фото → SQLite → пакеты)
- `app/` — Flutter: само приложение
- `docs/` — спецификация и производные заметки

Корень проекта одновременно является Obsidian-хранилищем: документация правится
в Obsidian и лежит в git рядом с кодом.

## Требования

- Go 1.22+
- Flutter SDK 3.x (stable)
- Java 17+ и Planetiler — для генерации тайлов

Ничего из этого сейчас в системе не установлено.

## Быстрый старт (Этап 0)

```sh
cd pipeline
go mod tidy
# скачать выгрузку Норвегии в data/ (~1.5 ГБ)
curl -o data/norway-latest.osm.pbf https://download.geofabrik.de/europe/norway-latest.osm.pbf
make extract REGION=vestland
```

Makefile и команды пайплайна ещё не написаны — это первая задача Этапа 0.

## Лицензии данных

Приложение использует открытые источники и обязано указывать авторство:

- OpenStreetMap © участники — ODbL
- Wikipedia / Wikivoyage — CC BY-SA 4.0
- Wikimedia Commons — только CC0 / CC BY / CC BY-SA, с автором у каждого снимка
- Kartverket — NLOD

Подробности и запреты — §7 спецификации.
