// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class LNo extends L {
  LNo([String locale = 'no']) : super(locale);

  @override
  String get appTitle => 'Norway Explore';

  @override
  String get appTagline => 'Fjorder, fossefall og byer — uten nett';

  @override
  String get nearbyTitle => 'Hva er i nærheten';

  @override
  String get nearbySubtitle => 'Nære steder med avstand og retning';

  @override
  String get browseTitle => 'Hvor skal du';

  @override
  String get browseSubtitle => 'Byer og severdigheter i hele landet';

  @override
  String get favoritesTitle => 'Min tur';

  @override
  String favoritesSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steder lagret',
      one: '$count sted lagret',
    );
    return '$_temp0';
  }

  @override
  String get sourcesTitle => 'Kilder og lisenser';

  @override
  String get sourcesTooltip => 'Om kildene';

  @override
  String photoBy(String credit) {
    return 'Foto: $credit';
  }

  @override
  String get nearbyScreenTitle => 'I nærheten';

  @override
  String nearbyScreenTitleAt(String city) {
    return 'Nær $city';
  }

  @override
  String get searchTooltip => 'Søk';

  @override
  String get setCityTooltip => 'Velg sted';

  @override
  String get useGpsTooltip => 'Bruk GPS';

  @override
  String get interestsTooltip => 'Mine interesser';

  @override
  String get locationUnknown => 'Ukjent posisjon. Trykk for å velge sted';

  @override
  String get nothingInFilters => 'Ingenting passer de valgte filtrene';

  @override
  String get loadError => 'Kunne ikke laste steder';

  @override
  String get otherLanguageShort => 'Annet språk';

  @override
  String get descriptionOtherLanguage =>
      'Ingen oversettelse ennå — tekst på kildespråket';

  @override
  String get tabCities => 'Steder';

  @override
  String get tabPlaces => 'Severdigheter';

  @override
  String get noCities => 'Ingen steder i dette datasettet';

  @override
  String get nothingInCategories => 'Ingenting funnet i valgte kategorier';

  @override
  String shownOf(int shown, int total) {
    return 'Viser $shown av $total';
  }

  @override
  String get resetFilter => 'Nullstill';

  @override
  String placesCount(int count) {
    return '$count steder';
  }

  @override
  String get cityLarge => 'Storby';

  @override
  String get cityMedium => 'By';

  @override
  String get citySmall => 'Småby';

  @override
  String get cityVillage => 'Tettsted';

  @override
  String get cityHamlet => 'Lite tettsted';

  @override
  String get cityTourist => 'Turiststed';

  @override
  String get cityGeneric => 'Bosetting';

  @override
  String get noPlacesInCity => 'Ingen steder her ennå';

  @override
  String get placeNotFound => 'Fant ikke stedet';

  @override
  String get noDescription =>
      'Ingen beskrivelse ennå. Koordinater og veibeskrivelse virker — du kan dra og se selv.';

  @override
  String get noDescriptionShort => 'Beskrivelse ikke lastet';

  @override
  String get routeButton => 'Veibeskrivelse';

  @override
  String get mapsFailed => 'Kunne ikke åpne kart. Krever nett.';

  @override
  String get addToFavorites => 'Legg til i turen';

  @override
  String get removeFromFavorites => 'Fjern fra turen';

  @override
  String get factOpeningHours => 'Åpningstider';

  @override
  String get factFee => 'Inngang';

  @override
  String get factDifficulty => 'Vanskelighetsgrad';

  @override
  String get factDuration => 'Varighet';

  @override
  String factMinutes(int count) {
    return '$count min';
  }

  @override
  String get factSeason => 'Sesong';

  @override
  String get factWebsite => 'Nettsted';

  @override
  String get searchHint => 'Sted, by, foss…';

  @override
  String get searchPrompt => 'Skriv minst to bokstaver';

  @override
  String get searchPromptDetail =>
      'Vi søker på ditt språk, norsk og engelsk samtidig — skriv slik det står på skiltet.';

  @override
  String searchNothing(String query) {
    return 'Fant ingenting for «$query»';
  }

  @override
  String get searchNothingDetail =>
      'Ikke alle steder har beskrivelse. Prøv norsk skrivemåte eller deler av ordet.';

  @override
  String get searchError => 'Søkefeil';

  @override
  String get favoritesWant => 'Vil se';

  @override
  String get favoritesVisited => 'Har vært';

  @override
  String get favoritesEmpty => 'Ingenting her ennå';

  @override
  String get favoritesEmptyDetail =>
      'Trykk hjertet på et sted, så havner det her. Du kan krysse av besøkte steder og skrive notater.';

  @override
  String get noteTooltip => 'Notat';

  @override
  String get noteHint => 'Åpningstid, parkering, hva du bør ta med…';

  @override
  String get markVisited => 'Har vært her';

  @override
  String get markNotVisited => 'Ikke ennå';

  @override
  String removedFromTrip(String place) {
    return '$place fjernet fra turen';
  }

  @override
  String get undo => 'Angre';

  @override
  String get cancel => 'Avbryt';

  @override
  String get save => 'Lagre';

  @override
  String get emergencyTitle => 'Nødhjelp';

  @override
  String get emergencyTooltip => 'Nødhjelp';

  @override
  String get emergencyOther => 'Andre tjenester';

  @override
  String get emergencyKnow => 'Viktig å vite';

  @override
  String get emergencyCoordinates => 'Dine koordinater';

  @override
  String get emergencyCopy => 'Kopier';

  @override
  String get emergencyCopied => 'Koordinater kopiert';

  @override
  String get emergencyManualPosition => 'Posisjon valgt manuelt — ikke fra GPS';

  @override
  String emergencyDial(String service, String number) {
    return '$service: ring $number';
  }

  @override
  String get whereAreYou => 'Hvor er du?';

  @override
  String get cityHint => 'Sted: Bergen, Oslo, Tromsø…';

  @override
  String get nothingFound => 'Ingenting funnet';

  @override
  String get profileQuestion => 'Hva interesserer deg mest?';

  @override
  String get profileQuestionDetail =>
      'Vi velger hva som vises først. Ingenting skjules — hele katalogen er tilgjengelig via søk.';

  @override
  String get profileWhen => 'Når reiser du?';

  @override
  String get profileWhenDetail =>
      'Fjellveier og noen stier er stengt om vinteren — vi foreslår ikke steder du ikke kommer til nå.';

  @override
  String get profileNow => 'Jeg er i Norge nå';

  @override
  String get profileSoon => 'I løpet av de nærmeste månedene';

  @override
  String get profileBrowsing => 'Bare ser meg om';

  @override
  String get profileSkip => 'Hopp over';

  @override
  String get profileNext => 'Videre';

  @override
  String profileDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ferdig — $count interesser tatt hensyn til',
      one: 'Ferdig — passende steder ligger nå høyere',
    );
    return '$_temp0';
  }

  @override
  String get catMuseums => 'Museer';

  @override
  String get catViewpoints => 'Utsiktspunkter';

  @override
  String get catFjords => 'Fjorder';

  @override
  String get catWaterfalls => 'Fossefall';

  @override
  String get catChurches => 'Kirker';

  @override
  String get catHikes => 'Turstier';

  @override
  String get catGlaciers => 'Isbreer';

  @override
  String get catBeaches => 'Strender';

  @override
  String get catMuseum => 'Museum';

  @override
  String get catViewpoint => 'Utsiktspunkt';

  @override
  String get catFjord => 'Fjord';

  @override
  String get catWaterfall => 'Foss';

  @override
  String get catChurch => 'Kirke';

  @override
  String get catHike => 'Tursti';

  @override
  String get catGlacier => 'Isbre';

  @override
  String get catBeach => 'Strand';

  @override
  String get catOther => 'Sted';

  @override
  String get emgAmbulance => 'Ambulanse';

  @override
  String get emgAmbulanceSub => 'Ambulanse · livstruende, alvorlig skade';

  @override
  String get emgPolice => 'Politi';

  @override
  String get emgPoliceSub => 'Politi · kriminalitet, ulykke, savnet person';

  @override
  String get emgFire => 'Brannvesen';

  @override
  String get emgFireSub => 'Brann · brann, røyk, gasslekkasje';

  @override
  String get emgDoctor => 'Legevakt';

  @override
  String get emgDoctorSub => 'Legevakt · haster, men ikke livstruende';

  @override
  String get emgSea => 'Sjøredning';

  @override
  String get emgSeaSub => 'Hovedredningssentralen · hendelse til sjøs';

  @override
  String get emgPoison => 'Forgiftning';

  @override
  String get emgPoisonSub => 'Giftinformasjonen · døgnåpent';

  @override
  String get emgRoad => 'Veitrafikk';

  @override
  String get emgRoadSub => 'Vegtrafikksentralen · stengte veier, skred';

  @override
  String get emgNoteSimTitle => 'Virker uten nett og uten SIM';

  @override
  String get emgNoteSimBody =>
      'Anrop til 112 og 113 går via enhver tilgjengelig mast, også uten dekning fra din operatør og uten SIM-kort i telefonen.';

  @override
  String get emgNoteCoordsTitle => 'Oppgi koordinatene';

  @override
  String get emgNoteCoordsBody =>
      'I fjellet og på fjorden finnes ingen adresse. Les opp breddegrad og lengdegrad — de står nedenfor og kan kopieres.';

  @override
  String get emgNoteEnglishTitle => 'Engelsk forstås';

  @override
  String get emgNoteEnglishBody =>
      'Operatørene snakker engelsk. Vær rolig og kort: hva som har skjedd, hvor, hvor mange skadde.';

  @override
  String get emgNoteMountainTitle => 'I fjellet — 112';

  @override
  String get emgNoteMountainBody =>
      'Politiet leder redning i fjellet, det finnes ikke eget nummer. La telefonen stå på: den brukes til å finne deg.';

  @override
  String get emgVerified =>
      'Numrene gjelder Norge. Kontrollert 10.09.2026 mot politiet.no, helsenorge.no, hovedredningssentralen.no.';

  @override
  String get onboardingTitle => 'Hva er du ute etter i Norge?';

  @override
  String get onboardingSubtitle =>
      'Velg alt som passer — vi velger hva som vises først.';

  @override
  String get onboardingNothingHidden =>
      'Ingenting skjules: hele katalogen er tilgjengelig via søk og filtre.';

  @override
  String get onboardingStart => 'Start';

  @override
  String get intNature => 'Natur og utsikt';

  @override
  String get intHiking => 'Fottur og trekking';

  @override
  String get intFishing => 'Fiske';

  @override
  String get intHunting => 'Jakt';

  @override
  String get intCulture => 'Museer og kultur';

  @override
  String get intPhoto => 'Fotografering';

  @override
  String get intKids => 'Med barn';

  @override
  String get intRoadtrip => 'Bilferie';

  @override
  String get intWinter => 'Vintersport';

  @override
  String get intCruise => 'Cruise, noen timer i land';

  @override
  String get rulesTitle => 'Regler og lisenser';

  @override
  String get rulesWhereToCheck => 'Hvor du sjekker';

  @override
  String rulesKommune(String name) {
    return '$name kommune';
  }

  @override
  String rulesCheckedAt(String date) {
    return 'Data hentet $date';
  }

  @override
  String get rulesCallKommune => 'Ring kommunen';

  @override
  String get rulesOpenSite => 'Kommunens nettsted';

  @override
  String get rulesDisclaimer =>
      'Appen gir ingen tillatelser og kan ikke si om fiske eller jakt er tillatt akkurat her. Det avhenger av kommunen, grunneieren, sesongen og arten. Sjekk med kommunen eller grunneieren før du drar.';

  @override
  String get rulesNational => 'Nasjonale regler';

  @override
  String rulesSource(String authority) {
    return 'Kilde: $authority';
  }

  @override
  String get rulesFishing => 'Fiske';

  @override
  String get rulesHunting => 'Jakt';

  @override
  String get rulesNoKommune =>
      'Fant ingen kommune for dette punktet. På Svalbard fastsettes reglene av Sysselmesteren, ikke av en kommune.';

  @override
  String get promptTitle => 'Hva er du interessert i?';

  @override
  String get promptSubtitle =>
      'Fiske, fottur, museer — vi tilpasser det du ser';

  @override
  String get modeTourist => 'Alt';

  @override
  String get modeFishing => 'Fiske';

  @override
  String get modeHunting => 'Jakt';

  @override
  String get modeSwitch => 'Modus';

  @override
  String get modeFishingHint =>
      'Viser fiskeplasser. Byer og severdigheter er skjult — hent dem tilbake med modusknappen.';

  @override
  String get modeHuntingHint =>
      'Viser naturområder. Jaktterreng er ikke kartfestet — her er det reglene og kommunen som teller.';

  @override
  String get modeRulesButton => 'Regler og lisenser';

  @override
  String get locServiceOff => 'Posisjon er slått av i telefoninnstillingene';

  @override
  String get locDenied => 'Ingen tilgang til posisjon';

  @override
  String get locDeniedForever =>
      'Tilgang til posisjon er blokkert. Du kan tillate det i appinnstillingene';

  @override
  String get locUnavailable =>
      'Fant ikke posisjonen din. Innendørs er signalet svakt';

  @override
  String get locOpenSettings => 'Innstillinger';

  @override
  String get locSetCity => 'Velg sted';

  @override
  String get locRetry => 'Prøv igjen';

  @override
  String get nothingNearby => 'Ingenting i nærheten';

  @override
  String get nothingNearbyHint =>
      'Guiden dekker bare steder med beskrivelse eller bilde. Det finnes ingen rundt deg akkurat nå.';

  @override
  String get nothingInFiltersHint =>
      'Prøv å fjerne en kategori — det kan finnes andre steder i nærheten.';

  @override
  String get resetFilters => 'Vis alle kategorier';

  @override
  String get mostVisitedTitle => 'Mest besøkt';

  @override
  String get mostVisitedSubtitle =>
      'De tjuefem stedene folk reiser til Norge for';

  @override
  String get mostVisitedEmpty =>
      'Topplisten finnes ikke i denne innholdspakken';

  @override
  String get mostVisitedNote =>
      'Rekkefølgen er satt sammen manuelt ut fra besøkstall, UNESCO-status og hvor kjent stedet er. Der et besøkstall vises, står år og kilde i stedets kort.';

  @override
  String get unescoShort => 'UNESCO';

  @override
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bilder',
      one: '1 bilde',
    );
    return '$_temp0';
  }

  @override
  String visitorsPerYear(int n, String year) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Omtrent $nString besøkende i året ($year)';
  }
}
