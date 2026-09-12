import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_no.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('no'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Norway Explore'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In ru, this message translates to:
  /// **'Фьорды, водопады и города — без интернета'**
  String get appTagline;

  /// No description provided for @nearbyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что рядом со мной'**
  String get nearbyTitle;

  /// No description provided for @nearbySubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшие места с расстоянием и направлением'**
  String get nearbySubtitle;

  /// No description provided for @browseTitle.
  ///
  /// In ru, this message translates to:
  /// **'Куда поехать'**
  String get browseTitle;

  /// No description provided for @browseSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Города и достопримечательности страны'**
  String get browseSubtitle;

  /// No description provided for @favoritesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моя поездка'**
  String get favoritesTitle;

  /// No description provided for @favoritesSaved.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} место сохранено} few{{count} места сохранено} many{{count} мест сохранено} other{{count} мест сохранено}}'**
  String favoritesSaved(int count);

  /// No description provided for @sourcesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Источники и лицензии'**
  String get sourcesTitle;

  /// No description provided for @sourcesTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Об источниках'**
  String get sourcesTooltip;

  /// No description provided for @photoBy.
  ///
  /// In ru, this message translates to:
  /// **'Фото: {credit}'**
  String photoBy(String credit);

  /// No description provided for @nearbyScreenTitle.
  ///
  /// In ru, this message translates to:
  /// **'Рядом со мной'**
  String get nearbyScreenTitle;

  /// No description provided for @nearbyScreenTitleAt.
  ///
  /// In ru, this message translates to:
  /// **'Рядом: {city}'**
  String nearbyScreenTitleAt(String city);

  /// No description provided for @searchTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get searchTooltip;

  /// No description provided for @setCityTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Указать город'**
  String get setCityTooltip;

  /// No description provided for @useGpsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Определить по GPS'**
  String get useGpsTooltip;

  /// No description provided for @interestsTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Мои интересы'**
  String get interestsTooltip;

  /// No description provided for @locationUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Положение неизвестно. Нажмите, чтобы указать город'**
  String get locationUnknown;

  /// No description provided for @nothingInFilters.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено по выбранным фильтрам'**
  String get nothingInFilters;

  /// No description provided for @loadError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить места'**
  String get loadError;

  /// No description provided for @otherLanguageShort.
  ///
  /// In ru, this message translates to:
  /// **'На другом языке'**
  String get otherLanguageShort;

  /// No description provided for @descriptionOtherLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Перевода пока нет — текст на языке источника'**
  String get descriptionOtherLanguage;

  /// No description provided for @tabCities.
  ///
  /// In ru, this message translates to:
  /// **'Города'**
  String get tabCities;

  /// No description provided for @tabPlaces.
  ///
  /// In ru, this message translates to:
  /// **'Места'**
  String get tabPlaces;

  /// No description provided for @noCities.
  ///
  /// In ru, this message translates to:
  /// **'Городов в этой сборке данных нет'**
  String get noCities;

  /// No description provided for @nothingInCategories.
  ///
  /// In ru, this message translates to:
  /// **'По выбранным категориям ничего не нашлось'**
  String get nothingInCategories;

  /// No description provided for @shownOf.
  ///
  /// In ru, this message translates to:
  /// **'Показано {shown} из {total}'**
  String shownOf(int shown, int total);

  /// No description provided for @resetFilter.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get resetFilter;

  /// No description provided for @placesCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} мест'**
  String placesCount(int count);

  /// No description provided for @cityLarge.
  ///
  /// In ru, this message translates to:
  /// **'Крупный город'**
  String get cityLarge;

  /// No description provided for @cityMedium.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get cityMedium;

  /// No description provided for @citySmall.
  ///
  /// In ru, this message translates to:
  /// **'Небольшой город'**
  String get citySmall;

  /// No description provided for @cityVillage.
  ///
  /// In ru, this message translates to:
  /// **'Посёлок'**
  String get cityVillage;

  /// No description provided for @cityHamlet.
  ///
  /// In ru, this message translates to:
  /// **'Небольшой посёлок'**
  String get cityHamlet;

  /// No description provided for @cityTourist.
  ///
  /// In ru, this message translates to:
  /// **'Туристическое место'**
  String get cityTourist;

  /// No description provided for @cityGeneric.
  ///
  /// In ru, this message translates to:
  /// **'Населённый пункт'**
  String get cityGeneric;

  /// No description provided for @noPlacesInCity.
  ///
  /// In ru, this message translates to:
  /// **'Для этого города мест пока нет'**
  String get noPlacesInCity;

  /// No description provided for @placeNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Место не найдено'**
  String get placeNotFound;

  /// No description provided for @noDescription.
  ///
  /// In ru, this message translates to:
  /// **'Описания для этого места пока нет. Координаты и маршрут работают — можно доехать и посмотреть самому.'**
  String get noDescription;

  /// No description provided for @noDescriptionShort.
  ///
  /// In ru, this message translates to:
  /// **'Описание пока не загружено'**
  String get noDescriptionShort;

  /// No description provided for @routeButton.
  ///
  /// In ru, this message translates to:
  /// **'Проложить маршрут'**
  String get routeButton;

  /// No description provided for @mapsFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть карты. Нужен интернет.'**
  String get mapsFailed;

  /// No description provided for @addToFavorites.
  ///
  /// In ru, this message translates to:
  /// **'В избранное'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из избранного'**
  String get removeFromFavorites;

  /// No description provided for @factOpeningHours.
  ///
  /// In ru, this message translates to:
  /// **'Часы работы'**
  String get factOpeningHours;

  /// No description provided for @factFee.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get factFee;

  /// No description provided for @factDifficulty.
  ///
  /// In ru, this message translates to:
  /// **'Сложность'**
  String get factDifficulty;

  /// No description provided for @factDuration.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get factDuration;

  /// No description provided for @factMinutes.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин'**
  String factMinutes(int count);

  /// No description provided for @factSeason.
  ///
  /// In ru, this message translates to:
  /// **'Сезон'**
  String get factSeason;

  /// No description provided for @factWebsite.
  ///
  /// In ru, this message translates to:
  /// **'Сайт'**
  String get factWebsite;

  /// No description provided for @searchHint.
  ///
  /// In ru, this message translates to:
  /// **'Место, город, водопад…'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Введите хотя бы две буквы'**
  String get searchPrompt;

  /// No description provided for @searchPromptDetail.
  ///
  /// In ru, this message translates to:
  /// **'Ищем на языке интерфейса, норвежском и английском одновременно — можно набирать так, как написано на указателе.'**
  String get searchPromptDetail;

  /// No description provided for @searchNothing.
  ///
  /// In ru, this message translates to:
  /// **'По запросу «{query}» ничего не нашлось'**
  String searchNothing(String query);

  /// No description provided for @searchNothingDetail.
  ///
  /// In ru, this message translates to:
  /// **'Описания есть не у всех мест. Попробуйте норвежское написание или часть слова.'**
  String get searchNothingDetail;

  /// No description provided for @searchError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка поиска'**
  String get searchError;

  /// No description provided for @favoritesWant.
  ///
  /// In ru, this message translates to:
  /// **'Хочу посмотреть'**
  String get favoritesWant;

  /// No description provided for @favoritesVisited.
  ///
  /// In ru, this message translates to:
  /// **'Уже был'**
  String get favoritesVisited;

  /// No description provided for @favoritesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь пока пусто'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyDetail.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите сердечко на карточке места — оно попадёт сюда. Можно отмечать посещённые и оставлять заметки.'**
  String get favoritesEmptyDetail;

  /// No description provided for @noteTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Заметка'**
  String get noteTooltip;

  /// No description provided for @noteHint.
  ///
  /// In ru, this message translates to:
  /// **'Во сколько открывается, где парковка, что взять…'**
  String get noteHint;

  /// No description provided for @markVisited.
  ///
  /// In ru, this message translates to:
  /// **'Был здесь'**
  String get markVisited;

  /// No description provided for @markNotVisited.
  ///
  /// In ru, this message translates to:
  /// **'Не был'**
  String get markNotVisited;

  /// No description provided for @removedFromTrip.
  ///
  /// In ru, this message translates to:
  /// **'{place} убрано из поездки'**
  String removedFromTrip(String place);

  /// No description provided for @undo.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть'**
  String get undo;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @emergencyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Экстренная помощь'**
  String get emergencyTitle;

  /// No description provided for @emergencyTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Экстренная помощь'**
  String get emergencyTooltip;

  /// No description provided for @emergencyOther.
  ///
  /// In ru, this message translates to:
  /// **'Другие службы'**
  String get emergencyOther;

  /// No description provided for @emergencyKnow.
  ///
  /// In ru, this message translates to:
  /// **'Что важно знать'**
  String get emergencyKnow;

  /// No description provided for @emergencyCoordinates.
  ///
  /// In ru, this message translates to:
  /// **'Ваши координаты'**
  String get emergencyCoordinates;

  /// No description provided for @emergencyCopy.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get emergencyCopy;

  /// No description provided for @emergencyCopied.
  ///
  /// In ru, this message translates to:
  /// **'Координаты скопированы'**
  String get emergencyCopied;

  /// No description provided for @emergencyManualPosition.
  ///
  /// In ru, this message translates to:
  /// **'Положение задано вручную — не по GPS'**
  String get emergencyManualPosition;

  /// No description provided for @emergencyDial.
  ///
  /// In ru, this message translates to:
  /// **'{service}: наберите {number}'**
  String emergencyDial(String service, String number);

  /// No description provided for @whereAreYou.
  ///
  /// In ru, this message translates to:
  /// **'Где вы находитесь?'**
  String get whereAreYou;

  /// No description provided for @cityHint.
  ///
  /// In ru, this message translates to:
  /// **'Город: Берген, Oslo, Tromsø…'**
  String get cityHint;

  /// No description provided for @nothingFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get nothingFound;

  /// No description provided for @profileQuestion.
  ///
  /// In ru, this message translates to:
  /// **'Что вам интереснее всего?'**
  String get profileQuestion;

  /// No description provided for @profileQuestionDetail.
  ///
  /// In ru, this message translates to:
  /// **'Подберём, что показывать первым. Ничего не спрячем — весь каталог остаётся доступен через поиск.'**
  String get profileQuestionDetail;

  /// No description provided for @profileWhen.
  ///
  /// In ru, this message translates to:
  /// **'Когда планируете поездку?'**
  String get profileWhen;

  /// No description provided for @profileWhenDetail.
  ///
  /// In ru, this message translates to:
  /// **'Горные дороги и часть троп закрыты зимой — не будем предлагать то, куда сейчас не проехать.'**
  String get profileWhenDetail;

  /// No description provided for @profileNow.
  ///
  /// In ru, this message translates to:
  /// **'Я сейчас в Норвегии'**
  String get profileNow;

  /// No description provided for @profileSoon.
  ///
  /// In ru, this message translates to:
  /// **'В ближайшие месяцы'**
  String get profileSoon;

  /// No description provided for @profileBrowsing.
  ///
  /// In ru, this message translates to:
  /// **'Просто смотрю'**
  String get profileBrowsing;

  /// No description provided for @profileSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get profileSkip;

  /// No description provided for @profileNext.
  ///
  /// In ru, this message translates to:
  /// **'Дальше'**
  String get profileNext;

  /// No description provided for @profileDone.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{Готово — подходящие места теперь выше в списке} few{Готово — учли {count} интереса в порядке выдачи} many{Готово — учли {count} интересов в порядке выдачи} other{Готово — учли {count} интереса в порядке выдачи}}'**
  String profileDone(int count);

  /// No description provided for @catMuseums.
  ///
  /// In ru, this message translates to:
  /// **'Музеи'**
  String get catMuseums;

  /// No description provided for @catViewpoints.
  ///
  /// In ru, this message translates to:
  /// **'Смотровые'**
  String get catViewpoints;

  /// No description provided for @catFjords.
  ///
  /// In ru, this message translates to:
  /// **'Фьорды'**
  String get catFjords;

  /// No description provided for @catWaterfalls.
  ///
  /// In ru, this message translates to:
  /// **'Водопады'**
  String get catWaterfalls;

  /// No description provided for @catChurches.
  ///
  /// In ru, this message translates to:
  /// **'Церкви'**
  String get catChurches;

  /// No description provided for @catHikes.
  ///
  /// In ru, this message translates to:
  /// **'Тропы'**
  String get catHikes;

  /// No description provided for @catGlaciers.
  ///
  /// In ru, this message translates to:
  /// **'Ледники'**
  String get catGlaciers;

  /// No description provided for @catBeaches.
  ///
  /// In ru, this message translates to:
  /// **'Пляжи'**
  String get catBeaches;

  /// No description provided for @catMuseum.
  ///
  /// In ru, this message translates to:
  /// **'Музей'**
  String get catMuseum;

  /// No description provided for @catViewpoint.
  ///
  /// In ru, this message translates to:
  /// **'Смотровая'**
  String get catViewpoint;

  /// No description provided for @catFjord.
  ///
  /// In ru, this message translates to:
  /// **'Фьорд'**
  String get catFjord;

  /// No description provided for @catWaterfall.
  ///
  /// In ru, this message translates to:
  /// **'Водопад'**
  String get catWaterfall;

  /// No description provided for @catChurch.
  ///
  /// In ru, this message translates to:
  /// **'Церковь'**
  String get catChurch;

  /// No description provided for @catHike.
  ///
  /// In ru, this message translates to:
  /// **'Тропа'**
  String get catHike;

  /// No description provided for @catGlacier.
  ///
  /// In ru, this message translates to:
  /// **'Ледник'**
  String get catGlacier;

  /// No description provided for @catBeach.
  ///
  /// In ru, this message translates to:
  /// **'Пляж'**
  String get catBeach;

  /// No description provided for @catOther.
  ///
  /// In ru, this message translates to:
  /// **'Место'**
  String get catOther;

  /// No description provided for @emgAmbulance.
  ///
  /// In ru, this message translates to:
  /// **'Скорая помощь'**
  String get emgAmbulance;

  /// No description provided for @emgAmbulanceSub.
  ///
  /// In ru, this message translates to:
  /// **'Ambulanse · угроза жизни, тяжёлая травма'**
  String get emgAmbulanceSub;

  /// No description provided for @emgPolice.
  ///
  /// In ru, this message translates to:
  /// **'Полиция'**
  String get emgPolice;

  /// No description provided for @emgPoliceSub.
  ///
  /// In ru, this message translates to:
  /// **'Politi · преступление, авария, пропал человек'**
  String get emgPoliceSub;

  /// No description provided for @emgFire.
  ///
  /// In ru, this message translates to:
  /// **'Пожарная служба'**
  String get emgFire;

  /// No description provided for @emgFireSub.
  ///
  /// In ru, this message translates to:
  /// **'Brann · пожар, задымление, утечка газа'**
  String get emgFireSub;

  /// No description provided for @emgDoctor.
  ///
  /// In ru, this message translates to:
  /// **'Дежурный врач'**
  String get emgDoctor;

  /// No description provided for @emgDoctorSub.
  ///
  /// In ru, this message translates to:
  /// **'Legevakt · срочно, но жизни ничто не угрожает'**
  String get emgDoctorSub;

  /// No description provided for @emgSea.
  ///
  /// In ru, this message translates to:
  /// **'Спасение на воде'**
  String get emgSea;

  /// No description provided for @emgSeaSub.
  ///
  /// In ru, this message translates to:
  /// **'Hovedredningssentralen · происшествие в море'**
  String get emgSeaSub;

  /// No description provided for @emgPoison.
  ///
  /// In ru, this message translates to:
  /// **'Отравления'**
  String get emgPoison;

  /// No description provided for @emgPoisonSub.
  ///
  /// In ru, this message translates to:
  /// **'Giftinformasjonen · круглосуточно'**
  String get emgPoisonSub;

  /// No description provided for @emgRoad.
  ///
  /// In ru, this message translates to:
  /// **'Дорожная служба'**
  String get emgRoad;

  /// No description provided for @emgRoadSub.
  ///
  /// In ru, this message translates to:
  /// **'Vegtrafikksentralen · перекрытые дороги, лавины'**
  String get emgRoadSub;

  /// No description provided for @emgNoteSimTitle.
  ///
  /// In ru, this message translates to:
  /// **'Работает без сети и без SIM'**
  String get emgNoteSimTitle;

  /// No description provided for @emgNoteSimBody.
  ///
  /// In ru, this message translates to:
  /// **'Звонок на 112 и 113 проходит через любую доступную вышку, даже если у вашего оператора нет покрытия и в телефоне нет SIM-карты.'**
  String get emgNoteSimBody;

  /// No description provided for @emgNoteCoordsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Назовите координаты'**
  String get emgNoteCoordsTitle;

  /// No description provided for @emgNoteCoordsBody.
  ///
  /// In ru, this message translates to:
  /// **'В горах и на фьордах адреса нет. Продиктуйте широту и долготу — они ниже на этом экране, их можно скопировать. Оператор поймёт.'**
  String get emgNoteCoordsBody;

  /// No description provided for @emgNoteEnglishTitle.
  ///
  /// In ru, this message translates to:
  /// **'Английский понимают'**
  String get emgNoteEnglishTitle;

  /// No description provided for @emgNoteEnglishBody.
  ///
  /// In ru, this message translates to:
  /// **'Операторы экстренных служб Норвегии говорят по-английски. Говорите спокойно и коротко: что случилось, где, сколько пострадавших.'**
  String get emgNoteEnglishBody;

  /// No description provided for @emgNoteMountainTitle.
  ///
  /// In ru, this message translates to:
  /// **'В горах — 112'**
  String get emgNoteMountainTitle;

  /// No description provided for @emgNoteMountainBody.
  ///
  /// In ru, this message translates to:
  /// **'Спасением в горах занимается полиция, отдельного номера нет. Не выключайте телефон: по нему вас будут искать.'**
  String get emgNoteMountainBody;

  /// No description provided for @emgVerified.
  ///
  /// In ru, this message translates to:
  /// **'Номера действительны для Норвегии. Проверены 10.09.2026 по источникам politiet.no, helsenorge.no, hovedredningssentralen.no.'**
  String get emgVerified;

  /// No description provided for @onboardingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что вас интересует в Норвегии?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметьте всё, что подходит — подберём, что показывать первым.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingNothingHidden.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не спрячем: полный каталог мест остаётся доступен через поиск и фильтры.'**
  String get onboardingNothingHidden;

  /// No description provided for @onboardingStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get onboardingStart;

  /// No description provided for @intNature.
  ///
  /// In ru, this message translates to:
  /// **'Природа и виды'**
  String get intNature;

  /// No description provided for @intHiking.
  ///
  /// In ru, this message translates to:
  /// **'Походы и треккинг'**
  String get intHiking;

  /// No description provided for @intFishing.
  ///
  /// In ru, this message translates to:
  /// **'Рыбалка'**
  String get intFishing;

  /// No description provided for @intHunting.
  ///
  /// In ru, this message translates to:
  /// **'Охота'**
  String get intHunting;

  /// No description provided for @intCulture.
  ///
  /// In ru, this message translates to:
  /// **'Музеи и культура'**
  String get intCulture;

  /// No description provided for @intPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Фотография'**
  String get intPhoto;

  /// No description provided for @intKids.
  ///
  /// In ru, this message translates to:
  /// **'С детьми'**
  String get intKids;

  /// No description provided for @intRoadtrip.
  ///
  /// In ru, this message translates to:
  /// **'Автопутешествие'**
  String get intRoadtrip;

  /// No description provided for @intWinter.
  ///
  /// In ru, this message translates to:
  /// **'Зимний спорт'**
  String get intWinter;

  /// No description provided for @intCruise.
  ///
  /// In ru, this message translates to:
  /// **'Круиз, несколько часов'**
  String get intCruise;

  /// No description provided for @rulesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Правила и лицензии'**
  String get rulesTitle;

  /// No description provided for @rulesWhereToCheck.
  ///
  /// In ru, this message translates to:
  /// **'Где проверить'**
  String get rulesWhereToCheck;

  /// No description provided for @rulesKommune.
  ///
  /// In ru, this message translates to:
  /// **'Коммуна {name}'**
  String rulesKommune(String name);

  /// No description provided for @rulesCheckedAt.
  ///
  /// In ru, this message translates to:
  /// **'Данные получены {date}'**
  String rulesCheckedAt(String date);

  /// No description provided for @rulesCallKommune.
  ///
  /// In ru, this message translates to:
  /// **'Позвонить в коммуну'**
  String get rulesCallKommune;

  /// No description provided for @rulesOpenSite.
  ///
  /// In ru, this message translates to:
  /// **'Сайт коммуны'**
  String get rulesOpenSite;

  /// No description provided for @rulesDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Приложение не выдаёт разрешений и не может сказать, разрешён ли лов или охота именно здесь. Это зависит от коммуны, владельца участка, сезона и вида. Перед выездом уточните в коммуне или у владельца.'**
  String get rulesDisclaimer;

  /// No description provided for @rulesNational.
  ///
  /// In ru, this message translates to:
  /// **'Общие правила по стране'**
  String get rulesNational;

  /// No description provided for @rulesSource.
  ///
  /// In ru, this message translates to:
  /// **'Источник: {authority}'**
  String rulesSource(String authority);

  /// No description provided for @rulesFishing.
  ///
  /// In ru, this message translates to:
  /// **'Рыбалка'**
  String get rulesFishing;

  /// No description provided for @rulesHunting.
  ///
  /// In ru, this message translates to:
  /// **'Охота'**
  String get rulesHunting;

  /// No description provided for @rulesNoKommune.
  ///
  /// In ru, this message translates to:
  /// **'Коммуна для этой точки не определена. На Шпицбергене правила устанавливает губернатор (Sysselmesteren), а не коммуна.'**
  String get rulesNoKommune;

  /// No description provided for @promptTitle.
  ///
  /// In ru, this message translates to:
  /// **'Что вас интересует?'**
  String get promptTitle;

  /// No description provided for @promptSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Рыбалка, походы, музеи — подберём, что показывать'**
  String get promptSubtitle;

  /// No description provided for @modeTourist.
  ///
  /// In ru, this message translates to:
  /// **'Всё подряд'**
  String get modeTourist;

  /// No description provided for @modeFishing.
  ///
  /// In ru, this message translates to:
  /// **'Рыбалка'**
  String get modeFishing;

  /// No description provided for @modeHunting.
  ///
  /// In ru, this message translates to:
  /// **'Охота'**
  String get modeHunting;

  /// No description provided for @modeSwitch.
  ///
  /// In ru, this message translates to:
  /// **'Режим'**
  String get modeSwitch;

  /// No description provided for @modeFishingHint.
  ///
  /// In ru, this message translates to:
  /// **'Показаны места для рыбалки. Города и достопримечательности скрыты — вернуть их можно кнопкой режима.'**
  String get modeFishingHint;

  /// No description provided for @modeHuntingHint.
  ///
  /// In ru, this message translates to:
  /// **'Показаны природные места. Охотничьи угодья на карте не размечены — главное здесь правила и коммуна.'**
  String get modeHuntingHint;

  /// No description provided for @modeRulesButton.
  ///
  /// In ru, this message translates to:
  /// **'Правила и лицензии'**
  String get modeRulesButton;

  /// No description provided for @locServiceOff.
  ///
  /// In ru, this message translates to:
  /// **'Геолокация выключена в настройках телефона'**
  String get locServiceOff;

  /// No description provided for @locDenied.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к местоположению'**
  String get locDenied;

  /// No description provided for @locDeniedForever.
  ///
  /// In ru, this message translates to:
  /// **'Доступ к местоположению запрещён. Разрешить можно в настройках приложения'**
  String get locDeniedForever;

  /// No description provided for @locUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение. В помещении сигнал слабый'**
  String get locUnavailable;

  /// No description provided for @locOpenSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get locOpenSettings;

  /// No description provided for @locSetCity.
  ///
  /// In ru, this message translates to:
  /// **'Указать город'**
  String get locSetCity;

  /// No description provided for @locRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get locRetry;

  /// No description provided for @nothingNearby.
  ///
  /// In ru, this message translates to:
  /// **'Рядом ничего нет'**
  String get nothingNearby;

  /// No description provided for @nothingNearbyHint.
  ///
  /// In ru, this message translates to:
  /// **'В путеводитель попадают только места с описанием или фотографией. Вокруг вас таких сейчас нет.'**
  String get nothingNearbyHint;

  /// No description provided for @nothingInFiltersHint.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте убрать категорию — рядом могут быть другие места.'**
  String get nothingInFiltersHint;

  /// No description provided for @resetFilters.
  ///
  /// In ru, this message translates to:
  /// **'Показать все категории'**
  String get resetFilters;

  /// No description provided for @mostVisitedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Самое посещаемое'**
  String get mostVisitedTitle;

  /// No description provided for @mostVisitedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Двадцать пять мест, ради которых едут в Норвегию'**
  String get mostVisitedSubtitle;

  /// No description provided for @mostVisitedEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Топ-списка нет в этом пакете контента'**
  String get mostVisitedEmpty;

  /// No description provided for @mostVisitedNote.
  ///
  /// In ru, this message translates to:
  /// **'Порядок составлен вручную: по числу посетителей, статусу ЮНЕСКО и известности места. Там, где показано число посетителей, год и источник указаны в карточке места.'**
  String get mostVisitedNote;

  /// No description provided for @unescoShort.
  ///
  /// In ru, this message translates to:
  /// **'ЮНЕСКО'**
  String get unescoShort;

  /// No description provided for @photoCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} фотография} few{{n} фотографии} many{{n} фотографий} other{{n} фотографии}}'**
  String photoCount(int n);

  /// No description provided for @visitorsPerYear.
  ///
  /// In ru, this message translates to:
  /// **'Около {n} посетителей в год ({year})'**
  String visitorsPerYear(int n, String year);

  /// No description provided for @profileDoneButton.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get profileDoneButton;

  /// No description provided for @downloadsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Скачать перед поездкой'**
  String get downloadsTitle;

  /// No description provided for @downloadsNote.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии качаются по регионам, чтобы приложение оставалось лёгким. Ничего не скачивается само — путеводитель не тратит ваш трафик без спроса.'**
  String get downloadsNote;

  /// No description provided for @downloadsBuiltAt.
  ///
  /// In ru, this message translates to:
  /// **'Данные собраны {date}'**
  String downloadsBuiltAt(String date);

  /// No description provided for @downloadsPhotos.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} фотография} few{{n} фотографии} many{{n} фотографий} other{{n} фотографии}}'**
  String downloadsPhotos(int n);

  /// No description provided for @downloadsStart.
  ///
  /// In ru, this message translates to:
  /// **'Скачать'**
  String get downloadsStart;

  /// No description provided for @downloadsRemove.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get downloadsRemove;

  /// No description provided for @downloadsUpdateAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Доступна более новая версия'**
  String get downloadsUpdateAvailable;

  /// No description provided for @downloadsFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать'**
  String get downloadsFailed;

  /// No description provided for @downloadsOffline.
  ///
  /// In ru, this message translates to:
  /// **'Нет связи с сервером контента'**
  String get downloadsOffline;

  /// No description provided for @downloadsNothingInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Пока ничего не скачано. Места работают — не хватает только дополнительных фотографий.'**
  String get downloadsNothingInstalled;

  /// No description provided for @downloadsInstalledCount.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{скачан {n} регион} few{скачано {n} региона} many{скачано {n} регионов} other{скачано {n} региона}}'**
  String downloadsInstalledCount(int n);

  /// No description provided for @routeBannerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Готовая прогулка по городу'**
  String get routeBannerTitle;

  /// No description provided for @routeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Прогулка по городу {city}'**
  String routeTitle(String city);

  /// No description provided for @routeAbout.
  ///
  /// In ru, this message translates to:
  /// **'около {hours} ч'**
  String routeAbout(String hours);

  /// No description provided for @routeDistance.
  ///
  /// In ru, this message translates to:
  /// **'{km} км'**
  String routeDistance(String km);

  /// No description provided for @routeStops.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} остановка} few{{n} остановки} many{{n} остановок} other{{n} остановки}}'**
  String routeStops(int n);

  /// No description provided for @routeEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В этой прогулке нет остановок'**
  String get routeEmpty;

  /// No description provided for @routeNote.
  ///
  /// In ru, this message translates to:
  /// **'Порядок и время приблизительные: расстояние считается по прямой с поправкой на улицы, а время осмотра — по типу места. Чтобы проложить дорогу, используйте кнопку карты в карточке места.'**
  String get routeNote;

  /// No description provided for @offerTitle.
  ///
  /// In ru, this message translates to:
  /// **'Вы в регионе {region}'**
  String offerTitle(String region);

  /// No description provided for @offerSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'{n} фотографий этих мест · {mb} МБ'**
  String offerSubtitle(int n, String mb);

  /// No description provided for @offerLater.
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get offerLater;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsContent.
  ///
  /// In ru, this message translates to:
  /// **'Контент'**
  String get settingsContent;

  /// No description provided for @settingsAutoWifi.
  ///
  /// In ru, this message translates to:
  /// **'Скачивать регионы автоматически'**
  String get settingsAutoWifi;

  /// No description provided for @settingsAutoWifiDetail.
  ///
  /// In ru, this message translates to:
  /// **'Только по Wi-Fi. Мобильный трафик не тратится никогда.'**
  String get settingsAutoWifiDetail;

  /// No description provided for @settingsWifiNow.
  ///
  /// In ru, this message translates to:
  /// **'Wi-Fi подключён'**
  String get settingsWifiNow;

  /// No description provided for @settingsWifiNo.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас Wi-Fi нет'**
  String get settingsWifiNo;

  /// No description provided for @settingsProfileSection.
  ///
  /// In ru, this message translates to:
  /// **'Ваши интересы'**
  String get settingsProfileSection;

  /// No description provided for @settingsNoInterests.
  ///
  /// In ru, this message translates to:
  /// **'Не указаны'**
  String get settingsNoInterests;

  /// No description provided for @settingsResetOffers.
  ///
  /// In ru, this message translates to:
  /// **'Снова показывать предложения'**
  String get settingsResetOffers;

  /// No description provided for @settingsResetOffersDetail.
  ///
  /// In ru, this message translates to:
  /// **'Регионы, от которых вы отказались, предложим ещё раз'**
  String get settingsResetOffersDetail;

  /// No description provided for @settingsResetDone.
  ///
  /// In ru, this message translates to:
  /// **'Предложения возвращены'**
  String get settingsResetDone;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @distanceMeters.
  ///
  /// In ru, this message translates to:
  /// **'{n} м'**
  String distanceMeters(int n);

  /// No description provided for @distanceKm.
  ///
  /// In ru, this message translates to:
  /// **'{km} км'**
  String distanceKm(String km);

  /// No description provided for @compassN.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get compassN;

  /// No description provided for @compassNE.
  ///
  /// In ru, this message translates to:
  /// **'СВ'**
  String get compassNE;

  /// No description provided for @compassE.
  ///
  /// In ru, this message translates to:
  /// **'В'**
  String get compassE;

  /// No description provided for @compassSE.
  ///
  /// In ru, this message translates to:
  /// **'ЮВ'**
  String get compassSE;

  /// No description provided for @compassS.
  ///
  /// In ru, this message translates to:
  /// **'Ю'**
  String get compassS;

  /// No description provided for @compassSW.
  ///
  /// In ru, this message translates to:
  /// **'ЮЗ'**
  String get compassSW;

  /// No description provided for @compassW.
  ///
  /// In ru, this message translates to:
  /// **'З'**
  String get compassW;

  /// No description provided for @compassNW.
  ///
  /// In ru, this message translates to:
  /// **'СЗ'**
  String get compassNW;

  /// No description provided for @gpxExport.
  ///
  /// In ru, this message translates to:
  /// **'Взять с собой'**
  String get gpxExport;

  /// No description provided for @gpxDescription.
  ///
  /// In ru, this message translates to:
  /// **'Создано в Norway Explore. Порядок остановок и время приблизительные.'**
  String get gpxDescription;

  /// No description provided for @gpxFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось передать файл'**
  String get gpxFailed;

  /// No description provided for @exportSheetTitle.
  ///
  /// In ru, this message translates to:
  /// **'Взять маршрут с собой'**
  String get exportSheetTitle;

  /// No description provided for @exportSheetWhat.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняет остановки файлом, который откроют другие приложения и проведут вас по точкам. Наш путеводитель показывает только порядок обхода, он не ведёт по дороге.'**
  String get exportSheetWhat;

  /// No description provided for @exportSheetApps.
  ///
  /// In ru, this message translates to:
  /// **'Навигаторы: OsmAnd, Komoot, Gaia GPS, Organic Maps'**
  String get exportSheetApps;

  /// No description provided for @exportSheetWatches.
  ///
  /// In ru, this message translates to:
  /// **'Спортивные часы: Garmin, Suunto, Polar'**
  String get exportSheetWatches;

  /// No description provided for @exportSheetNot.
  ///
  /// In ru, this message translates to:
  /// **'В файле точки, а не дорога. Путь между ними навигатор проложит сам.'**
  String get exportSheetNot;

  /// No description provided for @exportSheetSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить файл'**
  String get exportSheetSend;

  /// No description provided for @exportSheetCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get exportSheetCancel;

  /// No description provided for @usageTitle.
  ///
  /// In ru, this message translates to:
  /// **'Как вы пользуетесь приложением'**
  String get usageTitle;

  /// No description provided for @usageNote.
  ///
  /// In ru, this message translates to:
  /// **'Эти числа остаются на вашем телефоне. Никуда не отправляются — ни нам, ни кому-либо ещё. Стереть их можно в любой момент.'**
  String get usageNote;

  /// No description provided for @usageLaunches.
  ///
  /// In ru, this message translates to:
  /// **'Запусков'**
  String get usageLaunches;

  /// No description provided for @usagePlaces.
  ///
  /// In ru, this message translates to:
  /// **'Открыто мест'**
  String get usagePlaces;

  /// No description provided for @usageRoutes.
  ///
  /// In ru, this message translates to:
  /// **'Открыто прогулок'**
  String get usageRoutes;

  /// No description provided for @usageSearches.
  ///
  /// In ru, this message translates to:
  /// **'Поисков'**
  String get usageSearches;

  /// No description provided for @usagePacks.
  ///
  /// In ru, this message translates to:
  /// **'Скачано регионов'**
  String get usagePacks;

  /// No description provided for @usageSince.
  ///
  /// In ru, this message translates to:
  /// **'Пользуетесь'**
  String get usageSince;

  /// No description provided for @usageDays.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, =0{сегодня} one{{n} день} few{{n} дня} many{{n} дней} other{{n} дня}}'**
  String usageDays(int n);

  /// No description provided for @usageReset.
  ///
  /// In ru, this message translates to:
  /// **'Стереть эти числа'**
  String get usageReset;

  /// No description provided for @usageResetDetail.
  ///
  /// In ru, this message translates to:
  /// **'Счётчики начнутся с нуля'**
  String get usageResetDetail;

  /// No description provided for @usageResetDone.
  ///
  /// In ru, this message translates to:
  /// **'Числа стёрты'**
  String get usageResetDone;

  /// No description provided for @settingsUsage.
  ///
  /// In ru, this message translates to:
  /// **'Как вы пользуетесь приложением'**
  String get settingsUsage;

  /// No description provided for @ratingPrompt.
  ///
  /// In ru, this message translates to:
  /// **'Оцените это место'**
  String get ratingPrompt;

  /// No description provided for @ratingYours.
  ///
  /// In ru, this message translates to:
  /// **'Ваша оценка'**
  String get ratingYours;

  /// No description provided for @ratingVisited.
  ///
  /// In ru, this message translates to:
  /// **'отмечено как посещённое'**
  String get ratingVisited;

  /// No description provided for @ratingPrivate.
  ///
  /// In ru, this message translates to:
  /// **'Это видите только вы. Никуда не отправляется.'**
  String get ratingPrivate;

  /// No description provided for @alertsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Погодные предупреждения'**
  String get alertsTitle;

  /// No description provided for @alertsNone.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас предупреждений для вашего района нет'**
  String get alertsNone;

  /// No description provided for @alertsMore.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{ещё {n} предупреждение} few{ещё {n} предупреждения} many{ещё {n} предупреждений} other{ещё {n} предупреждения}}'**
  String alertsMore(int n);

  /// No description provided for @alertsMarine.
  ///
  /// In ru, this message translates to:
  /// **'на море'**
  String get alertsMarine;

  /// No description provided for @alertsUntil.
  ///
  /// In ru, this message translates to:
  /// **'До {time}'**
  String alertsUntil(String time);

  /// No description provided for @alertsSource.
  ///
  /// In ru, this message translates to:
  /// **'Официальные предупреждения: погода — Норвежский метеорологический институт (MET Norway), лавинная опасность — NVE (varsom.no).'**
  String get alertsSource;

  /// No description provided for @alertsFetched.
  ///
  /// In ru, this message translates to:
  /// **'Получено в {time}'**
  String alertsFetched(String time);

  /// No description provided for @sortTooltip.
  ///
  /// In ru, this message translates to:
  /// **'Сортировка'**
  String get sortTooltip;

  /// No description provided for @sortByRating.
  ///
  /// In ru, this message translates to:
  /// **'Сначала известные'**
  String get sortByRating;

  /// No description provided for @sortByDistance.
  ///
  /// In ru, this message translates to:
  /// **'Сначала ближние'**
  String get sortByDistance;

  /// No description provided for @sortByName.
  ///
  /// In ru, this message translates to:
  /// **'По названию'**
  String get sortByName;

  /// No description provided for @tripTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моя поездка'**
  String get tripTitle;

  /// No description provided for @tripCardTitle.
  ///
  /// In ru, this message translates to:
  /// **'Моя поездка\nпо Норвегии'**
  String get tripCardTitle;

  /// No description provided for @tripAddPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото'**
  String get tripAddPhoto;

  /// No description provided for @tripTakePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Сделать снимок'**
  String get tripTakePhoto;

  /// No description provided for @tripFromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать из галереи'**
  String get tripFromGallery;

  /// No description provided for @tripShare.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться картинкой'**
  String get tripShare;

  /// No description provided for @tripShareFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось собрать картинку'**
  String get tripShareFailed;

  /// No description provided for @tripPhotoFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить снимок'**
  String get tripPhotoFailed;

  /// No description provided for @tripPlacesVisited.
  ///
  /// In ru, this message translates to:
  /// **'мест посещено'**
  String get tripPlacesVisited;

  /// No description provided for @tripPhotosTaken.
  ///
  /// In ru, this message translates to:
  /// **'снимков сделано'**
  String get tripPhotosTaken;

  /// No description provided for @tripPhotos.
  ///
  /// In ru, this message translates to:
  /// **'{n, plural, one{{n} снимок} few{{n} снимка} many{{n} снимков} other{{n} снимка}}'**
  String tripPhotos(int n);

  /// No description provided for @tripPhotoRemove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать этот снимок?'**
  String get tripPhotoRemove;

  /// No description provided for @tripPhotoRemoveDetail.
  ///
  /// In ru, this message translates to:
  /// **'Он удалится из поездки и из папки приложения. Оригинал в галерее телефона останется.'**
  String get tripPhotoRemoveDetail;

  /// No description provided for @tripEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Здесь начнётся ваша поездка'**
  String get tripEmptyTitle;

  /// No description provided for @tripEmptyDetail.
  ///
  /// In ru, this message translates to:
  /// **'Снимайте по дороге и отмечайте места, где побывали. В конце получится карта поездки — одна картинка, которой можно поделиться.'**
  String get tripEmptyDetail;

  /// No description provided for @tripOpen.
  ///
  /// In ru, this message translates to:
  /// **'Моя поездка'**
  String get tripOpen;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'no',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return LDe();
    case 'en':
      return LEn();
    case 'es':
      return LEs();
    case 'no':
      return LNo();
    case 'ru':
      return LRu();
    case 'zh':
      return LZh();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
