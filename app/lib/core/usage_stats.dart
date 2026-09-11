import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';

/// Счётчик использования — полностью локальный.
///
/// Зачем он есть. Через полгода после выпуска придётся решать, что делать
/// с приложением: что развивать, стоит ли делать карту платной, нужна ли
/// реклама. Без чисел это решается вслепую, по ощущениям и отзывам самых
/// недовольных.
///
/// Чего здесь нет и не будет. Ничего не отправляется наружу: ни сюда,
/// ни в аналитику, ни куда-либо ещё. Все цифры лежат на телефоне человека
/// и видны только ему — в настройках есть экран, где можно посмотреть
/// и стереть их.
///
/// Это осознанное ограничение, а не недоделка. Приложение обещает, что
/// местоположение не покидает устройство, и тайком собирать статистику
/// поверх такого обещания нельзя. К тому же локальный счётчик не требует
/// ни согласия по GDPR, ни деклараций в сторах.
class UsageStats {
  const UsageStats({
    required this.launches,
    required this.placesOpened,
    required this.routesOpened,
    required this.searches,
    required this.packsDownloaded,
    required this.firstLaunch,
  });

  final int launches;
  final int placesOpened;
  final int routesOpened;
  final int searches;
  final int packsDownloaded;

  /// Когда приложением воспользовались впервые. Нужно, чтобы понимать,
  /// «сорок запусков» — это за неделю или за год.
  final DateTime? firstLaunch;

  int get daysSinceFirst {
    if (firstLaunch == null) return 0;
    return DateTime.now().difference(firstLaunch!).inDays;
  }
}

class _Keys {
  static const launches = 'stats.launches';
  static const places = 'stats.places';
  static const routes = 'stats.routes';
  static const searches = 'stats.searches';
  static const packs = 'stats.packs';
  static const firstLaunch = 'stats.firstLaunch';
}

/// Что именно считаем.
///
/// Список короткий намеренно: каждое событие должно отвечать на вопрос,
/// который реально возникнет. «Открыли карточку места» отвечает на «чем
/// пользуются», «скачали пакет» — на «готовы ли вообще что-то качать».
/// Считать нажатия на каждую кнопку бессмысленно: эти числа потом никто
/// не посмотрит.
enum UsageEvent { launch, placeOpened, routeOpened, search, packDownloaded }

class UsageStatsNotifier extends StateNotifier<UsageStats> {
  UsageStatsNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static UsageStats _read(SharedPreferences prefs) {
    final firstMs = prefs.getInt(_Keys.firstLaunch);
    return UsageStats(
      launches: prefs.getInt(_Keys.launches) ?? 0,
      placesOpened: prefs.getInt(_Keys.places) ?? 0,
      routesOpened: prefs.getInt(_Keys.routes) ?? 0,
      searches: prefs.getInt(_Keys.searches) ?? 0,
      packsDownloaded: prefs.getInt(_Keys.packs) ?? 0,
      firstLaunch: firstMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(firstMs),
    );
  }

  void record(UsageEvent event) {
    final key = switch (event) {
      UsageEvent.launch => _Keys.launches,
      UsageEvent.placeOpened => _Keys.places,
      UsageEvent.routeOpened => _Keys.routes,
      UsageEvent.search => _Keys.searches,
      UsageEvent.packDownloaded => _Keys.packs,
    };
    _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);

    // Дата первого запуска ставится один раз и больше не трогается.
    if (event == UsageEvent.launch &&
        _prefs.getInt(_Keys.firstLaunch) == null) {
      _prefs.setInt(_Keys.firstLaunch, DateTime.now().millisecondsSinceEpoch);
    }

    state = _read(_prefs);
  }

  /// Стереть всё. Обязательная возможность: человек вправе не хотеть,
  /// чтобы его телефон вёл о нём счёт, даже локально.
  Future<void> reset() async {
    for (final key in [
      _Keys.launches,
      _Keys.places,
      _Keys.routes,
      _Keys.searches,
      _Keys.packs,
      _Keys.firstLaunch,
    ]) {
      await _prefs.remove(key);
    }
    state = _read(_prefs);
  }
}

final usageStatsProvider =
    StateNotifierProvider<UsageStatsNotifier, UsageStats>((ref) {
      return UsageStatsNotifier(ref.watch(prefsProvider));
    });
