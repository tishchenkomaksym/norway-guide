import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';

/// Настройки, которые переживают перезапуск приложения.
///
/// Здесь только то, что выбрал сам человек: язык, город и интересы.
/// Всё остальное — контент — приходит из базы и перевыбирается заново.
///
/// Хранилище открывается в `main()` до запуска приложения и подставляется
/// через `overrideWithValue`. Это позволяет провайдерам читать значения
/// синхронно: иначе экран сначала отрисовался бы с языком по умолчанию,
/// а через мгновение перестроился с сохранённым — заметное мигание.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'prefsProvider должен быть переопределён в main() — '
    'см. overrideWithValue при создании ProviderScope',
  );
});

class _Keys {
  static const language = 'settings.language';
  static const cityName = 'settings.city.name';
  static const cityLat = 'settings.city.lat';
  static const cityLon = 'settings.city.lon';
  static const interests = 'profile.interests';
  static const travelTime = 'profile.travelTime';
  static const profileAnswered = 'profile.answered';
  static const autoDownloadWifi = 'settings.autoDownloadWifi';
  static const offeredRegions = 'settings.offeredRegions';
}

/// Языки, на которых говорит приложение (§8.2 спеки).
const supportedLanguages = ['en', 'no', 'de', 'es', 'ru', 'zh'];

/// Приводит локаль системы к одному из поддерживаемых языков.
///
/// Сопоставление по коду без региона: `de-AT` → `de`, `zh-Hans-CN` → `zh`.
/// Норвежские `nb` (букмол) и `nn` (нюнорск) оба ведут на `no` — иначе
/// половина норвежских телефонов получит английский в приложении о Норвегии.
String resolveLanguage(ui.Locale locale) {
  final code = locale.languageCode.toLowerCase();
  if (code == 'nb' || code == 'nn' || code == 'no') return 'no';
  if (supportedLanguages.contains(code)) return code;
  return 'en';
}

/// Язык интерфейса.
///
/// Выбор пользователя имеет приоритет над языком системы и переживает
/// перезапуск. Если пользователь ничего не выбирал, каждый раз берётся
/// язык системы — то есть смена языка телефона подхватывается.
class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences _prefs;

  static String _initial(SharedPreferences prefs) {
    final saved = prefs.getString(_Keys.language);
    if (saved != null && supportedLanguages.contains(saved)) return saved;
    return resolveLanguage(WidgetsBinding.instance.platformDispatcher.locale);
  }

  void set(String language) {
    state = language;
    _prefs.setString(_Keys.language, language);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.watch(prefsProvider));
});

/// Точка на карте с названием — для указанного вручную положения.
typedef NamedPoint = ({String name, double lat, double lon});

/// Положение, указанное пользователем вручную. null — использовать GPS.
///
/// Сохраняется, потому что выбор города — это ответ на вопрос, который
/// приложение задало один раз. Спрашивать его при каждом запуске значило бы
/// не помнить сказанного.
class ManualPositionNotifier extends StateNotifier<NamedPoint?> {
  ManualPositionNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences _prefs;

  static NamedPoint? _initial(SharedPreferences prefs) {
    final name = prefs.getString(_Keys.cityName);
    final lat = prefs.getDouble(_Keys.cityLat);
    final lon = prefs.getDouble(_Keys.cityLon);
    if (name == null || lat == null || lon == null) return null;
    return (name: name, lat: lat, lon: lon);
  }

  void set(NamedPoint? point) {
    state = point;
    if (point == null) {
      _prefs.remove(_Keys.cityName);
      _prefs.remove(_Keys.cityLat);
      _prefs.remove(_Keys.cityLon);
      return;
    }
    _prefs.setString(_Keys.cityName, point.name);
    _prefs.setDouble(_Keys.cityLat, point.lat);
    _prefs.setDouble(_Keys.cityLon, point.lon);
  }
}

final mockPositionProvider =
    StateNotifierProvider<ManualPositionNotifier, NamedPoint?>((ref) {
      return ManualPositionNotifier(ref.watch(prefsProvider));
    });

