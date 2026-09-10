import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/core/attribution.dart';
import 'package:nordguide/features/home/home_screen.dart';

/// Стартовый экран уже один раз «пропадал»: Spacer внутри
/// SingleChildScrollView роняет построение, и остаётся только фон.
/// Анализатор такое не видит — ловится только сборкой виджета.
void main() {
  testWidgets('стартовый экран строится и показывает оба пути', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Норвегия'), findsOneWidget);
    expect(find.text('Что рядом со мной'), findsOneWidget);
    expect(find.text('Куда поехать'), findsOneWidget);
  });

  testWidgets('стартовый экран не ломается на узком экране', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Что рядом со мной'), findsOneWidget);
  });

  testWidgets('на экране видна атрибуция фотографии', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    // Требование CC BY-SA: снимок нельзя показывать без указания автора.
    expect(find.textContaining('Diego Delso'), findsOneWidget);
  });

  test('каждое изображение имеет запись атрибуции', () {
    // Защита от главного способа нарушить лицензию: положить картинку
    // в assets и забыть про автора.
    expect(imageCredits, isNotEmpty);
    for (final credit in imageCredits) {
      expect(credit.author, isNotEmpty, reason: 'нет автора: ${credit.asset}');
      expect(credit.license, isNotEmpty, reason: 'нет лицензии: ${credit.asset}');
      expect(credit.sourceUrl, startsWith('https://'),
          reason: 'нет ссылки на источник: ${credit.asset}');
    }
  });
}
