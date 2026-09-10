import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/core/attribution.dart';
import 'package:nordguide/core/providers.dart';
import 'package:nordguide/data/database.dart';
import 'package:nordguide/features/home/home_screen.dart';
import 'package:nordguide/l10n/app_localizations.dart';
import 'package:nordguide/l10n/app_localizations_en.dart';
import 'package:nordguide/l10n/app_localizations_ru.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Стартовый экран уже один раз «пропадал»: Spacer внутри
/// SingleChildScrollView роняет построение, и остаётся только фон.
/// Анализатор такое не видит — ловится только сборкой виджета.
/// Стартовый экран показывает счётчик избранного, а значит тянет за собой
/// базу. Для проверки вёрстки она не нужна: подменяем провайдер пустым
/// списком, иначе тест открывает настоящий файл базы и виснет.
Widget _app({
  List<Favorite> favorites = const [],
  required SharedPreferences prefs,
}) {
  return ProviderScope(
    overrides: [
      // Переключатель языка в шапке читает сохранённые настройки, поэтому
      // без хранилища экран не строится вовсе.
      prefsProvider.overrideWithValue(prefs),
      favoritesProvider.overrideWith((ref) => Stream.value(favorites)),
    ],
    child: const MaterialApp(
      locale: Locale('ru'),
      localizationsDelegates: [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      home: HomeScreen(),
    ),
  );
}

/// Хранилище получаем внутри каждого теста, а не в setUp.
///
/// Асинхронный setUp с late-переменной здесь роняет тестовый изолят молча:
/// все тесты файла отваливаются с «did not complete», причём по отдельности
/// каждый проходит. Локальное получение надёжнее и читается не хуже.
Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('стартовый экран строится и показывает оба пути', (tester) async {
    await tester.pumpWidget(_app(prefs: await _prefs()));

    expect(tester.takeException(), isNull);
    // Название приложения — бренд, оно одинаково во всех локалях
    // и не переводится, в отличие от подписи под ним.
    expect(find.text('Norway Explore'), findsOneWidget);
    expect(find.text('Что рядом со мной'), findsOneWidget);
    expect(find.text('Куда поехать'), findsOneWidget);
  });

  testWidgets('стартовый экран не ломается на узком экране', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_app(prefs: await _prefs()));

    expect(tester.takeException(), isNull);
    expect(find.text('Что рядом со мной'), findsOneWidget);
  });

  testWidgets('на экране видна атрибуция фотографии', (tester) async {
    await tester.pumpWidget(_app(prefs: await _prefs()));

    // Требование CC BY-SA: снимок нельзя показывать без указания автора.
    // Имя берём из справочника, а не вписываем в тест: при замене фото
    // должен падать сам факт отсутствия подписи, а не смена автора.
    final credit = creditFor(HomeScreen.heroPhoto);
    expect(credit, isNotNull, reason: 'у заглавного фото нет записи об авторе');
    expect(find.textContaining(credit!.author), findsOneWidget);
  });

  testWidgets('без сохранённых мест раздела «Моя поездка» нет', (tester) async {
    await tester.pumpWidget(_app(prefs: await _prefs()));
    await tester.pump();
    // Пустой раздел на первом запуске — обещание без содержания.
    expect(find.text('Моя поездка'), findsNothing);
  });

  testWidgets('с сохранённым местом раздел появляется', (tester) async {
    await tester.pumpWidget(
      _app(
        prefs: await _prefs(),
        favorites: const [
          Favorite(placeId: 'osm:node/1', addedAt: 0, visited: false),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Моя поездка'), findsOneWidget);
    expect(find.text('1 место сохранено'), findsOneWidget);
  });

  test('русские числительные берутся из правил ICU', () {
    // Проверка не косметическая: «5 места» бросается в глаза сразу.
    // Формы теперь задаёт ARB, а не код — проверяем сам результат.
    final ru = LRu();
    expect(ru.favoritesSaved(1), '1 место сохранено');
    expect(ru.favoritesSaved(2), '2 места сохранено');
    expect(ru.favoritesSaved(5), '5 мест сохранено');
    expect(ru.favoritesSaved(11), '11 мест сохранено');
    expect(ru.favoritesSaved(21), '21 место сохранено');
    expect(ru.favoritesSaved(22), '22 места сохранено');
    expect(ru.favoritesSaved(114), '114 мест сохранено');
  });

  test('английские числительные — две формы', () {
    final en = LEn();
    expect(en.favoritesSaved(1), '1 place saved');
    expect(en.favoritesSaved(2), '2 places saved');
    expect(en.favoritesSaved(21), '21 places saved');
  });

  test('каждое изображение имеет запись атрибуции', () {
    // Защита от главного способа нарушить лицензию: положить картинку
    // в assets и забыть про автора.
    expect(imageCredits, isNotEmpty);
    for (final credit in imageCredits) {
      expect(credit.author, isNotEmpty, reason: 'нет автора: ${credit.asset}');
      expect(
        credit.license,
        isNotEmpty,
        reason: 'нет лицензии: ${credit.asset}',
      );
      // У снятой фотографии обязана быть страница источника. Исключение
      // одно — изображение, нарисованное нейросетью: страницы у него нет,
      // и оно помечено явным признаком, а не отсутствием ссылки.
      if (credit.generated) {
        expect(
          credit.license,
          isNot(startsWith('CC')),
          reason: 'сгенерированную картинку нельзя выдавать за CC-снимок: '
              '${credit.asset}',
        );
      } else {
        expect(
          credit.sourceUrl,
          startsWith('https://'),
          reason: 'нет ссылки на источник: ${credit.asset}',
        );
      }
    }
  });
}
