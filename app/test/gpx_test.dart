import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/core/gpx.dart';
import 'package:nordguide/data/database.dart';
import 'package:xml/xml.dart';

/// Формат GPX.
///
/// Проверять его здесь важнее, чем кажется: ошибка в разметке проявится
/// не у нас, а в чужом навигаторе — файл либо не откроется вовсе, либо
/// покажет вместо норвежских названий мусор. Обратной связи при этом
/// не будет никакой.
///
/// Разбор идёт настоящим XML-парсером, а не поиском подстрок: только так
/// проверка ловит незакрытый тег или сломанное экранирование.
void main() {
  PlaceWithText makePlace({
    required String id,
    required String name,
    required double lat,
    required double lon,
    String category = 'museum',
    String? summary,
  }) {
    return PlaceWithText(
      place: Place(
        id: id,
        regionId: 'r',
        category: category,
        nameNo: name,
        lat: lat,
        lon: lon,
        importance: 50,
        topRank: 0,
        visitors: 0,
        visitorsYear: 0,
        unesco: 0,
      ),
      name: name,
      summary: summary,
      isFallback: false,
    );
  }

  test('маршрут разбирается как корректный XML', () {
    final xml = GpxBuilder.route(
      name: 'Прогулка по Бергену',
      stops: [
        makePlace(id: '1', name: 'Bryggen', lat: 60.3975, lon: 5.3242),
        makePlace(id: '2', name: 'Fløibanen', lat: 60.3967, lon: 5.3272),
      ],
    );

    final doc = XmlDocument.parse(xml);
    expect(doc.rootElement.name.local, 'gpx');
    expect(doc.rootElement.getAttribute('version'), '1.1');
    expect(doc.findAllElements('wpt').length, 2);
    expect(doc.findAllElements('rtept').length, 2);
  });

  test('норвежские буквы доживают до файла', () {
    final xml = GpxBuilder.waypoints(
      name: 'Избранное',
      places: [
        makePlace(id: '1', name: 'Vøringsfossen', lat: 60.4267, lon: 7.2506),
        makePlace(id: '2', name: 'Nærøyfjorden', lat: 60.9167, lon: 6.9333),
        makePlace(id: '3', name: 'Trollstigen', lat: 62.4575, lon: 7.6708),
      ],
    );

    final doc = XmlDocument.parse(xml);
    final names = doc
        .findAllElements('wpt')
        .map((w) => w.findElements('name').first.innerText)
        .toList();
    expect(names, contains('Vøringsfossen'));
    expect(names, contains('Nærøyfjorden'));
  });

  test('служебные символы экранируются, а не ломают файл', () {
    // Такие названия реально встречаются: «Bryggen & Hanseatic Museum»,
    // кавычки в описаниях с Wikipedia.
    final xml = GpxBuilder.waypoints(
      name: 'Список & проверка',
      places: [
        makePlace(
          id: '1',
          name: 'Музей "Фрам" & Ко',
          lat: 59.9,
          lon: 10.7,
          summary: 'Описание с <тегами> и «кавычками»',
        ),
      ],
    );

    // Главное: файл остаётся разбираемым.
    final doc = XmlDocument.parse(xml);
    final name = doc.findAllElements('wpt').first.findElements('name').first;
    // И текст восстанавливается ровно тем, чем был.
    expect(name.innerText, 'Музей "Фрам" & Ко');

    final desc = doc.findAllElements('desc').last;
    expect(desc.innerText, contains('<тегами>'));
  });

  test('порядок остановок сохраняется и пронумерован', () {
    final xml = GpxBuilder.route(
      name: 'Маршрут',
      stops: [
        makePlace(id: '1', name: 'Первое', lat: 60.0, lon: 5.0),
        makePlace(id: '2', name: 'Второе', lat: 60.1, lon: 5.1),
        makePlace(id: '3', name: 'Третье', lat: 60.2, lon: 5.2),
      ],
    );

    final doc = XmlDocument.parse(xml);
    final names = doc
        .findAllElements('wpt')
        .map((w) => w.findElements('name').first.innerText)
        .toList();
    expect(names, ['1. Первое', '2. Второе', '3. Третье']);

    // В rte порядок тот же, но без номеров: их рисует сам навигатор.
    final rte = doc
        .findAllElements('rtept')
        .map((w) => w.findElements('name').first.innerText)
        .toList();
    expect(rte, ['Первое', 'Второе', 'Третье']);
  });

  test('координаты пишутся с точкой, а не запятой', () {
    // Локаль устройства не должна влиять на формат файла: навигатор
    // с «60,3975» откажется его читать.
    final xml = GpxBuilder.waypoints(
      name: 'Точка',
      places: [makePlace(id: '1', name: 'Bergen', lat: 60.3975, lon: 5.3242)],
    );

    final wpt = XmlDocument.parse(xml).findAllElements('wpt').first;
    expect(wpt.getAttribute('lat'), '60.397500');
    expect(wpt.getAttribute('lon'), '5.324200');
  });

  test('трека в файле нет', () {
    // Трек — это записанный путь по дорогам. У нас порядок точек, и
    // выдавать прямые отрезки за трек значило бы наврать про маршрут,
    // который навигатор честно попытается повторить.
    final xml = GpxBuilder.route(
      name: 'Маршрут',
      stops: [
        makePlace(id: '1', name: 'A', lat: 60.0, lon: 5.0),
        makePlace(id: '2', name: 'B', lat: 60.1, lon: 5.1),
      ],
    );
    expect(XmlDocument.parse(xml).findAllElements('trk'), isEmpty);
  });
}
