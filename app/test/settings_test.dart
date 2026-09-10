import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/core/profile.dart';
import 'package:nordguide/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Настройки — это ответы человека на вопросы, которые приложение задало
/// один раз. Терять их при перезапуске значит спрашивать заново то, что
/// уже сказано.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container() async {
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('язык', () {
    test('без сохранённого берётся из системы', () async {
      final c = await container();
      addTearDown(c.dispose);

      // В тестовой среде локаль обычно en_US.
      expect(supportedLanguages, contains(c.read(languageProvider)));
    });

    test('выбранный переживает перезапуск', () async {
      final first = await container();
      first.read(languageProvider.notifier).set('de');
      first.dispose();

      // Новый контейнер — как новый запуск приложения.
      final second = await container();
      addTearDown(second.dispose);
      expect(second.read(languageProvider), 'de');
    });

    test('nb и nn ведут на no', () {
      // Иначе половина норвежских телефонов получит английский
      // в приложении о Норвегии.
      expect(resolveLanguage(const Locale('nb')), 'no');
      expect(resolveLanguage(const Locale('nn')), 'no');
      expect(resolveLanguage(const Locale('no')), 'no');
    });

    test('регион отбрасывается, незнакомый язык даёт английский', () {
      expect(resolveLanguage(const Locale('de', 'AT')), 'de');
      expect(resolveLanguage(const Locale('zh', 'CN')), 'zh');
      expect(resolveLanguage(const Locale('fi')), 'en');
    });
  });

  group('выбранный город', () {
    test('сохраняется и восстанавливается', () async {
      final first = await container();
      first.read(mockPositionProvider.notifier).set(
            (name: 'Bergen', lat: 60.3913, lon: 5.3221),
          );
      first.dispose();

      final second = await container();
      addTearDown(second.dispose);
      final restored = second.read(mockPositionProvider);

      expect(restored, isNotNull);
      expect(restored!.name, 'Bergen');
      expect(restored.lat, closeTo(60.3913, 0.0001));
    });

    test('возврат к GPS стирает сохранённый город', () async {
      final first = await container();
      first.read(mockPositionProvider.notifier).set(
            (name: 'Oslo', lat: 59.9, lon: 10.7),
          );
      first.read(mockPositionProvider.notifier).set(null);
      first.dispose();

      final second = await container();
      addTearDown(second.dispose);
      expect(second.read(mockPositionProvider), isNull);
    });
  });

  group('профиль', () {
    test('интересы переживают перезапуск', () async {
      final first = await container();
      first.read(profileProvider.notifier).toggleInterest('hiking');
      first.read(profileProvider.notifier).toggleInterest('photo');
      first.dispose();

      final second = await container();
      addTearDown(second.dispose);
      expect(second.read(profileProvider).interestIds, {'hiking', 'photo'});
    });

    test('отметка «уже спрашивали» переживает перезапуск', () async {
      // Без этого приложение задавало бы один и тот же вопрос при каждом
      // запуске, хотя человек однажды его закрыл.
      final first = await container();
      first.read(profileProvider.notifier).markAnswered();
      first.dispose();

      final second = await container();
      addTearDown(second.dispose);
      expect(second.read(profileProvider).answered, isTrue);
      expect(second.read(shouldAskProfileProvider), isFalse);
    });

    test('время поездки сохраняется', () async {
      final first = await container();
      first.read(profileProvider.notifier).setTravelTime(TravelTime.soon);
      first.dispose();

      final second = await container();
      addTearDown(second.dispose);
      expect(second.read(profileProvider).travelTime, TravelTime.soon);
    });

    test('сброс очищает всё', () async {
      final first = await container();
      first.read(profileProvider.notifier).toggleInterest('fishing');
      first.read(profileProvider.notifier).markAnswered();
      first.read(profileProvider.notifier).reset();
      first.dispose();

      final second = await container();
      addTearDown(second.dispose);
      expect(second.read(profileProvider).interestIds, isEmpty);
      expect(second.read(profileProvider).answered, isFalse);
    });
  });
}
