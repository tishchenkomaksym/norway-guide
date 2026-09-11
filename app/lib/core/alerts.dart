import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

/// Официальные предупреждения об опасной погоде.
///
/// Источник — Норвежский метеорологический институт (MET Norway), тот же,
/// что стоит за yr.no. Данные государственные, под свободной лицензией
/// NLOD с обязательной атрибуцией. Это единственный вид сведений в
/// приложении, который обязан быть свежим: предупреждение о шторме
/// недельной давности хуже бесполезного.
///
/// Почему это не противоречит офлайновой природе приложения. Всё остальное
/// работает без сети, и так и останется. Предупреждения — надстройка: есть
/// связь, человек видит, что на побережье штормовой ветер; нет связи —
/// приложение работает как прежде, молча. Ради них ничего не качается
/// в фоне и не будит телефон.
///
/// Чего здесь намеренно нет: собственных выводов и пересказа. Мы показываем
/// текст метеоинститута и ссылку на met.no, не решая за человека, можно ли
/// идти на Тролльтунгу. Приложение, которое скажет «всё в порядке», а
/// человек попадёт в шторм, хуже приложения, которое молчит.

/// Уровень опасности по европейской шкале.
enum AlertLevel {
  /// Жёлтый: будьте внимательны.
  yellow,

  /// Оранжевый: опасно, готовьтесь.
  orange,

  /// Красный: очень опасно, действуйте.
  red;

  static AlertLevel parse(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('red')) return AlertLevel.red;
    if (value.contains('orange')) return AlertLevel.orange;
    return AlertLevel.yellow;
  }
}

/// Откуда пришло предупреждение. Нужен, чтобы подписать источник: человек
/// должен знать, кому верить и где перепроверить.
enum AlertSource {
  /// Метеорологический институт: ветер, дождь, снег, гроза.
  met,

  /// NVE (Varsom): лавинная опасность в горах.
  avalanche,
}

@immutable
class WeatherAlert {
  const WeatherAlert({
    required this.id,
    required this.event,
    required this.area,
    required this.level,
    required this.description,
    this.instruction,
    this.consequences,
    this.endsAt,
    this.web,
    this.marine = false,
    this.source = AlertSource.met,
  });

  final String id;

  /// Человеческое название: «Gale», «Heavy rain», «Snow».
  final String event;
  final String area;
  final AlertLevel level;
  final String description;

  /// Что делать. Метеоинститут пишет это сам, мы не сочиняем.
  final String? instruction;
  final String? consequences;
  final DateTime? endsAt;
  final String? web;

  /// Предупреждение для моря, а не для суши. Турист на берегу не должен
  /// пугаться штормового ветра, объявленного для лодок в открытом море.
  final bool marine;

  final AlertSource source;

  bool get isExpired =>
      endsAt != null && endsAt!.isBefore(DateTime.now().toUtc());

