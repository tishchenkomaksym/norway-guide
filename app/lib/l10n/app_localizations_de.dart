// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class LDe extends L {
  LDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Norway Explore';

  @override
  String get appTagline => 'Fjorde, Wasserfälle und Städte — ohne Internet';

  @override
  String get nearbyTitle => 'Was ist in der Nähe';

  @override
  String get nearbySubtitle => 'Orte in der Nähe mit Entfernung und Richtung';

  @override
  String get browseTitle => 'Wohin es geht';

  @override
  String get browseSubtitle => 'Städte und Sehenswürdigkeiten im ganzen Land';

  @override
  String get favoritesTitle => 'Meine Reise';

  @override
  String favoritesSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Orte gespeichert',
      one: '$count Ort gespeichert',
    );
    return '$_temp0';
  }

  @override
  String get sourcesTitle => 'Quellen und Lizenzen';

  @override
  String get sourcesTooltip => 'Über die Quellen';

  @override
  String photoBy(String credit) {
    return 'Foto: $credit';
  }

  @override
  String get nearbyScreenTitle => 'In der Nähe';

  @override
  String nearbyScreenTitleAt(String city) {
    return 'Nahe $city';
  }

  @override
  String get searchTooltip => 'Suche';

  @override
  String get setCityTooltip => 'Ort festlegen';

  @override
  String get useGpsTooltip => 'GPS verwenden';

  @override
  String get interestsTooltip => 'Meine Interessen';

  @override
  String get locationUnknown =>
      'Position unbekannt. Tippen, um einen Ort zu wählen';

  @override
  String get nothingInFilters => 'Nichts passt zu den gewählten Filtern';

  @override
  String get loadError => 'Orte konnten nicht geladen werden';

  @override
  String get otherLanguageShort => 'Andere Sprache';

  @override
  String get descriptionOtherLanguage =>
      'Noch keine Übersetzung — Text in der Originalsprache';

  @override
  String get tabCities => 'Städte';

  @override
  String get tabPlaces => 'Sehenswürdigkeiten';

  @override
  String get noCities => 'Keine Städte in diesem Datenstand';

  @override
  String get nothingInCategories =>
      'In den gewählten Kategorien nichts gefunden';

  @override
  String shownOf(int shown, int total) {
    return '$shown von $total angezeigt';
  }

  @override
  String get resetFilter => 'Zurücksetzen';

  @override
  String placesCount(int count) {
    return '$count Orte';
  }

  @override
  String get cityLarge => 'Großstadt';

  @override
  String get cityMedium => 'Stadt';

  @override
  String get citySmall => 'Kleinstadt';

  @override
  String get cityVillage => 'Ortschaft';

  @override
  String get cityHamlet => 'Weiler';

  @override
  String get cityTourist => 'Touristenort';

  @override
  String get cityGeneric => 'Siedlung';

  @override
  String get noPlacesInCity => 'Für diesen Ort noch keine Einträge';

  @override
  String get placeNotFound => 'Ort nicht gefunden';

  @override
  String get noDescription =>
      'Noch keine Beschreibung. Koordinaten und Route funktionieren — Sie können hinfahren und selbst schauen.';

  @override
  String get noDescriptionShort => 'Beschreibung noch nicht geladen';

  @override
  String get routeButton => 'Route planen';

  @override
  String get mapsFailed =>
      'Karten konnten nicht geöffnet werden. Internet nötig.';

  @override
  String get addToFavorites => 'Zur Reise hinzufügen';

  @override
  String get removeFromFavorites => 'Aus der Reise entfernen';

  @override
  String get factOpeningHours => 'Öffnungszeiten';

  @override
  String get factFee => 'Eintritt';

  @override
  String get factDifficulty => 'Schwierigkeit';

  @override
  String get factDuration => 'Dauer';

  @override
  String factMinutes(int count) {
    return '$count Min.';
  }

  @override
  String get factSeason => 'Saison';

  @override
  String get factWebsite => 'Website';

  @override
  String get searchHint => 'Ort, Stadt, Wasserfall…';

  @override
  String get searchPrompt => 'Mindestens zwei Buchstaben eingeben';

  @override
  String get searchPromptDetail =>
      'Wir suchen gleichzeitig in Ihrer Sprache, auf Norwegisch und Englisch — schreiben Sie es so, wie es auf dem Schild steht.';

  @override
  String searchNothing(String query) {
    return 'Nichts gefunden für „$query“';
  }

  @override
  String get searchNothingDetail =>
      'Nicht jeder Ort hat eine Beschreibung. Versuchen Sie die norwegische Schreibweise oder einen Wortteil.';

  @override
  String get searchError => 'Fehler bei der Suche';

  @override
  String get favoritesWant => 'Möchte ich sehen';

  @override
  String get favoritesVisited => 'War ich schon';

  @override
  String get favoritesEmpty => 'Hier ist noch nichts';

  @override
  String get favoritesEmptyDetail =>
      'Tippen Sie auf das Herz bei einem Ort, dann landet er hier. Besuchte Orte lassen sich abhaken und mit Notizen versehen.';

  @override
  String get noteTooltip => 'Notiz';

  @override
  String get noteHint => 'Öffnungszeit, Parkplatz, was mitnehmen…';

  @override
  String get markVisited => 'War hier';

  @override
  String get markNotVisited => 'Noch nicht';

  @override
  String removedFromTrip(String place) {
    return '$place aus der Reise entfernt';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get emergencyTitle => 'Notfallhilfe';

  @override
  String get emergencyTooltip => 'Notfallhilfe';

  @override
  String get emergencyOther => 'Weitere Dienste';

  @override
  String get emergencyKnow => 'Wichtig zu wissen';

  @override
  String get emergencyCoordinates => 'Ihre Koordinaten';

  @override
  String get emergencyCopy => 'Kopieren';

  @override
  String get emergencyCopied => 'Koordinaten kopiert';

  @override
  String get emergencyManualPosition =>
      'Position manuell gesetzt — nicht per GPS';

  @override
  String emergencyDial(String service, String number) {
    return '$service: $number wählen';
  }

  @override
  String get whereAreYou => 'Wo befinden Sie sich?';

  @override
  String get cityHint => 'Ort: Bergen, Oslo, Tromsø…';

  @override
  String get nothingFound => 'Nichts gefunden';

  @override
  String get profileQuestion => 'Was interessiert Sie am meisten?';

  @override
  String get profileQuestionDetail =>
      'Wir wählen aus, was zuerst erscheint. Nichts wird versteckt — der ganze Katalog bleibt über die Suche erreichbar.';

  @override
  String get profileWhen => 'Wann reisen Sie?';

  @override
  String get profileWhenDetail =>
      'Bergstraßen und manche Wege sind im Winter gesperrt — wir schlagen nichts vor, wohin Sie gerade nicht kommen.';

  @override
  String get profileNow => 'Ich bin gerade in Norwegen';

  @override
  String get profileSoon => 'In den nächsten Monaten';

  @override
  String get profileBrowsing => 'Ich schaue nur';

  @override
  String get profileSkip => 'Überspringen';

  @override
  String get profileNext => 'Weiter';

  @override
  String profileDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fertig — $count Interessen berücksichtigt',
      one: 'Fertig — passende Orte stehen jetzt weiter oben',
    );
    return '$_temp0';
  }

  @override
  String get catMuseums => 'Museen';

  @override
  String get catViewpoints => 'Aussichtspunkte';

  @override
  String get catFjords => 'Fjorde';

  @override
  String get catWaterfalls => 'Wasserfälle';

  @override
  String get catChurches => 'Kirchen';

  @override
  String get catHikes => 'Wanderwege';

  @override
  String get catGlaciers => 'Gletscher';

  @override
  String get catBeaches => 'Strände';

  @override
  String get catMuseum => 'Museum';

  @override
  String get catViewpoint => 'Aussichtspunkt';

  @override
  String get catFjord => 'Fjord';

  @override
  String get catWaterfall => 'Wasserfall';

  @override
  String get catChurch => 'Kirche';

  @override
  String get catHike => 'Wanderweg';

  @override
  String get catGlacier => 'Gletscher';

  @override
  String get catBeach => 'Strand';

  @override
  String get catOther => 'Ort';

  @override
  String get emgAmbulance => 'Rettungsdienst';

  @override
  String get emgAmbulanceSub => 'Ambulanse · Lebensgefahr, schwere Verletzung';

  @override
  String get emgPolice => 'Polizei';

  @override
  String get emgPoliceSub => 'Politi · Straftat, Unfall, vermisste Person';

  @override
  String get emgFire => 'Feuerwehr';

  @override
  String get emgFireSub => 'Brann · Feuer, Rauch, Gasleck';

  @override
  String get emgDoctor => 'Bereitschaftsarzt';

  @override
  String get emgDoctorSub => 'Legevakt · dringend, aber nicht lebensbedrohlich';

  @override
  String get emgSea => 'Seenotrettung';

  @override
  String get emgSeaSub => 'Hovedredningssentralen · Notfall auf See';

  @override
  String get emgPoison => 'Vergiftung';

  @override
  String get emgPoisonSub => 'Giftinformasjonen · rund um die Uhr';

  @override
  String get emgRoad => 'Straßendienst';

  @override
  String get emgRoadSub => 'Vegtrafikksentralen · gesperrte Straßen, Lawinen';

  @override
  String get emgNoteSimTitle => 'Funktioniert ohne Netz und ohne SIM';

  @override
  String get emgNoteSimBody =>
      'Anrufe an 112 und 113 laufen über jeden erreichbaren Mast, auch ohne Netz Ihres Anbieters und ohne SIM-Karte im Telefon.';

  @override
  String get emgNoteCoordsTitle => 'Nennen Sie die Koordinaten';

  @override
  String get emgNoteCoordsBody =>
      'In den Bergen und am Fjord gibt es keine Adressen. Lesen Sie Breite und Länge vor — sie stehen unten auf diesem Bildschirm und lassen sich kopieren.';

  @override
  String get emgNoteEnglishTitle => 'Englisch wird verstanden';

  @override
  String get emgNoteEnglishBody =>
      'Die norwegischen Notrufzentralen sprechen Englisch. Bleiben Sie ruhig und kurz: was passiert ist, wo, wie viele Verletzte.';

  @override
  String get emgNoteMountainTitle => 'In den Bergen — 112';

  @override
  String get emgNoteMountainBody =>
      'Die Bergrettung leitet die Polizei, eine eigene Nummer gibt es nicht. Lassen Sie das Telefon eingeschaltet: darüber wird nach Ihnen gesucht.';

  @override
  String get emgVerified =>
      'Die Nummern gelten für Norwegen. Geprüft am 10.09.2026 anhand von politiet.no, helsenorge.no, hovedredningssentralen.no.';

  @override
  String get onboardingTitle => 'Was interessiert Sie in Norwegen?';

  @override
  String get onboardingSubtitle =>
      'Wählen Sie alles Passende — wir bestimmen, was zuerst erscheint.';

  @override
  String get onboardingNothingHidden =>
      'Nichts wird versteckt: der ganze Katalog bleibt über Suche und Filter erreichbar.';

  @override
  String get onboardingStart => 'Los';

  @override
  String get intNature => 'Natur und Aussicht';

  @override
  String get intHiking => 'Wandern und Trekking';

  @override
  String get intFishing => 'Angeln';

  @override
  String get intHunting => 'Jagd';

  @override
  String get intCulture => 'Museen und Kultur';

  @override
  String get intPhoto => 'Fotografie';

  @override
  String get intKids => 'Mit Kindern';

  @override
  String get intRoadtrip => 'Autoreise';

  @override
  String get intWinter => 'Wintersport';

  @override
  String get intCruise => 'Kreuzfahrt, wenige Stunden an Land';

  @override
  String get rulesTitle => 'Regeln und Lizenzen';

  @override
  String get rulesWhereToCheck => 'Wo Sie nachfragen';

  @override
  String rulesKommune(String name) {
    return 'Kommune $name';
  }

  @override
  String rulesCheckedAt(String date) {
    return 'Daten abgerufen am $date';
  }

  @override
  String get rulesCallKommune => 'Kommune anrufen';

  @override
  String get rulesOpenSite => 'Website der Kommune';

  @override
  String get rulesDisclaimer =>
      'Die App erteilt keine Genehmigungen und kann nicht sagen, ob Angeln oder Jagen genau hier erlaubt ist. Das hängt von Kommune, Grundeigentümer, Saison und Art ab. Fragen Sie vor der Fahrt bei der Kommune oder beim Eigentümer nach.';

  @override
  String get rulesNational => 'Landesweite Regeln';

  @override
  String rulesSource(String authority) {
    return 'Quelle: $authority';
  }

  @override
  String get rulesFishing => 'Angeln';

  @override
  String get rulesHunting => 'Jagd';

  @override
  String get rulesNoKommune =>
      'Für diesen Punkt ließ sich keine Kommune bestimmen. Auf Spitzbergen legt der Gouverneur (Sysselmesteren) die Regeln fest, nicht eine Kommune.';

  @override
  String get promptTitle => 'Was interessiert Sie?';

  @override
  String get promptSubtitle =>
      'Angeln, Wandern, Museen — wir passen die Auswahl an';

  @override
  String get modeTourist => 'Alles';

  @override
  String get modeFishing => 'Angeln';

  @override
  String get modeHunting => 'Jagd';

  @override
  String get modeSwitch => 'Modus';

  @override
  String get modeFishingHint =>
      'Angelplätze werden gezeigt. Städte und Sehenswürdigkeiten sind ausgeblendet — mit der Modus-Schaltfläche zurückholen.';

  @override
  String get modeHuntingHint =>
      'Naturgebiete werden gezeigt. Jagdreviere sind nicht kartiert — entscheidend sind hier Regeln und Kommune.';

  @override
  String get modeRulesButton => 'Regeln und Lizenzen';

  @override
  String get locServiceOff =>
      'Standort ist in den Telefoneinstellungen ausgeschaltet';

  @override
  String get locDenied => 'Kein Zugriff auf den Standort';

  @override
  String get locDeniedForever =>
      'Standortzugriff ist blockiert. In den App-Einstellungen erlauben';

  @override
  String get locUnavailable =>
      'Standort konnte nicht bestimmt werden. In Gebäuden ist das Signal schwach';

  @override
  String get locOpenSettings => 'Einstellungen';

  @override
  String get locSetCity => 'Ort wählen';

  @override
  String get locRetry => 'Erneut versuchen';

  @override
  String get nothingNearby => 'Nichts in der Umgebung';

  @override
  String get nothingNearbyHint =>
      'Der Reiseführer enthält nur Orte mit Beschreibung oder Foto. In Ihrer Umgebung gibt es derzeit keine.';

  @override
  String get nothingInFiltersHint =>
      'Entfernen Sie eine Kategorie — in der Nähe könnten andere Orte liegen.';

  @override
  String get resetFilters => 'Alle Kategorien anzeigen';

  @override
  String get mostVisitedTitle => 'Meistbesucht';

  @override
  String get mostVisitedSubtitle =>
      'Die fünfundzwanzig Orte, für die man nach Norwegen reist';

  @override
  String get mostVisitedEmpty =>
      'Die Topliste ist in diesem Inhaltspaket nicht enthalten';

  @override
  String get mostVisitedNote =>
      'Die Reihenfolge wurde von Hand zusammengestellt: nach Besucherzahlen, UNESCO-Status und Bekanntheit. Wo eine Besucherzahl steht, finden Sie Jahr und Quelle auf der Seite des Ortes.';

  @override
  String get unescoShort => 'UNESCO';

  @override
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Fotos',
      one: '1 Foto',
    );
    return '$_temp0';
  }

  @override
  String visitorsPerYear(int n, String year) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Etwa $nString Besucher pro Jahr ($year)';
  }

  @override
  String get profileDoneButton => 'Fertig';

  @override
  String get downloadsTitle => 'Vor der Reise herunterladen';

  @override
  String get downloadsNote =>
      'Fotos werden nach Region geladen, damit die App klein bleibt. Nichts wird automatisch geladen — der Reiseführer verbraucht nie ungefragt Ihr Datenvolumen.';

  @override
  String downloadsBuiltAt(String date) {
    return 'Inhalte erstellt am $date';
  }

  @override
  String downloadsPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Fotos',
      one: '1 Foto',
    );
    return '$_temp0';
  }

  @override
  String get downloadsStart => 'Herunterladen';

  @override
  String get downloadsRemove => 'Entfernen';

  @override
  String get downloadsUpdateAvailable => 'Eine neuere Version ist verfügbar';

  @override
  String get downloadsFailed => 'Download fehlgeschlagen';

  @override
  String get downloadsOffline => 'Keine Verbindung zum Inhaltsserver';

  @override
  String get downloadsNothingInstalled =>
      'Noch nichts heruntergeladen. Die Orte funktionieren weiterhin — es fehlen nur zusätzliche Fotos.';

  @override
  String downloadsInstalledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Regionen geladen',
      one: '1 Region geladen',
    );
    return '$_temp0';
  }

  @override
  String get routeBannerTitle => 'Ein fertiger Stadtrundgang';

  @override
  String routeTitle(String city) {
    return 'Rundgang durch $city';
  }

  @override
  String routeAbout(String hours) {
    return 'etwa $hours Std.';
  }

  @override
  String routeDistance(String km) {
    return '$km km';
  }

  @override
  String routeStops(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Stationen',
      one: '1 Station',
    );
    return '$_temp0';
  }

  @override
  String get routeEmpty => 'Keine Stationen in diesem Rundgang';

  @override
  String get routeNote =>
      'Reihenfolge und Zeiten sind Näherungswerte: Entfernungen werden in Luftlinie mit Zuschlag für Straßen gemessen, die Besuchsdauer nach Art des Ortes geschätzt. Für die Wegführung nutzen Sie die Kartenschaltfläche auf der Seite des Ortes.';

  @override
  String offerTitle(String region) {
    return 'Sie sind in $region';
  }

  @override
  String offerSubtitle(int n, String mb) {
    return '$n Fotos dieser Gegend · $mb MB';
  }

  @override
  String get offerLater => 'Jetzt nicht';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsContent => 'Inhalte';

  @override
  String get settingsAutoWifi => 'Regionen automatisch laden';

  @override
  String get settingsAutoWifiDetail =>
      'Nur über WLAN. Mobile Daten werden nie genutzt.';

  @override
  String get settingsWifiNow => 'WLAN verbunden';

  @override
  String get settingsWifiNo => 'Derzeit kein WLAN';

  @override
  String get settingsProfileSection => 'Ihre Interessen';

  @override
  String get settingsNoInterests => 'Nicht festgelegt';

  @override
  String get settingsResetOffers => 'Download-Vorschläge erneut zeigen';

  @override
  String get settingsResetOffersDetail =>
      'Abgelehnte Regionen werden noch einmal vorgeschlagen';

  @override
  String get settingsResetDone => 'Vorschläge zurückgesetzt';

  @override
  String get settingsAbout => 'Über die App';

  @override
  String distanceMeters(int n) {
    return '$n m';
  }

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String get compassN => 'N';

  @override
  String get compassNE => 'NO';

  @override
  String get compassE => 'O';

  @override
  String get compassSE => 'SO';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SW';

  @override
  String get compassW => 'W';

  @override
  String get compassNW => 'NW';

  @override
  String get gpxExport => 'Als GPX exportieren';

  @override
  String get gpxDescription =>
      'Erstellt in Norway Explore. Reihenfolge und Zeiten sind Näherungswerte.';

  @override
  String get gpxFailed => 'Datei konnte nicht geteilt werden';
}
