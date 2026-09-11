// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Norway Explore';

  @override
  String get appTagline => 'Fiordos, cascadas y ciudades — sin conexión';

  @override
  String get nearbyTitle => 'Qué hay cerca';

  @override
  String get nearbySubtitle => 'Lugares cercanos con distancia y dirección';

  @override
  String get browseTitle => 'Adónde ir';

  @override
  String get browseSubtitle => 'Ciudades y lugares de interés del país';

  @override
  String get favoritesTitle => 'Mi viaje';

  @override
  String favoritesSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lugares guardados',
      one: '$count lugar guardado',
    );
    return '$_temp0';
  }

  @override
  String get sourcesTitle => 'Fuentes y licencias';

  @override
  String get sourcesTooltip => 'Sobre las fuentes';

  @override
  String photoBy(String credit) {
    return 'Foto: $credit';
  }

  @override
  String get nearbyScreenTitle => 'Cerca de mí';

  @override
  String nearbyScreenTitleAt(String city) {
    return 'Cerca de $city';
  }

  @override
  String get searchTooltip => 'Buscar';

  @override
  String get setCityTooltip => 'Elegir ciudad';

  @override
  String get useGpsTooltip => 'Usar GPS';

  @override
  String get interestsTooltip => 'Mis intereses';

  @override
  String get locationUnknown =>
      'Ubicación desconocida. Toca para elegir una ciudad';

  @override
  String get nothingInFilters => 'Nada coincide con los filtros seleccionados';

  @override
  String get loadError => 'No se pudieron cargar los lugares';

  @override
  String get otherLanguageShort => 'En otro idioma';

  @override
  String get descriptionOtherLanguage =>
      'Aún sin traducción — texto en el idioma original';

  @override
  String get tabCities => 'Ciudades';

  @override
  String get tabPlaces => 'Lugares';

  @override
  String get noCities => 'No hay ciudades en estos datos';

  @override
  String get nothingInCategories =>
      'No se encontró nada en las categorías elegidas';

  @override
  String shownOf(int shown, int total) {
    return 'Mostrando $shown de $total';
  }

  @override
  String get resetFilter => 'Restablecer';

  @override
  String placesCount(int count) {
    return '$count lugares';
  }

  @override
  String get cityLarge => 'Ciudad grande';

  @override
  String get cityMedium => 'Ciudad';

  @override
  String get citySmall => 'Ciudad pequeña';

  @override
  String get cityVillage => 'Pueblo';

  @override
  String get cityHamlet => 'Aldea';

  @override
  String get cityTourist => 'Lugar turístico';

  @override
  String get cityGeneric => 'Localidad';

  @override
  String get noPlacesInCity => 'Todavía no hay lugares para esta ciudad';

  @override
  String get placeNotFound => 'Lugar no encontrado';

  @override
  String get noDescription =>
      'Todavía no hay descripción. Las coordenadas y la ruta funcionan — puedes ir y verlo tú mismo.';

  @override
  String get noDescriptionShort => 'Descripción no cargada';

  @override
  String get routeButton => 'Cómo llegar';

  @override
  String get mapsFailed =>
      'No se pudieron abrir los mapas. Se necesita internet.';

  @override
  String get addToFavorites => 'Añadir al viaje';

  @override
  String get removeFromFavorites => 'Quitar del viaje';

  @override
  String get factOpeningHours => 'Horario';

  @override
  String get factFee => 'Entrada';

  @override
  String get factDifficulty => 'Dificultad';

  @override
  String get factDuration => 'Duración';

  @override
  String factMinutes(int count) {
    return '$count min';
  }

  @override
  String get factSeason => 'Temporada';

  @override
  String get factWebsite => 'Sitio web';

  @override
  String get searchHint => 'Lugar, ciudad, cascada…';

  @override
  String get searchPrompt => 'Escribe al menos dos letras';

  @override
  String get searchPromptDetail =>
      'Buscamos a la vez en tu idioma, en noruego y en inglés — escríbelo como aparece en la señal.';

  @override
  String searchNothing(String query) {
    return 'No se encontró nada para «$query»';
  }

  @override
  String get searchNothingDetail =>
      'No todos los lugares tienen descripción. Prueba la grafía noruega o parte de la palabra.';

  @override
  String get searchError => 'Error de búsqueda';

  @override
  String get favoritesWant => 'Quiero ver';

  @override
  String get favoritesVisited => 'Ya estuve';

  @override
  String get favoritesEmpty => 'Aquí no hay nada todavía';

  @override
  String get favoritesEmptyDetail =>
      'Toca el corazón en la ficha de un lugar y aparecerá aquí. Puedes marcar los visitados y añadir notas.';

  @override
  String get noteTooltip => 'Nota';

  @override
  String get noteHint => 'A qué hora abre, dónde aparcar, qué llevar…';

  @override
  String get markVisited => 'Ya estuve aquí';

  @override
  String get markNotVisited => 'Todavía no';

  @override
  String removedFromTrip(String place) {
    return '$place quitado del viaje';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get emergencyTitle => 'Emergencias';

  @override
  String get emergencyTooltip => 'Emergencias';

  @override
  String get emergencyOther => 'Otros servicios';

  @override
  String get emergencyKnow => 'Conviene saber';

  @override
  String get emergencyCoordinates => 'Tus coordenadas';

  @override
  String get emergencyCopy => 'Copiar';

  @override
  String get emergencyCopied => 'Coordenadas copiadas';

  @override
  String get emergencyManualPosition => 'Ubicación puesta a mano — no por GPS';

  @override
  String emergencyDial(String service, String number) {
    return '$service: marca $number';
  }

  @override
  String get whereAreYou => '¿Dónde estás?';

  @override
  String get cityHint => 'Ciudad: Bergen, Oslo, Tromsø…';

  @override
  String get nothingFound => 'No se encontró nada';

  @override
  String get profileQuestion => '¿Qué te interesa más?';

  @override
  String get profileQuestionDetail =>
      'Elegiremos qué mostrar primero. No ocultamos nada — el catálogo completo sigue disponible en la búsqueda.';

  @override
  String get profileWhen => '¿Cuándo viajas?';

  @override
  String get profileWhenDetail =>
      'Las carreteras de montaña y algunos senderos cierran en invierno — no te propondremos sitios a los que ahora no se llega.';

  @override
  String get profileNow => 'Estoy en Noruega ahora';

  @override
  String get profileSoon => 'En los próximos meses';

  @override
  String get profileBrowsing => 'Solo estoy mirando';

  @override
  String get profileSkip => 'Omitir';

  @override
  String get profileNext => 'Siguiente';

  @override
  String profileDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Listo — $count intereses tenidos en cuenta',
      one: 'Listo — los lugares afines aparecen más arriba',
    );
    return '$_temp0';
  }

  @override
  String get catMuseums => 'Museos';

  @override
  String get catViewpoints => 'Miradores';

  @override
  String get catFjords => 'Fiordos';

  @override
  String get catWaterfalls => 'Cascadas';

  @override
  String get catChurches => 'Iglesias';

  @override
  String get catHikes => 'Senderos';

  @override
  String get catGlaciers => 'Glaciares';

  @override
  String get catBeaches => 'Playas';

  @override
  String get catMuseum => 'Museo';

  @override
  String get catViewpoint => 'Mirador';

  @override
  String get catFjord => 'Fiordo';

  @override
  String get catWaterfall => 'Cascada';

  @override
  String get catChurch => 'Iglesia';

  @override
  String get catHike => 'Sendero';

  @override
  String get catGlacier => 'Glaciar';

  @override
  String get catBeach => 'Playa';

  @override
  String get catOther => 'Lugar';

  @override
  String get emgAmbulance => 'Ambulancia';

  @override
  String get emgAmbulanceSub => 'Ambulanse · peligro de muerte, herida grave';

  @override
  String get emgPolice => 'Policía';

  @override
  String get emgPoliceSub => 'Politi · delito, accidente, persona desaparecida';

  @override
  String get emgFire => 'Bomberos';

  @override
  String get emgFireSub => 'Brann · incendio, humo, fuga de gas';

  @override
  String get emgDoctor => 'Médico de guardia';

  @override
  String get emgDoctorSub => 'Legevakt · urgente, pero sin peligro de muerte';

  @override
  String get emgSea => 'Rescate marítimo';

  @override
  String get emgSeaSub => 'Hovedredningssentralen · incidente en el mar';

  @override
  String get emgPoison => 'Intoxicaciones';

  @override
  String get emgPoisonSub => 'Giftinformasjonen · 24 horas';

  @override
  String get emgRoad => 'Servicio de carreteras';

  @override
  String get emgRoadSub => 'Vegtrafikksentralen · carreteras cortadas, aludes';

  @override
  String get emgNoteSimTitle => 'Funciona sin cobertura y sin SIM';

  @override
  String get emgNoteSimBody =>
      'Las llamadas al 112 y al 113 pasan por cualquier antena disponible, aunque tu operador no tenga cobertura y no haya tarjeta SIM en el teléfono.';

  @override
  String get emgNoteCoordsTitle => 'Da tus coordenadas';

  @override
  String get emgNoteCoordsBody =>
      'En la montaña y en los fiordos no hay direcciones. Dicta la latitud y la longitud — están más abajo en esta pantalla y se pueden copiar.';

  @override
  String get emgNoteEnglishTitle => 'Entienden inglés';

  @override
  String get emgNoteEnglishBody =>
      'Los operadores de emergencias de Noruega hablan inglés. Habla con calma y brevedad: qué ha pasado, dónde, cuántos heridos.';

  @override
  String get emgNoteMountainTitle => 'En la montaña — 112';

  @override
  String get emgNoteMountainBody =>
      'El rescate en montaña lo dirige la policía; no hay un número aparte. No apagues el teléfono: lo usarán para localizarte.';

  @override
  String get emgVerified =>
      'Los números son de Noruega. Verificados el 10/09/2026 en politiet.no, helsenorge.no, hovedredningssentralen.no.';

  @override
  String get onboardingTitle => '¿Qué te interesa de Noruega?';

  @override
  String get onboardingSubtitle =>
      'Marca todo lo que encaje: elegiremos qué mostrar primero.';

  @override
  String get onboardingNothingHidden =>
      'No ocultamos nada: el catálogo completo sigue disponible en la búsqueda y los filtros.';

  @override
  String get onboardingStart => 'Empezar';

  @override
  String get intNature => 'Naturaleza y paisajes';

  @override
  String get intHiking => 'Senderismo y trekking';

  @override
  String get intFishing => 'Pesca';

  @override
  String get intHunting => 'Caza';

  @override
  String get intCulture => 'Museos y cultura';

  @override
  String get intPhoto => 'Fotografía';

  @override
  String get intKids => 'Con niños';

  @override
  String get intRoadtrip => 'Viaje por carretera';

  @override
  String get intWinter => 'Deportes de invierno';

  @override
  String get intCruise => 'Crucero, unas horas en tierra';

  @override
  String get rulesTitle => 'Normas y licencias';

  @override
  String get rulesWhereToCheck => 'Dónde comprobarlo';

  @override
  String rulesKommune(String name) {
    return 'Municipio de $name';
  }

  @override
  String rulesCheckedAt(String date) {
    return 'Datos obtenidos el $date';
  }

  @override
  String get rulesCallKommune => 'Llamar al municipio';

  @override
  String get rulesOpenSite => 'Web del municipio';

  @override
  String get rulesDisclaimer =>
      'La aplicación no concede permisos y no puede decir si se permite pescar o cazar exactamente aquí. Depende del municipio, del propietario, de la temporada y de la especie. Consulta con el municipio o el propietario antes de ir.';

  @override
  String get rulesNational => 'Normas de ámbito nacional';

  @override
  String rulesSource(String authority) {
    return 'Fuente: $authority';
  }

  @override
  String get rulesFishing => 'Pesca';

  @override
  String get rulesHunting => 'Caza';

  @override
  String get rulesNoKommune =>
      'No se ha podido determinar el municipio de este punto. En Svalbard las normas las fija el Gobernador (Sysselmesteren), no un municipio.';

  @override
  String get promptTitle => '¿Qué te interesa?';

  @override
  String get promptSubtitle =>
      'Pesca, senderismo, museos: adaptamos lo que ves';

  @override
  String get modeTourist => 'Todo';

  @override
  String get modeFishing => 'Pesca';

  @override
  String get modeHunting => 'Caza';

  @override
  String get modeSwitch => 'Modo';

  @override
  String get modeFishingHint =>
      'Mostrando zonas de pesca. Las ciudades y los lugares de interés están ocultos: recupéralos con el botón de modo.';

  @override
  String get modeHuntingHint =>
      'Mostrando zonas naturales. Los cotos de caza no están cartografiados: aquí lo que importa son las normas y el municipio.';

  @override
  String get modeRulesButton => 'Normas y licencias';

  @override
  String get locServiceOff =>
      'La ubicación está desactivada en los ajustes del teléfono';

  @override
  String get locDenied => 'Sin acceso a la ubicación';

  @override
  String get locDeniedForever =>
      'El acceso a la ubicación está bloqueado. Puedes permitirlo en los ajustes de la app';

  @override
  String get locUnavailable =>
      'No se pudo determinar tu ubicación. En interiores la señal es débil';

  @override
  String get locOpenSettings => 'Ajustes';

  @override
  String get locSetCity => 'Elegir ciudad';

  @override
  String get locRetry => 'Reintentar';

  @override
  String get nothingNearby => 'No hay nada cerca';

  @override
  String get nothingNearbyHint =>
      'La guía solo incluye lugares con descripción o fotografía. Ahora mismo no hay ninguno a tu alrededor.';

  @override
  String get nothingInFiltersHint =>
      'Prueba a quitar una categoría: puede haber otros lugares cerca.';

  @override
  String get resetFilters => 'Mostrar todas las categorías';

  @override
  String get mostVisitedTitle => 'Lo más visitado';

  @override
  String get mostVisitedSubtitle =>
      'Los veinticinco lugares por los que se viaja a Noruega';

  @override
  String get mostVisitedEmpty =>
      'La lista destacada no está en este paquete de contenido';

  @override
  String get mostVisitedNote =>
      'El orden está compuesto a mano según el número de visitantes, la declaración de la UNESCO y lo conocido que es el lugar. Cuando se muestra una cifra de visitantes, el año y la fuente aparecen en la ficha del lugar.';

  @override
  String get unescoShort => 'UNESCO';

  @override
  String photoCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String visitorsPerYear(int n, String year) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return 'Unos $nString visitantes al año ($year)';
  }

  @override
  String get profileDoneButton => 'Listo';

  @override
  String get downloadsTitle => 'Descargar antes del viaje';

  @override
  String get downloadsNote =>
      'Las fotos se descargan por región para que la aplicación siga siendo ligera. No se descarga nada automáticamente: la guía nunca gasta tus datos sin pedírtelo.';

  @override
  String downloadsBuiltAt(String date) {
    return 'Contenido preparado el $date';
  }

  @override
  String downloadsPhotos(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String get downloadsStart => 'Descargar';

  @override
  String get downloadsRemove => 'Eliminar';

  @override
  String get downloadsUpdateAvailable => 'Hay una versión más reciente';

  @override
  String get downloadsFailed => 'Error de descarga';

  @override
  String get downloadsOffline => 'Sin conexión con el servidor de contenidos';

  @override
  String get downloadsNothingInstalled =>
      'Aún no has descargado nada. Los lugares siguen funcionando: solo faltan fotos adicionales.';

  @override
  String downloadsInstalledCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n regiones descargadas',
      one: '1 región descargada',
    );
    return '$_temp0';
  }

  @override
  String get routeBannerTitle => 'Un paseo listo por la ciudad';

  @override
  String routeTitle(String city) {
    return 'Paseo por $city';
  }

  @override
  String routeAbout(String hours) {
    return 'unas $hours h';
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
      other: '$n paradas',
      one: '1 parada',
    );
    return '$_temp0';
  }

  @override
  String get routeEmpty => 'Este paseo no tiene paradas';

  @override
  String get routeNote =>
      'El orden y los tiempos son aproximados: las distancias se miden en línea recta con un margen por las calles, y el tiempo de visita se estima según el tipo de lugar. Para indicaciones paso a paso, usa el botón de mapa en la ficha del lugar.';

  @override
  String offerTitle(String region) {
    return 'Estás en $region';
  }

  @override
  String offerSubtitle(int n, String mb) {
    return '$n fotos de esta zona · $mb MB';
  }

  @override
  String get offerLater => 'Ahora no';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsContent => 'Contenido';

  @override
  String get settingsAutoWifi => 'Descargar regiones automáticamente';

  @override
  String get settingsAutoWifiDetail =>
      'Solo por Wi-Fi. Nunca se usan datos móviles.';

  @override
  String get settingsWifiNow => 'Wi-Fi conectado';

  @override
  String get settingsWifiNo => 'Ahora no hay Wi-Fi';

  @override
  String get settingsProfileSection => 'Tus intereses';

  @override
  String get settingsNoInterests => 'Sin definir';

  @override
  String get settingsResetOffers => 'Volver a mostrar las sugerencias';

  @override
  String get settingsResetOffersDetail =>
      'Las regiones que descartaste se ofrecerán una vez más';

  @override
  String get settingsResetDone => 'Sugerencias restauradas';

  @override
  String get settingsAbout => 'Acerca de';

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
  String get compassNE => 'NE';

  @override
  String get compassE => 'E';

  @override
  String get compassSE => 'SE';

  @override
  String get compassS => 'S';

  @override
  String get compassSW => 'SO';

  @override
  String get compassW => 'O';

  @override
  String get compassNW => 'NO';

  @override
  String get gpxExport => 'Llevar conmigo';

  @override
  String get gpxDescription =>
      'Creado en Norway Explore. El orden y los tiempos son aproximados.';

  @override
  String get gpxFailed => 'No se pudo compartir el archivo';

  @override
  String get exportSheetTitle => 'Llévate la ruta';

  @override
  String get exportSheetWhat =>
      'Guarda las paradas en un archivo que otras aplicaciones pueden abrir y usar para guiarte: nuestra guía solo muestra el orden, no navega.';

  @override
  String get exportSheetApps =>
      'Aplicaciones de navegación: OsmAnd, Komoot, Gaia GPS, Organic Maps';

  @override
  String get exportSheetWatches => 'Relojes deportivos: Garmin, Suunto, Polar';

  @override
  String get exportSheetNot =>
      'El archivo contiene puntos, no un camino. Tu navegador calculará la ruta entre ellos.';

  @override
  String get exportSheetSend => 'Enviar archivo';

  @override
  String get exportSheetCancel => 'Cancelar';

  @override
  String get usageTitle => 'Cómo usas la aplicación';

  @override
  String get usageNote =>
      'Estos números se quedan en tu teléfono. No se envía nada a ninguna parte, ni a nosotros ni a nadie. Puedes borrarlos cuando quieras.';

  @override
  String get usageLaunches => 'Veces abierta';

  @override
  String get usagePlaces => 'Lugares vistos';

  @override
  String get usageRoutes => 'Paseos abiertos';

  @override
  String get usageSearches => 'Búsquedas';

  @override
  String get usagePacks => 'Regiones descargadas';

  @override
  String get usageSince => 'En uso desde hace';

  @override
  String usageDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días',
      one: '1 día',
      zero: 'hoy',
    );
    return '$_temp0';
  }

  @override
  String get usageReset => 'Borrar estos números';

  @override
  String get usageResetDetail => 'Los contadores vuelven a cero';

  @override
  String get usageResetDone => 'Números borrados';

  @override
  String get settingsUsage => 'Cómo usas la aplicación';

  @override
  String get ratingPrompt => 'Valora este lugar';

  @override
  String get ratingYours => 'Tu valoración';

  @override
  String get ratingVisited => 'marcado como visitado';

  @override
  String get ratingPrivate =>
      'Solo lo ves tú. No se envía nada a ninguna parte.';
}
