import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/features/home/home_screen.dart';

/// Стартовый экран уже один раз «пропадал»: Spacer внутри
/// SingleChildScrollView роняет построение, и остаётся только фон.
/// Анализатор такое не видит — ловится только сборкой виджета.
void main() {
  testWidgets('стартовый экран строится и показывает оба пути', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('nordguide'), findsOneWidget);
    expect(find.text('Что интересного рядом'), findsOneWidget);
    expect(find.text('Города и достопримечательности'), findsOneWidget);
  });

  testWidgets('стартовый экран не ломается на узком экране', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Что интересного рядом'), findsOneWidget);
  });
}
