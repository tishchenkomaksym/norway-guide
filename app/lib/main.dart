import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
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

/// Выбирает, с чего начать: с вопроса об интересах или сразу с главного
/// экрана.
///
/// Вопрос показывается один раз за установку. Решение задавать его до
/// первого экрана пересмотрено 2026-09-10 — см. docs/decisions.md.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool _forceHome = false;

  @override
  Widget build(BuildContext context) {
    final answered = ref.watch(profileProvider).answered;
    if (answered || _forceHome) return const HomeScreen();
    return OnboardingScreen(
      onDone: () => setState(() => _forceHome = true),
    );
  }
}

class NordguideApp extends ConsumerWidget {
  const NordguideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Язык интерфейса берётся из системы и может быть переопределён
    // пользователем (см. languageProvider). Тот же язык используется
    // для выбора текстов о местах — но там работает цепочка подстановки
    // §8.4, поэтому интерфейс и содержимое могут оказаться на разных
    // языках, и это нормальное состояние.
    final language = ref.watch(languageProvider);

    return MaterialApp(
      title: 'nordguide',
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
      home: const _Root(),
    );
  }
}
