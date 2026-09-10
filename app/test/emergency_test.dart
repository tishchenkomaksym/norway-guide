import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/features/emergency/emergency_data.dart';

/// Ошибка в экстренных номерах опаснее любой другой ошибки в приложении,
/// поэтому здесь проверяется не вёрстка, а сами данные.
void main() {
  test('номера служб спасения Норвегии на месте', () {
    final numbers = emergencyContacts.map((c) => c.number).toSet();
    expect(numbers, containsAll(['113', '112', '110']));
  });

  test('службы спасения жизни помечены как критические', () {
    final critical =
        emergencyContacts.where((c) => c.critical).map((c) => c.number).toSet();
    // Эти три показываются крупно и первыми, без прокрутки.
    expect(critical, equals({'113', '112', '110'}));
  });

  test('номер для набора не содержит пробелов', () {
    for (final c in emergencyContacts) {
      expect(c.dialNumber, isNot(contains(' ')),
          reason: 'нельзя набрать: ${c.number}');
      expect(c.dialNumber, matches(RegExp(r'^\d+$')),
          reason: 'в номере посторонние символы: ${c.number}');
    }
  });

  test('у каждой службы есть название и пояснение', () {
    for (final c in emergencyContacts) {
      expect(c.title, isNotEmpty);
      expect(c.subtitle, isNotEmpty, reason: 'нет пояснения: ${c.number}');
    }
  });

  test('пояснения не содержат медицинских советов', () {
    // Приложение не имеет права советовать, что делать с пострадавшим:
    // только куда звонить.
    const forbidden = ['примите', 'выпейте', 'наложите', 'сделайте искусственное'];
    for (final (_, title, body) in emergencyNotes) {
      final text = '$title $body'.toLowerCase();
      for (final word in forbidden) {
        expect(text, isNot(contains(word)),
            reason: 'похоже на медицинский совет: $title');
      }
    }
  });
}
