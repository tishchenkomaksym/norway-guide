/// Справочник населённых пунктов Норвегии для ручного указания положения.
///
/// Нужен, потому что GPS доступен не всегда: на десктопе его может не быть
/// вовсе, разрешение может быть не выдано, а в помещении определение бывает
/// неточным. Пользователь просто пишет, где он находится.
///
/// Это отдельный справочник, а не таблица `cities` из контентной базы:
/// он нужен до того, как база наполнена, и содержит альтернативные написания
/// на русском и английском, чтобы поиск работал независимо от раскладки.
class KnownPlace {
  const KnownPlace(this.name, this.lat, this.lon, this.aliases);

  final String name;
  final double lat;
  final double lon;

  /// Написания на других языках и распространённые варианты.
  final List<String> aliases;

  /// Совпадает ли запрос с этим местом. Регистр и диакритика игнорируются.
  bool matches(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return false;
    if (_normalize(name).contains(q)) return true;
    return aliases.any((a) => _normalize(a).contains(q));
  }
}

/// Приводит строку к виду, удобному для сравнения: нижний регистр и
/// норвежские буквы, разложенные в латиницу — «Ålesund» находится и по «alesund».
String _normalize(String s) {
  const map = {
    'å': 'a', 'æ': 'ae', 'ø': 'o', 'ä': 'a', 'ö': 'o', 'ü': 'u', 'é': 'e',
  };
  final lower = s.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final ch in lower.split('')) {
    buffer.write(map[ch] ?? ch);
  }
  return buffer.toString();
}

const knownPlaces = <KnownPlace>[
  KnownPlace('Oslo', 59.9139, 10.7522, ['Осло']),
  KnownPlace('Bergen', 60.3913, 5.3221, ['Берген']),
  KnownPlace('Trondheim', 63.4305, 10.3951, ['Тронхейм']),
  KnownPlace('Stavanger', 58.9700, 5.7331, ['Ставангер']),
  KnownPlace('Tromsø', 69.6492, 18.9553, ['Тромсё', 'Tromso', 'Тромсе']),
  KnownPlace('Ålesund', 62.4722, 6.1495, ['Олесунн', 'Alesund']),
  KnownPlace('Bodø', 67.2804, 14.4049, ['Будё', 'Bodo', 'Буде']),
  KnownPlace('Kristiansand', 58.1467, 7.9956, ['Кристиансанн']),
  KnownPlace('Drammen', 59.7440, 10.2045, ['Драммен']),
  KnownPlace('Fredrikstad', 59.2181, 10.9298, ['Фредрикстад']),
  KnownPlace('Sandnes', 58.8524, 5.7352, ['Саннес']),
  KnownPlace('Molde', 62.7375, 7.1591, ['Молде']),
  KnownPlace('Haugesund', 59.4136, 5.2680, ['Хаугесунн']),
  KnownPlace('Tønsberg', 59.2675, 10.4076, ['Тёнсберг', 'Tonsberg']),
  KnownPlace('Lillehammer', 61.1153, 10.4662, ['Лиллехаммер']),
  KnownPlace('Hamar', 60.7945, 11.0680, ['Хамар']),
  KnownPlace('Narvik', 68.4385, 17.4272, ['Нарвик']),
  KnownPlace('Alta', 69.9689, 23.2717, ['Алта']),
  KnownPlace('Kirkenes', 69.7273, 30.0450, ['Киркенес']),
  KnownPlace('Harstad', 68.7986, 16.5416, ['Харстад']),
  KnownPlace('Svolvær', 68.2342, 14.5681, ['Свольвер', 'Svolvar']),
  KnownPlace('Flåm', 60.8628, 7.1136, ['Флом', 'Flam']),
  KnownPlace('Geiranger', 62.1010, 7.2050, ['Гейрангер']),
  KnownPlace('Voss', 60.6294, 6.4136, ['Восс']),
  KnownPlace('Odda', 60.0670, 6.5460, ['Одда']),
  KnownPlace('Røros', 62.5748, 11.3843, ['Рёрос', 'Roros']),
  KnownPlace('Trysil', 61.3145, 12.2617, ['Трюсиль']),
  KnownPlace('Longyearbyen', 78.2232, 15.6267, ['Лонгйир', 'Свальбард']),
  KnownPlace('Åndalsnes', 62.5675, 7.6874, ['Ондалснес', 'Andalsnes']),
  KnownPlace('Kristiansund', 63.1105, 7.7280, ['Кристиансунн']),
  KnownPlace('Lofoten', 68.2000, 13.7000, ['Лофотены', 'Лофотен']),
  KnownPlace('Nordkapp', 71.1710, 25.7845, ['Нордкап', 'Норткап']),
  KnownPlace('Sogndal', 61.2308, 7.1003, ['Согндал']),
  KnownPlace('Førde', 61.4522, 5.8570, ['Фёрде', 'Forde']),
  KnownPlace('Arendal', 58.4616, 8.7724, ['Арендал']),
  KnownPlace('Bryne', 58.7356, 5.6461, ['Брюне']),
  KnownPlace('Gjøvik', 60.7957, 10.6915, ['Йёвик', 'Gjovik']),
  KnownPlace('Halden', 59.1230, 11.3875, ['Хальден']),
  KnownPlace('Mo i Rana', 66.3128, 14.1428, ['Му-и-Рана']),
  KnownPlace('Steinkjer', 64.0148, 11.4954, ['Стейнхьер']),
];

/// Ищет места по строке запроса. Пустой запрос возвращает крупнейшие города.
List<KnownPlace> searchPlaces(String query) {
  if (query.trim().isEmpty) return knownPlaces.take(8).toList();
  return knownPlaces.where((p) => p.matches(query)).toList();
}
