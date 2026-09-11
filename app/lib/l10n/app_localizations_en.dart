// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Norway Explore';

  @override
  String get appTagline => 'Fjords, waterfalls and towns — offline';

  @override
  String get nearbyTitle => 'What\'s around me';

  @override
  String get nearbySubtitle => 'Nearby places with distance and direction';

  @override
  String get browseTitle => 'Where to go';

  @override
  String get browseSubtitle => 'Towns and sights across the country';

  @override
  String get favoritesTitle => 'My trip';

  @override
  String favoritesSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places saved',
      one: '$count place saved',
    );
    return '$_temp0';
  }

  @override
  String get sourcesTitle => 'Sources and licences';

  @override
  String get sourcesTooltip => 'About the sources';

  @override
  String photoBy(String credit) {
    return 'Photo: $credit';
  }

  @override
  String get nearbyScreenTitle => 'Around me';

  @override
  String nearbyScreenTitleAt(String city) {
    return 'Around $city';
  }

  @override
  String get searchTooltip => 'Search';

  @override
  String get setCityTooltip => 'Set your town';

  @override
  String get useGpsTooltip => 'Use GPS';

  @override
  String get interestsTooltip => 'My interests';

  @override
  String get locationUnknown => 'Location unknown. Tap to choose a town';

  @override
  String get nothingInFilters => 'Nothing matches the selected filters';

  @override
  String get loadError => 'Could not load places';

  @override
  String get otherLanguageShort => 'Another language';

  @override
  String get descriptionOtherLanguage =>
      'No translation yet — text in the source language';

  @override
  String get tabCities => 'Towns';

  @override
  String get tabPlaces => 'Sights';

  @override
  String get noCities => 'No towns in this data build';

  @override
  String get nothingInCategories => 'Nothing found in the selected categories';

  @override
  String shownOf(int shown, int total) {
    return 'Showing $shown of $total';
  }

  @override
  String get resetFilter => 'Reset';

  @override
  String placesCount(int count) {
    return '$count places';
  }

  @override
  String get cityLarge => 'Large city';

  @override
  String get cityMedium => 'Town';

  @override
  String get citySmall => 'Small town';

  @override
  String get cityVillage => 'Village';

  @override
  String get cityHamlet => 'Hamlet';

  @override
  String get cityTourist => 'Tourist spot';

  @override
  String get cityGeneric => 'Settlement';

  @override
  String get noPlacesInCity => 'No places for this town yet';

  @override
  String get placeNotFound => 'Place not found';

  @override
  String get noDescription =>
      'No description for this place yet. Coordinates and directions work — you can go and see for yourself.';

  @override
  String get noDescriptionShort => 'Description not loaded yet';

  @override
  String get routeButton => 'Get directions';

  @override
  String get mapsFailed => 'Could not open maps. Internet required.';

  @override
  String get addToFavorites => 'Add to trip';

  @override
  String get removeFromFavorites => 'Remove from trip';

  @override
  String get factOpeningHours => 'Opening hours';

  @override
  String get factFee => 'Entry';

  @override
  String get factDifficulty => 'Difficulty';

  @override
  String get factDuration => 'Duration';

  @override
  String factMinutes(int count) {
    return '$count min';
  }

  @override
  String get factSeason => 'Season';

  @override
  String get factWebsite => 'Website';

  @override
  String get searchHint => 'Place, town, waterfall…';

  @override
  String get searchPrompt => 'Type at least two letters';

  @override
  String get searchPromptDetail =>
      'We search your language, Norwegian and English at once — type it the way it appears on the road sign.';

  @override
  String searchNothing(String query) {
    return 'Nothing found for “$query”';
  }

  @override
  String get searchNothingDetail =>
      'Not every place has a description. Try the Norwegian spelling or part of the word.';

  @override
  String get searchError => 'Search error';

  @override
  String get favoritesWant => 'Want to see';

  @override
  String get favoritesVisited => 'Been there';

  @override
  String get favoritesEmpty => 'Nothing here yet';

  @override
  String get favoritesEmptyDetail =>
      'Tap the heart on a place card and it lands here. You can mark visited places and add notes.';

  @override
  String get noteTooltip => 'Note';

  @override
  String get noteHint => 'Opening time, where to park, what to bring…';

  @override
  String get markVisited => 'Been here';

  @override
  String get markNotVisited => 'Not yet';

  @override
  String removedFromTrip(String place) {
    return '$place removed from the trip';
  }

  @override
  String get undo => 'Undo';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get emergencyTitle => 'Emergency';

  @override
  String get emergencyTooltip => 'Emergency';

  @override
  String get emergencyOther => 'Other services';

  @override
  String get emergencyKnow => 'What to know';

  @override
  String get emergencyCoordinates => 'Your coordinates';

  @override
  String get emergencyCopy => 'Copy';

  @override
  String get emergencyCopied => 'Coordinates copied';

  @override
  String get emergencyManualPosition => 'Location set manually — not from GPS';

  @override
  String emergencyDial(String service, String number) {
    return '$service: dial $number';
  }

  @override
  String get whereAreYou => 'Where are you?';

  @override
  String get cityHint => 'Town: Bergen, Oslo, Tromsø…';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get profileQuestion => 'What interests you most?';

  @override
  String get profileQuestionDetail =>
      'We\'ll pick what to show first. Nothing gets hidden — the full catalogue stays available through search.';

  @override
  String get profileWhen => 'When are you travelling?';

  @override
  String get profileWhenDetail =>
      'Mountain roads and some trails close in winter — we won\'t suggest places you can\'t reach right now.';

  @override
  String get profileNow => 'I\'m in Norway now';

  @override
  String get profileSoon => 'In the coming months';

  @override
  String get profileBrowsing => 'Just browsing';

  @override
  String get profileSkip => 'Skip';

  @override
  String get profileNext => 'Next';

  @override
  String profileDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Done — $count interests taken into account',
      one: 'Done — matching places now rank higher',
    );
    return '$_temp0';
  }

  @override
  String get catMuseums => 'Museums';

  @override
  String get catViewpoints => 'Viewpoints';

  @override
  String get catFjords => 'Fjords';

  @override
  String get catWaterfalls => 'Waterfalls';

  @override
  String get catChurches => 'Churches';

  @override
  String get catHikes => 'Trails';

  @override
  String get catGlaciers => 'Glaciers';

  @override
  String get catBeaches => 'Beaches';

  @override
  String get catMuseum => 'Museum';

  @override
  String get catViewpoint => 'Viewpoint';

  @override
  String get catFjord => 'Fjord';

  @override
  String get catWaterfall => 'Waterfall';

  @override
  String get catChurch => 'Church';

  @override
  String get catHike => 'Trail';

  @override
  String get catGlacier => 'Glacier';

  @override
  String get catBeach => 'Beach';

  @override
  String get catOther => 'Place';

  @override
  String get emgAmbulance => 'Ambulance';

  @override
  String get emgAmbulanceSub => 'Ambulanse · life-threatening, severe injury';

  @override
  String get emgPolice => 'Police';

  @override
  String get emgPoliceSub => 'Politi · crime, accident, missing person';

  @override
  String get emgFire => 'Fire brigade';

  @override
  String get emgFireSub => 'Brann · fire, smoke, gas leak';

  @override
  String get emgDoctor => 'On-call doctor';

  @override
  String get emgDoctorSub => 'Legevakt · urgent but not life-threatening';

  @override
  String get emgSea => 'Sea rescue';

  @override
  String get emgSeaSub => 'Hovedredningssentralen · incident at sea';

  @override
  String get emgPoison => 'Poisoning';

  @override
  String get emgPoisonSub => 'Giftinformasjonen · around the clock';

  @override
  String get emgRoad => 'Road service';

  @override
  String get emgRoadSub => 'Vegtrafikksentralen · closed roads, avalanches';

  @override
  String get emgNoteSimTitle => 'Works without network or SIM';

  @override
  String get emgNoteSimBody =>
      'Calls to 112 and 113 go through any available mast, even if your operator has no coverage and there is no SIM card in the phone.';

  @override
  String get emgNoteCoordsTitle => 'Give your coordinates';

  @override
  String get emgNoteCoordsBody =>
      'There are no addresses in the mountains or on the fjords. Read out the latitude and longitude — they are below on this screen and can be copied. The operator will understand.';

  @override
  String get emgNoteEnglishTitle => 'English is understood';

  @override
  String get emgNoteEnglishBody =>
      'Norwegian emergency operators speak English. Stay calm and be brief: what happened, where, how many injured.';

  @override
  String get emgNoteMountainTitle => 'In the mountains — 112';

  @override
  String get emgNoteMountainBody =>
      'Mountain rescue is run by the police; there is no separate number. Keep your phone on: they will use it to find you.';

  @override
  String get emgVerified =>
      'Numbers apply to Norway. Verified 10 Sep 2026 against politiet.no, helsenorge.no, hovedredningssentralen.no.';

  @override
  String get onboardingTitle => 'What brings you to Norway?';

  @override
  String get onboardingSubtitle =>
      'Pick everything that fits — we\'ll choose what to show first.';

  @override
  String get onboardingNothingHidden =>
      'Nothing gets hidden: the full catalogue stays available through search and filters.';

  @override
  String get onboardingStart => 'Start';

  @override
  String get intNature => 'Nature and views';

  @override
  String get intHiking => 'Hiking and trekking';

  @override
  String get intFishing => 'Fishing';

  @override
  String get intHunting => 'Hunting';

  @override
  String get intCulture => 'Museums and culture';

  @override
  String get intPhoto => 'Photography';

  @override
  String get intKids => 'With children';

  @override
  String get intRoadtrip => 'Road trip';

  @override
  String get intWinter => 'Winter sports';

  @override
  String get intCruise => 'Cruise, a few hours ashore';

  @override
  String get rulesTitle => 'Rules and licences';

  @override
  String get rulesWhereToCheck => 'Where to check';

  @override
  String rulesKommune(String name) {
    return '$name municipality';
  }

  @override
  String rulesCheckedAt(String date) {
    return 'Data retrieved $date';
  }

  @override
  String get rulesCallKommune => 'Call the municipality';

  @override
  String get rulesOpenSite => 'Municipality website';

  @override
  String get rulesDisclaimer =>
      'This app issues no permits and cannot tell you whether fishing or hunting is allowed at this exact spot. That depends on the municipality, the landowner, the season and the species. Check with the municipality or the owner before you go.';

  @override
  String get rulesNational => 'Nationwide rules';

  @override
  String rulesSource(String authority) {
    return 'Source: $authority';
  }

  @override
  String get rulesFishing => 'Fishing';

  @override
  String get rulesHunting => 'Hunting';

  @override
  String get rulesNoKommune =>
      'No municipality could be determined for this point. On Svalbard the rules are set by the Governor (Sysselmesteren), not a municipality.';

  @override
  String get promptTitle => 'What are you interested in?';

  @override
  String get promptSubtitle =>
      'Fishing, hiking, museums — we\'ll tailor what you see';

  @override
  String get modeTourist => 'Everything';

  @override
  String get modeFishing => 'Fishing';

  @override
  String get modeHunting => 'Hunting';

  @override
  String get modeSwitch => 'Mode';

  @override
  String get modeFishingHint =>
      'Showing fishing spots. Towns and sights are hidden — bring them back with the mode button.';

  @override
  String get modeHuntingHint =>
      'Showing natural areas. Hunting grounds are not mapped — what matters here are the rules and the municipality.';

  @override
  String get modeRulesButton => 'Rules and licences';

  @override
  String get locServiceOff => 'Location is turned off in phone settings';

  @override
  String get locDenied => 'No access to location';

  @override
  String get locDeniedForever =>
      'Location access is blocked. You can allow it in app settings';

  @override
  String get locUnavailable =>
      'Could not determine your location. Indoors the signal is weak';

  @override
  String get locOpenSettings => 'Settings';

  @override
  String get locSetCity => 'Choose a town';

  @override
  String get locRetry => 'Retry';

  @override
  String get nothingNearby => 'Nothing within reach';

  @override
  String get nothingNearbyHint =>
      'The guide only covers places with a description or a photo. There are none around you right now.';

  @override
  String get nothingInFiltersHint =>
      'Try removing a category — there may be other places nearby.';

  @override
  String get resetFilters => 'Show all categories';

  @override
  String get mostVisitedTitle => 'Most visited';

  @override
  String get mostVisitedSubtitle =>
      'The twenty-five places people come to Norway for';

  @override
  String get mostVisitedEmpty => 'The top list is not in this content package';

  @override
  String get mostVisitedNote =>
      'The order is compiled by hand from visitor numbers, UNESCO status and how widely a place is known. Where a visitor count is shown, its year and source are given in the place\'s card.';

  @override
  String get unescoShort => 'UNESCO';

  @override
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String visitorsPerYear(int n, String year) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'About $nString visitors a year ($year)';
  }

  @override
  String get profileDoneButton => 'Done';

  @override
  String get downloadsTitle => 'Download before the trip';

  @override
  String get downloadsNote =>
      'Photos are downloaded by region so the app stays small. Nothing is downloaded automatically — the guide never spends your data without you asking.';

  @override
  String downloadsBuiltAt(String date) {
    return 'Content prepared on $date';
  }

  @override
  String downloadsPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get downloadsStart => 'Download';

  @override
  String get downloadsRemove => 'Remove';

  @override
  String get downloadsUpdateAvailable => 'A newer version is available';

  @override
  String get downloadsFailed => 'Download failed';

  @override
  String get downloadsOffline => 'No connection to the content server';

  @override
  String get downloadsNothingInstalled =>
      'Nothing downloaded yet. Places still work — only extra photos are missing.';

  @override
  String downloadsInstalledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regions downloaded',
      one: '1 region downloaded',
    );
    return '$_temp0';
  }
}
