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
  /// **'Норвегия'**
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
  /// **'{count, plural, one{{count} место сохранено} few{{count} места сохранено} other{{count} мест сохранено}}'**
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
  /// **'{count, plural, one{Готово — подходящие места теперь выше в списке} other{Готово — учли {count} интереса в порядке выдачи}}'**
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
