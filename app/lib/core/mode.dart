import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';
import 'settings.dart';

/// Режим приложения — под кого подстроена выдача.
///
/// По умолчанию приложение туристическое: города, виды, музеи. Рыбалка
/// и охота — отдельные режимы, потому что у них другая задача: не «что
/// посмотреть», а «где ловить и по каким правилам». Показывать рыбаку
/// список музеев вперемешку с озёрами — значит не помочь ни тому, ни
/// другому.
///
/// Режим включается сам, если человек отметил соответствующий интерес,
/// но переключить его можно всегда: тот, кто выбрал и рыбалку, и музеи,
/// не должен терять музеи.
enum AppMode {
  tourist,
  fishing,
  hunting;

  /// Категории, которые показываются в этом режиме.
  /// Пустой список означает «все».
  List<String> get categories {
    switch (this) {
      case AppMode.fishing:
        return const ['lake', 'river', 'fjord', 'beach'];
      case AppMode.hunting:
        // Охота не привязана к категориям мест: угодья не размечены
        // на карте. Показываем природу, а главное на экране — правила
        // и коммуна.
        return const ['hike', 'lake', 'river'];
      case AppMode.tourist:
        return const [];
    }
  }

  /// Соответствующий интерес в профиле.
  String? get interestId {
    switch (this) {
      case AppMode.fishing:
        return 'fishing';
      case AppMode.hunting:
        return 'hunting';
      case AppMode.tourist:
        return null;
    }
  }

  /// Вид деятельности для экрана правил.
  String? get activity {
    switch (this) {
      case AppMode.fishing:
        return 'fishing';
      case AppMode.hunting:
        return 'hunting';
      case AppMode.tourist:
        return null;
    }
  }
}

const _modeKey = 'app.mode';

class ModeNotifier extends StateNotifier<AppMode> {
  ModeNotifier(this._prefs, UserProfile profile)
    : super(_initial(_prefs, profile));

  final SharedPreferences _prefs;

  /// Начальный режим: сохранённый выбор, иначе выводится из профиля.
  ///
  /// Если человек отметил и рыбалку, и охоту, побеждает рыбалка — она
  /// привязана к конкретным местам, а охота к территории, и показать
  /// первой полезнее ту, где есть что показывать.
  static AppMode _initial(SharedPreferences prefs, UserProfile profile) {
    final saved = prefs.getString(_modeKey);
    if (saved != null) {
      for (final m in AppMode.values) {
        if (m.name == saved) return m;
      }
    }
    if (profile.interestIds.contains('fishing')) return AppMode.fishing;
    if (profile.interestIds.contains('hunting')) return AppMode.hunting;
    return AppMode.tourist;
  }

  void set(AppMode mode) {
    state = mode;
    _prefs.setString(_modeKey, mode.name);
  }
}

final modeProvider = StateNotifierProvider<ModeNotifier, AppMode>((ref) {
  return ModeNotifier(ref.watch(prefsProvider), ref.watch(profileProvider));
});

/// Режимы, доступные человеку: туристический всегда плюс те, что он
/// отметил в интересах.
///
/// Не показываем переключатель на охоту тому, кто про охоту не спрашивал:
/// лишний пункт в интерфейсе стоит дороже, чем кажется.
final availableModesProvider = Provider<List<AppMode>>((ref) {
  final profile = ref.watch(profileProvider);
  return [
    AppMode.tourist,
    for (final m in [AppMode.fishing, AppMode.hunting])
      if (profile.interestIds.contains(m.interestId)) m,
  ];
});
