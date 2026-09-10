// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian (`no`).
class LNo extends L {
  LNo([String locale = 'no']) : super(locale);

  @override
  String get appTitle => 'Norge';

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
}
