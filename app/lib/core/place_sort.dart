import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'categories.dart';
import '../data/database.dart';

/// Чем упорядочен список мест.
///
/// Порядок по умолчанию разный на разных экранах, и это не небрежность.
/// На «Рядом со мной» человек спрашивает «что вокруг», и расстояние там
/// главное. В городе и в обзоре страны расстояния нет вовсе, и первым
/// должно идти то, ради чего вообще едут.
enum PlaceSort {
  /// От самых известных: ЮНЕСКО и топ впереди.
  rating,

  /// От ближайшего. Доступна только там, где расстояние посчитано.
  distance,

  /// По алфавиту — когда человек ищет конкретное название глазами.
  name,
}

/// Выбранный порядок. Общий на приложение: человек, переключивший
/// сортировку в городе, ожидает её же в обзоре страны.
final placeSortProvider = StateProvider<PlaceSort>((ref) => PlaceSort.rating);

/// Возвращает новый список в нужном порядке.
///
/// Копия, а не сортировка на месте: исходный список приходит из провайдера
/// и может быть общим для нескольких экранов — перемешать его значит
/// незаметно поменять порядок и там.
List<PlaceWithText> sortPlaces(List<PlaceWithText> places, PlaceSort sort) {
  final result = [...places];

  switch (sort) {
    case PlaceSort.rating:
      result.sort((a, b) {
        // Сначала звёзды — та самая шкала внешнего признания.
        final sa =
            ratingStars(
              unesco: a.place.unesco == 1,
              topRank: a.place.topRank,
              langCount: a.langCount,
            ) ??
            0;
        final sb =
            ratingStars(
              unesco: b.place.unesco == 1,
              topRank: b.place.topRank,
              langCount: b.langCount,
            ) ??
            0;
        if (sa != sb) return sb.compareTo(sa);

        // При равных звёздах — место в курируемом топе. Иначе десятки
        // мест с четырьмя звёздами выстроились бы в случайном порядке.
        final ta = a.place.topRank == 0 ? 999 : a.place.topRank;
        final tb = b.place.topRank == 0 ? 999 : b.place.topRank;
        if (ta != tb) return ta.compareTo(tb);

        // И только потом полнота разметки: она плохой мерой известности,
        // но сносной — для разрешения ничьих.
        return b.place.importance.compareTo(a.place.importance);
      });

    case PlaceSort.distance:
      result.sort((a, b) {
        final da = a.distanceMeters;
        final db = b.distanceMeters;
        // Места без расстояния уходят в конец, а не наверх: иначе при
        // потере GPS список молча перевернулся бы.
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    case PlaceSort.name:
      // Сравнение с учётом регистра и норвежских букв: «Ålesund» должен
      // оказаться в конце, как в норвежском алфавите, а не в начале
      // по коду символа.
      result.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }

  return result;
}
