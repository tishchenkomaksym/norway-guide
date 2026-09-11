import 'package:intl/intl.dart';

import '../data/database.dart';

/// Экспорт мест в GPX.
///
/// Зачем он нужен. Приложение не прокладывает дорогу и не ведёт по ней —
/// это и не его задача. Но человек, собравший прогулку по Бергену или
/// список избранного, должен иметь возможность взять его с собой: в
/// Garmin, OsmAnd, Komoot, часы, автомобильный навигатор. GPX понимают
/// все они, и это единственный формат с таким охватом.
///
/// Что кладём в файл. Точки (`wpt`) с координатами, названием и описанием,
/// а для маршрута ещё и `rte` с порядком обхода. Трека (`trk`) здесь нет
/// намеренно: трек — это записанный путь с привязкой ко времени, а у нас
/// порядок точек, а не линия по дорогам. Подсунуть прямые отрезки между
/// точками под видом трека значило бы наврать про маршрут, который
/// навигатор потом честно попытается повторить.
///
/// Кодировка и экранирование. Названия норвежских мест полны символов
/// «ø», «å», «æ», а в описаниях с Wikipedia попадаются кавычки и
/// амперсанды. Файл пишется в UTF-8, а пять служебных символов XML
/// экранируются — иначе половина навигаторов молча откажется открывать
/// файл, а вторая покажет вместо названия мусор.
class GpxBuilder {
  /// Маршрут: точки в заданном порядке плюс элемент `rte`.
  static String route({
    required String name,
    required List<PlaceWithText> stops,
    String? description,
  }) {
    final buffer = StringBuffer();
    _header(buffer, name, description);

    for (var i = 0; i < stops.length; i++) {
      _waypoint(buffer, stops[i], number: i + 1);
    }

    buffer.writeln('  <rte>');
    buffer.writeln('    <name>${_escape(name)}</name>');
    for (final stop in stops) {
      final place = stop.place;
      buffer.writeln(
        '    <rtept lat="${_coord(place.lat)}" lon="${_coord(place.lon)}">',
      );
      buffer.writeln('      <name>${_escape(stop.name)}</name>');
      buffer.writeln('    </rtept>');
    }
    buffer.writeln('  </rte>');

    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  /// Просто набор точек — например, избранное. Без `rte`: порядка обхода
  /// у избранного нет, и придумывать его не надо.
  static String waypoints({
    required String name,
    required List<PlaceWithText> places,
  }) {
    final buffer = StringBuffer();
    _header(buffer, name, null);
    for (final place in places) {
      _waypoint(buffer, place);
    }
    buffer.writeln('</gpx>');
    return buffer.toString();
  }

  static void _header(StringBuffer b, String name, String? description) {
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln(
      '<gpx version="1.1" creator="Norway Explore" '
      'xmlns="http://www.topografix.com/GPX/1/1" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
      'http://www.topografix.com/GPX/1/1/gpx.xsd">',
    );
    b.writeln('  <metadata>');
    b.writeln('    <name>${_escape(name)}</name>');
    if (description != null && description.isNotEmpty) {
      b.writeln('    <desc>${_escape(description)}</desc>');
    }
    // Время создания в UTC — обязательное поле по схеме GPX 1.1.
    b.writeln('    <time>${_now()}</time>');
    b.writeln('  </metadata>');
  }

  static void _waypoint(StringBuffer b, PlaceWithText item, {int? number}) {
    final place = item.place;
    final title = number == null ? item.name : '$number. ${item.name}';

    b.writeln('  <wpt lat="${_coord(place.lat)}" lon="${_coord(place.lon)}">');
    b.writeln('    <name>${_escape(title)}</name>');
    if (item.summary != null && item.summary!.isNotEmpty) {
      // Описание обрезаем: некоторые навигаторы показывают его целиком
      // во всплывающей подсказке, и статья на три абзаца закрывает карту.
      final text = item.summary!.length > 300
          ? '${item.summary!.substring(0, 300)}…'
          : item.summary!;
      b.writeln('    <desc>${_escape(text)}</desc>');
    }
    // Тип точки — по нему навигаторы подбирают значок.
    b.writeln('    <type>${_escape(place.category)}</type>');
    b.writeln('  </wpt>');
  }

  /// Координаты с шестью знаками: это около десяти сантиметров на
  /// местности, больше не нужно и незачем раздувать файл.
  static String _coord(double value) => value.toStringAsFixed(6);

  static String _now() =>
      DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());

  /// Экранирование пяти служебных символов XML.
  ///
  /// Амперсанд обязан идти первым: иначе он снова экранирует то, что
  /// уже подставлено на следующих шагах, и получится «&amp;amp;».
  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
