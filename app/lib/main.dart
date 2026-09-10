import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: NordguideApp()));
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
      home: const HomeScreen(),
    );
  }
}
