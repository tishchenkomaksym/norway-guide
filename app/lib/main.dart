import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers.dart';
import 'core/usage_stats.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настройки читаем ДО запуска приложения: иначе первый кадр отрисуется
  // с языком по умолчанию, а следующий — с сохранённым, и человек увидит
  // мигание интерфейса на старте.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const NordguideApp(),
    ),
  );
}

class NordguideApp extends ConsumerStatefulWidget {
  const NordguideApp({super.key});

  @override
  ConsumerState<NordguideApp> createState() => _NordguideAppState();
}

class _NordguideAppState extends ConsumerState<NordguideApp> {
  @override
  void initState() {
    super.initState();
    // Запуск считается один раз за сессию, в initState, а не в build:
    // build вызывается при каждой смене языка и темы.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usageStatsProvider.notifier).record(UsageEvent.launch);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Язык интерфейса берётся из системы и может быть переопределён
    // пользователем (см. languageProvider). Тот же язык используется
    // для выбора текстов о местах — но там работает цепочка подстановки
    // §8.4, поэтому интерфейс и содержимое могут оказаться на разных
    // языках, и это нормальное состояние.
    final language = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Norway Explore',
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6F8B)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6F8B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