/// Профиль интересов, переживающий перезапуск.
///
/// Флаг «уже спрашивали» тоже сохраняется, и это важнее самих интересов:
/// без него приложение задавало бы один и тот же вопрос при каждом запуске,
/// хотя человек однажды его закрыл.
class PersistentProfileNotifier extends StateNotifier<UserProfile> {
  PersistentProfileNotifier(this._prefs) : super(_initial(_prefs));

  final SharedPreferences _prefs;

  static UserProfile _initial(SharedPreferences prefs) {
    final ids = prefs.getStringList(_Keys.interests)?.toSet() ?? <String>{};
    final timeIndex = prefs.getInt(_Keys.travelTime);
    return UserProfile(
      interestIds: ids,
      travelTime: timeIndex == null || timeIndex >= TravelTime.values.length
          ? null
          : TravelTime.values[timeIndex],
      answered: prefs.getBool(_Keys.profileAnswered) ?? false,
    );
  }

  void _save(UserProfile profile) {
    _prefs.setStringList(_Keys.interests, profile.interestIds.toList());
    _prefs.setBool(_Keys.profileAnswered, profile.answered);
    if (profile.travelTime != null) {
      _prefs.setInt(_Keys.travelTime, profile.travelTime!.index);
    }
  }

  void toggleInterest(String id) {
    final next = Set<String>.from(state.interestIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(interestIds: next);
    _save(state);
  }

  void setTravelTime(TravelTime time) {
    state = state.copyWith(travelTime: time);
    _save(state);
  }

  void markAnswered() {
    state = state.copyWith(answered: true);
    _save(state);
  }

  void reset() {
    state = const UserProfile();
    _prefs.remove(_Keys.interests);
    _prefs.remove(_Keys.travelTime);
    _prefs.remove(_Keys.profileAnswered);
  }
}

final profileProvider =
    StateNotifierProvider<PersistentProfileNotifier, UserProfile>((ref) {
      return PersistentProfileNotifier(ref.watch(prefsProvider));
    });

/// Скачивать регион автоматически, когда есть Wi-Fi.
///
/// По умолчанию выключено, и это не осторожность ради осторожности.
/// Турист в Норвегии чаще всего в роуминге: списать у него двадцать
/// мегабайт без спроса — реальные деньги и одна звезда в сторе. Даже
/// с включённой настройкой мобильный трафик не трогается никогда,
/// только Wi-Fi.
class AutoDownloadNotifier extends StateNotifier<bool> {
  AutoDownloadNotifier(this._prefs)
    : super(_prefs.getBool(_Keys.autoDownloadWifi) ?? false);

  final SharedPreferences _prefs;

  void set(bool value) {
    state = value;
    _prefs.setBool(_Keys.autoDownloadWifi, value);
  }
}

final autoDownloadWifiProvider =
    StateNotifierProvider<AutoDownloadNotifier, bool>((ref) {
      return AutoDownloadNotifier(ref.watch(prefsProvider));
    });

/// Регионы, которые уже предлагали скачать.
///
/// Предложение показывается один раз на регион. Человек, отказавшийся
/// качать фотографии Фьордов, не должен видеть ту же полосу при каждом
/// открытии приложения всю поездку.
class OfferedRegionsNotifier extends StateNotifier<Set<String>> {
  OfferedRegionsNotifier(this._prefs)
    : super((_prefs.getStringList(_Keys.offeredRegions) ?? const []).toSet());

  final SharedPreferences _prefs;

  void markOffered(String regionId) {
    if (state.contains(regionId)) return;
    state = {...state, regionId};
    _prefs.setStringList(_Keys.offeredRegions, state.toList());
  }

  /// Забыть отказы — нужно в настройках, если человек передумал.
  void reset() {
    state = {};
    _prefs.remove(_Keys.offeredRegions);
  }
}

final offeredRegionsProvider =
    StateNotifierProvider<OfferedRegionsNotifier, Set<String>>((ref) {
      return OfferedRegionsNotifier(ref.watch(prefsProvider));
    });
