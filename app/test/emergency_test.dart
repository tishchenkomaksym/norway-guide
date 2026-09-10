import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/features/emergency/emergency_data.dart';
import 'package:nordguide/l10n/app_localizations.dart';

/// Ошибка в экстренных номерах опаснее любой другой ошибки в приложении,
/// поэтому здесь проверяются данные, а не вёрстка.
///
/// Номера собираются вместе с локализованными подписями, поэтому часть
/// проверок требует контекста — их гоняем через реальный виджет.
void main() {
  test('номера служб спасения Норвегии на месте', () {
    expect(emergencyNumbers, containsAll(['113', '112', '110']));
  });

  test('номер для набора не содержит пробелов и посторонних символов', () {
    for (final n in emergencyNumbers) {
      final dial = n.replaceAll(' ', '');
      expect(dial, matches(RegExp(r'^\d+$')), reason: 'плохой номер: $n');
    }
  });

  testWidgets('на всех языках номера одни и те же', (tester) async {
    // Перевод не должен по недосмотру подменить номер: подписи разные,
    // цифры одинаковые.
    for (final locale in L.supportedLocales) {
      late List<EmergencyContact> contacts;

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L.supportedLocales,
          home: Builder(
            builder: (context) {
              contacts = emergencyContacts(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        contacts.map((c) => c.number).toList(),
        emergencyNumbers,
        reason: 'номера разъехались для локали ${locale.languageCode}',
      );

      final critical = contacts
          .where((c) => c.critical)
          .map((c) => c.number)
          .toSet();
      expect(critical, {
        '113',
        '112',
        '110',
      }, reason: 'критические службы для ${locale.languageCode}');

      for (final c in contacts) {
        expect(
          c.title,
          isNotEmpty,
          reason: 'нет названия: ${c.number} / ${locale.languageCode}',
        );
        expect(
          c.subtitle,
          isNotEmpty,
          reason: 'нет пояснения: ${c.number} / ${locale.languageCode}',
        );
      }
    }
  });

  testWidgets('пояснения не содержат медицинских советов', (tester) async {
    // Приложение не имеет права советовать, что делать с пострадавшим:
    // только куда звонить.
    const forbidden = [
      'примите',
      'выпейте',
      'наложите',
      'сделайте искусственное',
      'apply a tourniquet',
      'give aspirin',
    ];

    late List<(IconData, String, String)> notes;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          L.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L.supportedLocales,
        home: Builder(
          builder: (context) {
            notes = emergencyNotes(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(notes, isNotEmpty);
    for (final (_, title, body) in notes) {
      final text = '$title $body'.toLowerCase();
      for (final word in forbidden) {
        expect(
          text,
          isNot(contains(word)),
          reason: 'похоже на медицинский совет: $title',
        );
      }
    }
  });
}
