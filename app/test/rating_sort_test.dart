import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/core/categories.dart';
import 'package:nordguide/core/place_sort.dart';
import 'package:nordguide/data/database.dart';

/// Шкала известности и порядок списков.
///
/// Раньше звёзды считались из `importance`, а в него входит полнота
/// разметки в OpenStreetMap. Получалось, что городской музей с сайтом
/// и часами работы обгонял горное озеро редкой красоты, у которого два
/// тега. Человек читает звёзды как «насколько тут хорошо», и это было
/// враньём по существу.
///
/// Тест закрепляет новое правило: в счёт идёт только признание извне —
/// ЮНЕСКО, курируемый топ и число языков, на которых о месте написали.
void main() {
  PlaceWithText place({
    required String id,
    required String name,
    int unesco = 0,
    int topRank = 0,
    int langCount = 0,
    int importance = 50,
    double? distance,
  }) {
    return PlaceWithText(
      place: Place(
        id: id,
        regionId: 'r',
        category: 'museum',
        nameNo: name,
        lat: 60,
        lon: 5,
        importance: importance,
        topRank: topRank,
        visitors: 0,
        visitorsYear: 0,
        unesco: unesco,
      ),
      name: name,
      summary: null,
      isFallback: false,
      langCount: langCount,
      distanceMeters: distance,
    );
  }

  group('звёзды', () {
    test('ЮНЕСКО даёт пять', () {
      expect(ratingStars(unesco: true, topRank: 0, langCount: 0), 5);
    });

    test('первая десятка топа даёт пять', () {
      expect(ratingStars(unesco: false, topRank: 3, langCount: 1), 5);
      expect(ratingStars(unesco: false, topRank: 10, langCount: 1), 5);
    });

    test('остальной топ и три языка дают четыре', () {
      expect(ratingStars(unesco: false, topRank: 15, langCount: 1), 4);
      expect(ratingStars(unesco: false, topRank: 0, langCount: 3), 4);
    });

    test('полнота разметки больше ни на что не влияет', () {
      // Место с максимальной значимостью, но без внешнего признания
      // и без описаний, звёзд не получает вовсе.
      expect(ratingStars(unesco: false, topRank: 0, langCount: 0), isNull);
    });

    test('отсутствие звёзд означает «не знаем», а не «плохо»', () {
      expect(ratingStars(unesco: false, topRank: 0, langCount: 0), isNull);
      expect(ratingStars(unesco: false, topRank: 0, langCount: 1), 2);
    });
  });

  group('порядок', () {
    test('по известности: ЮНЕСКО и топ впереди', () {
      final list = [
        place(id: '1', name: 'Обычное', langCount: 1, importance: 95),
        place(id: '2', name: 'ЮНЕСКО', unesco: 1, langCount: 1),
        place(id: '3', name: 'Топ-20', topRank: 20, langCount: 2),
      ];

      final sorted = sortPlaces(list, PlaceSort.rating);
      expect(sorted.map((p) => p.name), ['ЮНЕСКО', 'Топ-20', 'Обычное']);
    });

    test('высокая значимость не обгоняет известность', () {
      // Ровно тот случай, ради которого шкала переписана: подробно
      // размеченный музей против места с описаниями на трёх языках.
      final list = [
        place(id: '1', name: 'Музей с тегами', importance: 99, langCount: 1),
        place(id: '2', name: 'Известное место', importance: 50, langCount: 3),
      ];

      final sorted = sortPlaces(list, PlaceSort.rating);
      expect(sorted.first.name, 'Известное место');
    });

    test('по расстоянию: места без координат уходят в конец', () {
      // Иначе при потере GPS список молча перевернулся бы.
      final list = [
        place(id: '1', name: 'Далеко', distance: 5000),
        place(id: '2', name: 'Неизвестно'),
        place(id: '3', name: 'Близко', distance: 100),
      ];

      final sorted = sortPlaces(list, PlaceSort.distance);
      expect(sorted.map((p) => p.name), ['Близко', 'Далеко', 'Неизвестно']);
    });

    test('по названию — без учёта регистра', () {
      final list = [
        place(id: '1', name: 'вøringsfossen'),
        place(id: '2', name: 'Bryggen'),
        place(id: '3', name: 'akershus'),
      ];

      final sorted = sortPlaces(list, PlaceSort.name);
      expect(sorted.first.name, 'akershus');
    });

    test('сортировка не портит исходный список', () {
      // Список приходит из провайдера и может быть общим для нескольких
      // экранов: перемешать его значит незаметно поменять порядок и там.
      final list = [
        place(id: '1', name: 'Б', langCount: 1),
        place(id: '2', name: 'А', unesco: 1),
      ];
      final before = list.map((p) => p.name).toList();

      sortPlaces(list, PlaceSort.rating);
      expect(list.map((p) => p.name), before);
    });
  });
}
