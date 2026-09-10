// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class LRu extends L {
  LRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Норвегия';

  @override
  String get appTagline => 'Фьорды, водопады и города — без интернета';

  @override
  String get nearbyTitle => 'Что рядом со мной';

  @override
  String get nearbySubtitle => 'Ближайшие места с расстоянием и направлением';

  @override
  String get browseTitle => 'Куда поехать';

  @override
  String get browseSubtitle => 'Города и достопримечательности страны';

  @override
  String get favoritesTitle => 'Моя поездка';

  @override
  String favoritesSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мест сохранено',
      few: '$count места сохранено',
      one: '$count место сохранено',
    );
    return '$_temp0';
  }

  @override
  String get sourcesTitle => 'Источники и лицензии';

  @override
  String get sourcesTooltip => 'Об источниках';

  @override
  String photoBy(String credit) {
    return 'Фото: $credit';
  }

  @override
  String get nearbyScreenTitle => 'Рядом со мной';

  @override
  String nearbyScreenTitleAt(String city) {
    return 'Рядом: $city';
  }

  @override
  String get searchTooltip => 'Поиск';

  @override
  String get setCityTooltip => 'Указать город';

  @override
  String get useGpsTooltip => 'Определить по GPS';

  @override
  String get interestsTooltip => 'Мои интересы';

  @override
  String get locationUnknown =>
      'Положение неизвестно. Нажмите, чтобы указать город';

  @override
  String get nothingInFilters => 'Ничего не найдено по выбранным фильтрам';

  @override
  String get loadError => 'Не удалось загрузить места';

  @override
  String get otherLanguageShort => 'На другом языке';

  @override
  String get descriptionOtherLanguage =>
      'Перевода пока нет — текст на языке источника';

  @override
  String get tabCities => 'Города';

  @override
  String get tabPlaces => 'Места';

  @override
  String get noCities => 'Городов в этой сборке данных нет';

  @override
  String get nothingInCategories => 'По выбранным категориям ничего не нашлось';

  @override
  String shownOf(int shown, int total) {
    return 'Показано $shown из $total';
  }

  @override
  String get resetFilter => 'Сбросить';

  @override
  String placesCount(int count) {
    return '$count мест';
  }

  @override
  String get cityLarge => 'Крупный город';

  @override
  String get cityMedium => 'Город';

  @override
  String get citySmall => 'Небольшой город';

  @override
  String get cityVillage => 'Посёлок';

  @override
  String get cityHamlet => 'Небольшой посёлок';

  @override
  String get cityTourist => 'Туристическое место';

  @override
  String get cityGeneric => 'Населённый пункт';

  @override
  String get noPlacesInCity => 'Для этого города мест пока нет';

  @override
  String get placeNotFound => 'Место не найдено';

  @override
  String get noDescription =>
      'Описания для этого места пока нет. Координаты и маршрут работают — можно доехать и посмотреть самому.';

  @override
  String get noDescriptionShort => 'Описание пока не загружено';

  @override
  String get routeButton => 'Проложить маршрут';

  @override
  String get mapsFailed => 'Не удалось открыть карты. Нужен интернет.';

  @override
  String get addToFavorites => 'В избранное';

  @override
  String get removeFromFavorites => 'Убрать из избранного';

  @override
  String get factOpeningHours => 'Часы работы';

  @override
  String get factFee => 'Вход';

  @override
  String get factDifficulty => 'Сложность';

  @override
  String get factDuration => 'Время';

  @override
  String factMinutes(int count) {
    return '$count мин';
  }

  @override
  String get factSeason => 'Сезон';

  @override
  String get factWebsite => 'Сайт';

  @override
  String get searchHint => 'Место, город, водопад…';

  @override
  String get searchPrompt => 'Введите хотя бы две буквы';

  @override
  String get searchPromptDetail =>
      'Ищем на языке интерфейса, норвежском и английском одновременно — можно набирать так, как написано на указателе.';

  @override
  String searchNothing(String query) {
    return 'По запросу «$query» ничего не нашлось';
  }

  @override
  String get searchNothingDetail =>
      'Описания есть не у всех мест. Попробуйте норвежское написание или часть слова.';

  @override
  String get searchError => 'Ошибка поиска';

  @override
  String get favoritesWant => 'Хочу посмотреть';

  @override
  String get favoritesVisited => 'Уже был';

  @override
  String get favoritesEmpty => 'Здесь пока пусто';

  @override
  String get favoritesEmptyDetail =>
      'Нажмите сердечко на карточке места — оно попадёт сюда. Можно отмечать посещённые и оставлять заметки.';

  @override
  String get noteTooltip => 'Заметка';

  @override
  String get noteHint => 'Во сколько открывается, где парковка, что взять…';

  @override
  String get markVisited => 'Был здесь';

  @override
  String get markNotVisited => 'Не был';

  @override
  String removedFromTrip(String place) {
    return '$place убрано из поездки';
  }

  @override
  String get undo => 'Вернуть';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get emergencyTitle => 'Экстренная помощь';

  @override
  String get emergencyTooltip => 'Экстренная помощь';

  @override
  String get emergencyOther => 'Другие службы';

  @override
  String get emergencyKnow => 'Что важно знать';

  @override
  String get emergencyCoordinates => 'Ваши координаты';

  @override
  String get emergencyCopy => 'Скопировать';

  @override
  String get emergencyCopied => 'Координаты скопированы';

  @override
  String get emergencyManualPosition => 'Положение задано вручную — не по GPS';

  @override
  String emergencyDial(String service, String number) {
    return '$service: наберите $number';
  }

  @override
  String get whereAreYou => 'Где вы находитесь?';

  @override
  String get cityHint => 'Город: Берген, Oslo, Tromsø…';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get profileQuestion => 'Что вам интереснее всего?';

  @override
  String get profileQuestionDetail =>
      'Подберём, что показывать первым. Ничего не спрячем — весь каталог остаётся доступен через поиск.';

  @override
  String get profileWhen => 'Когда планируете поездку?';

  @override
  String get profileWhenDetail =>
      'Горные дороги и часть троп закрыты зимой — не будем предлагать то, куда сейчас не проехать.';

  @override
  String get profileNow => 'Я сейчас в Норвегии';

  @override
  String get profileSoon => 'В ближайшие месяцы';

  @override
  String get profileBrowsing => 'Просто смотрю';

  @override
  String get profileSkip => 'Пропустить';

  @override
  String get profileNext => 'Дальше';

  @override
  String profileDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Готово — учли $count интереса в порядке выдачи',
      one: 'Готово — подходящие места теперь выше в списке',
    );
    return '$_temp0';
  }

  @override
  String get catMuseums => 'Музеи';

  @override
  String get catViewpoints => 'Смотровые';

  @override
  String get catFjords => 'Фьорды';

  @override
  String get catWaterfalls => 'Водопады';

  @override
  String get catChurches => 'Церкви';

  @override
  String get catHikes => 'Тропы';

  @override
  String get catGlaciers => 'Ледники';

  @override
  String get catBeaches => 'Пляжи';

  @override
  String get catMuseum => 'Музей';

  @override
  String get catViewpoint => 'Смотровая';

  @override
  String get catFjord => 'Фьорд';

  @override
  String get catWaterfall => 'Водопад';

  @override
  String get catChurch => 'Церковь';

  @override
  String get catHike => 'Тропа';

  @override
  String get catGlacier => 'Ледник';

  @override
  String get catBeach => 'Пляж';

  @override
  String get catOther => 'Место';

  @override
  String get emgAmbulance => 'Скорая помощь';

  @override
  String get emgAmbulanceSub => 'Ambulanse · угроза жизни, тяжёлая травма';

  @override
  String get emgPolice => 'Полиция';

  @override
  String get emgPoliceSub => 'Politi · преступление, авария, пропал человек';

  @override
  String get emgFire => 'Пожарная служба';

  @override
  String get emgFireSub => 'Brann · пожар, задымление, утечка газа';

  @override
  String get emgDoctor => 'Дежурный врач';

  @override
  String get emgDoctorSub => 'Legevakt · срочно, но жизни ничто не угрожает';

  @override
  String get emgSea => 'Спасение на воде';

  @override
  String get emgSeaSub => 'Hovedredningssentralen · происшествие в море';

  @override
  String get emgPoison => 'Отравления';

  @override
  String get emgPoisonSub => 'Giftinformasjonen · круглосуточно';

  @override
  String get emgRoad => 'Дорожная служба';

  @override
  String get emgRoadSub => 'Vegtrafikksentralen · перекрытые дороги, лавины';

  @override
  String get emgNoteSimTitle => 'Работает без сети и без SIM';

  @override
  String get emgNoteSimBody =>
      'Звонок на 112 и 113 проходит через любую доступную вышку, даже если у вашего оператора нет покрытия и в телефоне нет SIM-карты.';

  @override
  String get emgNoteCoordsTitle => 'Назовите координаты';

  @override
  String get emgNoteCoordsBody =>
      'В горах и на фьордах адреса нет. Продиктуйте широту и долготу — они ниже на этом экране, их можно скопировать. Оператор поймёт.';

  @override
  String get emgNoteEnglishTitle => 'Английский понимают';

  @override
  String get emgNoteEnglishBody =>
      'Операторы экстренных служб Норвегии говорят по-английски. Говорите спокойно и коротко: что случилось, где, сколько пострадавших.';

  @override
  String get emgNoteMountainTitle => 'В горах — 112';

  @override
  String get emgNoteMountainBody =>
      'Спасением в горах занимается полиция, отдельного номера нет. Не выключайте телефон: по нему вас будут искать.';

  @override
  String get emgVerified =>
      'Номера действительны для Норвегии. Проверены 10.09.2026 по источникам politiet.no, helsenorge.no, hovedredningssentralen.no.';
}
