---
title: Разработка
tags: [project/norway-guide, howto]
updated: 2026-09-09
---

# Разработка

Что установлено, как запускать, что где проверяется.
Состояние работ — в [[status]].

## Окружение

| Инструмент | Версия | Путь |
|---|---|---|
| Go | 1.27.1 | `C:\Program Files\Go\bin` |
| Flutter | 3.47.2 stable (Dart 3.13.2) | `E:\dev\flutter` |
| Java | Temurin JDK 17.0.20.1 | `C:\Program Files\Eclipse Adoptium` |
| Chrome | 151 | площадка разработки |

Java нужна только для Planetiler, то есть для Этапа 6 ([[decisions#Карта вне MVP]]).
Android SDK не установлен — сборок под телефон пока нет.

## Запуск приложения

```powershell
cd app
flutter run -d chrome --web-port=8080
```

Проверки перед сдачей изменений:

```powershell
flutter analyze     # должно быть чисто
flutter test        # все тесты зелёные
```

## Запуск разведки контента

```powershell
cd pipeline
go run ./cmd/probe -quick    # 4 объекта, ~5 секунд, проверить что запросы идут
go run ./cmd/probe > ../docs/probe-result.md   # полный прогон, ~8 минут
```

Флаг `-quick` появился не случайно: два полных прогона были потрачены впустую
на собственные ошибки. Всегда прогоняйте его первым.

## Сборка контента и подключение к приложению

Полная цепочка от выгрузки OSM до базы в приложении:

```powershell
cd pipeline
go run ./cmd/extract --bbox 5.0,60.2,5.6,60.5 `
    --out data/places-bergen.jsonl --cities data/cities-bergen.jsonl
go run ./cmd/enrich --in data/places-bergen.jsonl `
    --out data/translations-bergen.jsonl --limit 40
go run ./cmd/build --places data/places-bergen.jsonl `
    --cities data/cities-bergen.jsonl `
    --translations data/translations-bergen.jsonl `
    --out data/content.sqlite --region vestland --region-name Vestland
copy data\content.sqlite ..\app\assets\db\content.sqlite
```

Проверить собранную базу теми же запросами, что делает приложение:

```powershell
go test ./cmd/build/ -v
```

**Ловушка при перезапуске.** База копируется из assets только когда её ещё
нет. В браузере она живёт в OPFS или IndexedDB и переживает перезапуск
приложения, поэтому новая сборка не подхватится сама. Варианты:

- запустить на другом порту (`--web-port=8081`) — другой origin, чистое
  хранилище;
- очистить данные сайта в инструментах разработчика;
- на устройстве — удалить приложение.

**Версия схемы.** `PRAGMA user_version` в собранной базе обязана совпадать
с `schemaVersion` в `app/lib/data/database.dart`. Расходятся — drift примет
готовую базу за пустую и упадёт на «table already exists».

## Данные

`pipeline/data/` — выгрузка OSM и промежуточные файлы, каталог под `.gitignore`.

```powershell
curl -o pipeline/data/norway-latest.osm.pbf `
  https://download.geofabrik.de/europe/norway-latest.osm.pbf
```

Файл весит 1.3 ГБ. Уже скачан.

## Где что проверяется

Web удобен и быстр, но врёт в важном. Это стоит держать в голове постоянно.

| Что | Web | Устройство |
|---|---|---|
| Экраны, навигация, логика | да | да |
| Запросы к базе, тексты, fallback | да | да |
| **Офлайн-поведение** | нет — другая модель хранения (OPFS/IndexedDB) | только здесь |
| **Размер сборки для стора** | нет | только здесь |
| **Производительность списков** | нет — десктоп сильнее телефона | только здесь |
| **SQLite с ICU** | нет — в web это WASM-сборка | только здесь |
| **Исключение файлов из iCloud** | нет | только здесь |

Практический вывод: Android SDK стоит поставить до того, как накопится месяц
работы, не проверенной там, где она должна работать.

## Особенности среды

- **Геолокация Windows** может быть недоступна: у стационарного ПК без Wi-Fi
  источника определения нет вовсе. Поэтому в приложении есть ручной ввод
  города ([[decisions#Положение можно указать вручную]]).
- **Wikipedia отдаёт 429** при частых анонимных запросах. Темп ~2 rps,
  уважать `Retry-After`, и никогда не трактовать сбой как «статьи нет».
- **`flutter analyze` не ловит ошибки разметки.** Экран может собраться
  без единого предупреждения и не отрисоваться в браузере. Виджет-тесты
  на построение экрана — единственная защита.

## Тесты

```
app/test/widget_test.dart       расстояние и азимут
app/test/home_screen_test.dart  стартовый экран строится, узкий экран
```

Второй файл появился после реальной поломки: `Spacer` внутри
`SingleChildScrollView` уронил построение, и на экране остался только фон.