  factory WeatherAlert.fromFeature(Map<String, dynamic> feature) {
    final p = feature['properties'] as Map<String, dynamic>;
    return WeatherAlert(
      id: p['id'] as String? ?? '',
      event: p['eventAwarenessName'] as String? ?? p['event'] as String? ?? '',
      area: p['area'] as String? ?? '',
      level: AlertLevel.parse(p['awareness_level'] as String? ?? ''),
      description: p['description'] as String? ?? '',
      instruction: p['instruction'] as String?,
      consequences: p['consequences'] as String?,
      endsAt: DateTime.tryParse(p['eventEndingTime'] as String? ?? ''),
      web: p['web'] as String?,
      marine: (p['geographicDomain'] as String?) == 'marine',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event': event,
    'area': area,
    'level': level.name,
    'description': description,
    'instruction': instruction,
    'consequences': consequences,
    'endsAt': endsAt?.toIso8601String(),
    'web': web,
    'marine': marine,
    'source': source.name,
  };

  factory WeatherAlert.fromJson(Map<String, dynamic> json) => WeatherAlert(
    id: json['id'] as String? ?? '',
    event: json['event'] as String? ?? '',
    area: json['area'] as String? ?? '',
    level: AlertLevel.values.firstWhere(
      (l) => l.name == json['level'],
      orElse: () => AlertLevel.yellow,
    ),
    description: json['description'] as String? ?? '',
    instruction: json['instruction'] as String?,
    consequences: json['consequences'] as String?,
    endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
    web: json['web'] as String?,
    marine: json['marine'] as bool? ?? false,
    source: AlertSource.values.firstWhere(
      (s) => s.name == json['source'],
      orElse: () => AlertSource.met,
    ),
  );
}

const _cacheKey = 'alerts.cache';
const _cacheTimeKey = 'alerts.cachedAt';

/// Предупреждения для текущего положения человека.
///
/// Без координат запроса не делаем вовсе: предупреждения по всей стране
/// не нужны никому — в Норвегии почти всегда где-нибудь штормит, и такой
/// список только приучит не обращать внимания.
final weatherAlertsProvider = FutureProvider<List<WeatherAlert>>((ref) async {
  final prefs = ref.watch(prefsProvider);

  final manual = ref.watch(mockPositionProvider);
  final position = ref.watch(positionProvider).valueOrNull?.position;

  final lat = manual?.lat ?? position?.latitude;
  final lon = manual?.lon ?? position?.longitude;
  if (lat == null || lon == null) return const [];

  // Язык: метеоинститут отдаёт тексты только на норвежском и английском.
  // Для остальных наших локалей берём английский — он понятнее туристу,
  // чем норвежский, и переводить предупреждения самим нельзя: это
  // официальный текст, за точность которого отвечает институт.
  final lang = ref.watch(languageProvider) == 'no' ? 'no' : 'en';

  try {
    final uri = Uri.parse(
      'https://api.met.no/weatherapi/metalerts/2.0/current.json'
      '?lat=${lat.toStringAsFixed(4)}&lon=${lon.toStringAsFixed(4)}&lang=$lang',
    );
    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return _readCache(prefs);

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final alerts = (data['features'] as List<dynamic>? ?? [])
        .map((f) => WeatherAlert.fromFeature(f as Map<String, dynamic>))
        .where((a) => !a.isExpired)
        .toList();

    // Лавины — отдельная служба и отдельный запрос. Объединяем в один
    // список: человеку всё равно, какое ведомство объявило опасность,
    // ему важно, что в горах сегодня опасно.
    final avalanche = await _fetchAvalanche(lat, lon, lang);
    final all = [...alerts, ...avalanche];

    await _writeCache(prefs, all);
    return all;
  } catch (_) {
    // Нет сети — показываем то, что успели получить раньше, если оно ещё
    // не истекло. Предупреждение с истёкшим сроком отбрасывается: пугать
    // вчерашним штормом хуже, чем не сказать ничего.
    return _readCache(prefs);
  }
});

/// Лавинная опасность от NVE (varsom.no).
///
/// Зачем отдельно от погоды. Лавины объявляет не метеоинститут, а
/// Управление водных ресурсов и энергетики — другое ведомство, другая
/// шкала, другой API. Для человека это одна и та же опасность, поэтому
/// в приложении они объединены в один список, но источник у каждого
/// предупреждения подписан свой.
///
/// Работает только зимой и только в горах: летом служба не публикует
/// прогнозов, и пустой ответ здесь — норма, а не сбой. Приложением
/// пользуются в основном летом, так что чаще всего этот запрос вернёт
/// пустоту, и это правильно.
///
/// Шкала лавинной опасности европейская, от 1 до 5. Третий уровень
/// («значительная») — тот, на котором в Норвегии происходит большинство
/// несчастных случаев: люди считают его умеренным, хотя это не так.
/// Поэтому 3 и выше показываем как оранжевый, 4–5 как красный.
Future<List<WeatherAlert>> _fetchAvalanche(
  double lat,
  double lon,
  String lang,
) async {
  try {
    // API различает языки числом: 1 — норвежский, 2 — английский.
    final langKey = lang == 'no' ? 1 : 2;
    final today = DateTime.now();
    final from = _date(today);
    final to = _date(today.add(const Duration(days: 1)));

    final uri = Uri.parse(
      'https://api01.nve.no/hydrology/forecast/avalanche/v6.3.0/api'
      '/AvalancheWarningByCoordinates/Simple'
      '/${lat.toStringAsFixed(4)}/${lon.toStringAsFixed(4)}'
      '/$langKey/$from/$to',
    );
    final response = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];

    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return list
        .map((e) => e as Map<String, dynamic>)
        .where((w) => (w['DangerLevel'] as int? ?? 0) >= 2)
        .map((w) {
          final level = w['DangerLevel'] as int? ?? 0;
          return WeatherAlert(
            id: 'avalanche-${w['RegId']}',
            event: 'Avalanche danger $level/5',
            area: w['RegionName'] as String? ?? '',
            level: level >= 4
                ? AlertLevel.red
                : level >= 3
                ? AlertLevel.orange
                : AlertLevel.yellow,
            description: w['MainText'] as String? ?? '',
            endsAt: DateTime.tryParse(w['ValidTo'] as String? ?? ''),
            web: 'https://www.varsom.no/',
            source: AlertSource.avalanche,
          );
        })
        .toList();
  } catch (_) {
    // Лавинная служба недоступна — это не повод терять погодные
    // предупреждения, которые уже получены.
    return const [];
  }
}

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}'
    '-${value.day.toString().padLeft(2, '0')}';

/// Требование лицензии MET: запросы обязаны представляться.
const _userAgent =
    'NorwayExplore/0.1 (offline Norway guide; github.com/tishchenkomaksym/norway-guide)';

Future<void> _writeCache(SharedPreferences prefs, List<WeatherAlert> alerts) {
  prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  return prefs.setString(
    _cacheKey,
    jsonEncode(alerts.map((a) => a.toJson()).toList()),
  );
}

List<WeatherAlert> _readCache(SharedPreferences prefs) {
  try {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => WeatherAlert.fromJson(e as Map<String, dynamic>))
        .where((a) => !a.isExpired)
        .toList();
  } catch (_) {
    return const [];
  }
}

/// Когда сведения получены. Показывается рядом с предупреждением: человек
/// должен понимать, смотрит он на свежее или на сохранённое час назад.
final alertsFetchedAtProvider = Provider<DateTime?>((ref) {
  final ms = ref.watch(prefsProvider).getInt(_cacheTimeKey);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
});
