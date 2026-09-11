// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class LRu extends L {
  LRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Norway Explore';

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

  @override
  String get onboardingTitle => 'Что вас интересует в Норвегии?';

  @override
  String get onboardingSubtitle =>
      'Отметьте всё, что подходит — подберём, что показывать первым.';

  @override
  String get onboardingNothingHidden =>
      'Ничего не спрячем: полный каталог мест остаётся доступен через поиск и фильтры.';

  @override
  String get onboardingStart => 'Начать';

  @override
  String get intNature => 'Природа и виды';

  @override
  String get intHiking => 'Походы и треккинг';

  @override
  String get intFishing => 'Рыбалка';

  @override
  String get intHunting => 'Охота';

  @override
  String get intCulture => 'Музеи и культура';

  @override
  String get intPhoto => 'Фотография';

  @override
  String get intKids => 'С детьми';

  @override
  String get intRoadtrip => 'Автопутешествие';

  @override
  String get intWinter => 'Зимний спорт';

  @override
  String get intCruise => 'Круиз, несколько часов';

  @override
  String get rulesTitle => 'Правила и лицензии';

  @override
  String get rulesWhereToCheck => 'Где проверить';

  @override
  String rulesKommune(String name) {
    return 'Коммуна $name';
  }

  @override
  String rulesCheckedAt(String date) {
    return 'Данные получены $date';
  }

  @override
  String get rulesCallKommune => 'Позвонить в коммуну';

  @override
  String get rulesOpenSite => 'Сайт коммуны';

  @override
  String get rulesDisclaimer =>
      'Приложение не выдаёт разрешений и не может сказать, разрешён ли лов или охота именно здесь. Это зависит от коммуны, владельца участка, сезона и вида. Перед выездом уточните в коммуне или у владельца.';

  @override
  String get rulesNational => 'Общие правила по стране';

  @override
  String rulesSource(String authority) {
    return 'Источник: $authority';
  }

  @override
  String get rulesFishing => 'Рыбалка';

  @override
  String get rulesHunting => 'Охота';

  @override
  String get rulesNoKommune =>
      'Коммуна для этой точки не определена. На Шпицбергене правила устанавливает губернатор (Sysselmesteren), а не коммуна.';

  @override
  String get promptTitle => 'Что вас интересует?';

  @override
  String get promptSubtitle =>
      'Рыбалка, походы, музеи — подберём, что показывать';

  @override
  String get modeTourist => 'Всё подряд';

  @override
  String get modeFishing => 'Рыбалка';

  @override
  String get modeHunting => 'Охота';

  @override
  String get modeSwitch => 'Режим';

  @override
  String get modeFishingHint =>
      'Показаны места для рыбалки. Города и достопримечательности скрыты — вернуть их можно кнопкой режима.';

  @override
  String get modeHuntingHint =>
      'Показаны природные места. Охотничьи угодья на карте не размечены — главное здесь правила и коммуна.';

  @override
  String get modeRulesButton => 'Правила и лицензии';

  @override
  String get locServiceOff => 'Геолокация выключена в настройках телефона';

  @override
  String get locDenied => 'Нет доступа к местоположению';

  @override
  String get locDeniedForever =>
      'Доступ к местоположению запрещён. Разрешить можно в настройках приложения';

  @override
  String get locUnavailable =>
      'Не удалось определить местоположение. В помещении сигнал слабый';

  @override
  String get locOpenSettings => 'Настройки';

  @override
  String get locSetCity => 'Указать город';

  @override
  String get locRetry => 'Повторить';

  @override
  String get nothingNearby => 'Рядом ничего нет';

  @override
  String get nothingNearbyHint =>
      'В путеводитель попадают только места с описанием или фотографией. Вокруг вас таких сейчас нет.';

  @override
  String get nothingInFiltersHint =>
      'Попробуйте убрать категорию — рядом могут быть другие места.';

  @override
  String get resetFilters => 'Показать все категории';

  @override
  String get mostVisitedTitle => 'Самое посещаемое';

  @override
  String get mostVisitedSubtitle =>
      'Двадцать пять мест, ради которых едут в Норвегию';

  @override
  String get mostVisitedEmpty => 'Топ-списка нет в этом пакете контента';

  @override
  String get mostVisitedNote =>
      'Порядок составлен вручную: по числу посетителей, статусу ЮНЕСКО и известности места. Там, где показано число посетителей, год и источник указаны в карточке места.';

  @override
  String get unescoShort => 'ЮНЕСКО';

  @override
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n фотографии',
      many: '$n фотографий',
      few: '$n фотографии',
      one: '$n фотография',
    );
    return '$_temp0';
  }

  @override
  String visitorsPerYear(int n, String year) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Около $nString посетителей в год ($year)';
  }

  @override
  String get profileDoneButton => 'Готово';

  @override
  String get downloadsTitle => 'Скачать перед поездкой';

  @override
  String get downloadsNote =>
      'Фотографии качаются по регионам, чтобы приложение оставалось лёгким. Ничего не скачивается само — путеводитель не тратит ваш трафик без спроса.';

  @override
  String downloadsBuiltAt(String date) {
    return 'Данные собраны $date';
  }

  @override
  String downloadsPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n фотографии',
      many: '$n фотографий',
      few: '$n фотографии',
      one: '$n фотография',
    );
    return '$_temp0';
  }

  @override
  String get downloadsStart => 'Скачать';

  @override
  String get downloadsRemove => 'Удалить';

  @override
  String get downloadsUpdateAvailable => 'Доступна более новая версия';

  @override
  String get downloadsFailed => 'Не удалось скачать';

  @override
  String get downloadsOffline => 'Нет связи с сервером контента';

  @override
  String get downloadsNothingInstalled =>
      'Пока ничего не скачано. Места работают — не хватает только дополнительных фотографий.';

  @override
  String downloadsInstalledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'скачано $n региона',
      many: 'скачано $n регионов',
      few: 'скачано $n региона',
      one: 'скачан $n регион',
    );
    return '$_temp0';
  }

  @override
  String get routeBannerTitle => 'Готовая прогулка по городу';

  @override
  String routeTitle(String city) {
    return 'Прогулка по городу $city';
  }

  @override
  String routeAbout(String hours) {
    return 'около $hours ч';
  }

  @override
  String routeDistance(String km) {
    return '$km км';
  }

  @override
  String routeStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n остановки',
      many: '$n остановок',
      few: '$n остановки',
      one: '$n остановка',
    );
    return '$_temp0';
  }

  @override
  String get routeEmpty => 'В этой прогулке нет остановок';

  @override
  String get routeNote =>
      'Порядок и время приблизительные: расстояние считается по прямой с поправкой на улицы, а время осмотра — по типу места. Чтобы проложить дорогу, используйте кнопку карты в карточке места.';

  @override
  String offerTitle(String region) {
    return 'Вы в регионе $region';
  }

  @override
  String offerSubtitle(int n, String mb) {
    return '$n фотографий этих мест · $mb МБ';
  }

  @override
  String get offerLater => 'Не сейчас';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsContent => 'Контент';

  @override
  String get settingsAutoWifi => 'Скачивать регионы автоматически';

  @override
  String get settingsAutoWifiDetail =>
      'Только по Wi-Fi. Мобильный трафик не тратится никогда.';

  @override
  String get settingsWifiNow => 'Wi-Fi подключён';

  @override
  String get settingsWifiNo => 'Сейчас Wi-Fi нет';

  @override
  String get settingsProfileSection => 'Ваши интересы';

  @override
  String get settingsNoInterests => 'Не указаны';

  @override
  String get settingsResetOffers => 'Снова показывать предложения';

  @override
  String get settingsResetOffersDetail =>
      'Регионы, от которых вы отказались, предложим ещё раз';

  @override
  String get settingsResetDone => 'Предложения возвращены';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String distanceMeters(int n) {
    return '$n м';
  }

  @override
  String distanceKm(String km) {
    return '$km км';
  }

  @override
  String get compassN => 'С';

  @override
  String get compassNE => 'СВ';

  @override
  String get compassE => 'В';

  @override
  String get compassSE => 'ЮВ';

  @override
  String get compassS => 'Ю';

  @override
  String get compassSW => 'ЮЗ';

  @override
  String get compassW => 'З';

  @override
  String get compassNW => 'СЗ';

  @override
  String get gpxExport => 'Взять с собой';

  @override
  String get gpxDescription =>
      'Создано в Norway Explore. Порядок остановок и время приблизительные.';

  @override
  String get gpxFailed => 'Не удалось передать файл';

  @override
  String get exportSheetTitle => 'Взять маршрут с собой';

  @override
  String get exportSheetWhat =>
      'Сохраняет остановки файлом, который откроют другие приложения и проведут вас по точкам. Наш путеводитель показывает только порядок обхода, он не ведёт по дороге.';

  @override
  String get exportSheetApps =>
      'Навигаторы: OsmAnd, Komoot, Gaia GPS, Organic Maps';

  @override
  String get exportSheetWatches => 'Спортивные часы: Garmin, Suunto, Polar';

  @override
  String get exportSheetNot =>
      'В файле точки, а не дорога. Путь между ними навигатор проложит сам.';

  @override
  String get exportSheetSend => 'Отправить файл';

  @override
  String get exportSheetCancel => 'Отмена';
}
