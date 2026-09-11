/// Атрибуция изображений.
///
/// Требование §7 спецификации, а не формальность: снимки с Wikimedia Commons
/// идут под CC BY-SA, и распространение без указания автора, лицензии
/// и ссылки на источник — нарушение, которое блокирует релиз.
///
/// Каждое изображение в приложении обязано иметь здесь запись.
class ImageCredit {
  const ImageCredit({
    required this.asset,
    required this.title,
    required this.author,
    required this.license,
    required this.sourceUrl,
    this.generated = false,
  });

  final String asset;
  final String title;
  final String author;
  final String license;
  final String sourceUrl;

  /// Изображение нарисовано нейросетью, а не снято.
  ///
  /// Отдельный признак, а не догадка по тексту автора: у сгенерированной
  /// картинки нет страницы источника, и проверка «ссылка обязана начинаться
  /// с https» иначе либо падает, либо её приходится ослаблять для всех.
  /// Ослаблять нельзя — она ловит главный способ нарушить лицензию:
  /// положить чужой снимок в assets и забыть про автора.
  final bool generated;

  /// Короткая подпись под фото.
  String get short => '$author · $license';
}

const imageCredits = <ImageCredit>[
  ImageCredit(
    asset: 'assets/images/first-screen.jpg',
    // Заставка главного экрана и эмблема приложения нарисованы
    // нейросетью: в файле стоит метка C2PA
    // digitalsourcetype/trainedAlgorithmicMedia. Это не фотография
    // конкретного места, и подписывать её как снимок Рейне нельзя —
    // мотивы узнаваемы (рорбу, сияние, Олстинден), но кадр вымышлен.
    //
    // Отсюда и формулировка: «иллюстрация, сгенерирована ИИ». Всё
    // остальное в приложении — настоящие снимки с Commons, и человек
    // должен понимать, где что.
    title: 'Заставка: рорбу под северным сиянием (иллюстрация)',
    author: 'Иллюстрация, сгенерирована ИИ',
    license: 'Не фотография',
    sourceUrl: '',
    generated: true,
  ),
  ImageCredit(
    asset: 'assets/images/geiranger-ornesvingen.jpg',
    title: 'Гейрангер-фьорд со смотровой Эрнесвинген',
    author: 'Ximonic (Simo Räsänen)',
    license: 'CC BY-SA 3.0',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:Geirangerfjord_from_%C3%98rnesvingen,_2013_June.jpg',
  ),
  ImageCredit(
    asset: 'assets/images/preikestolen.jpg',
    title: 'Прекестулен над Люсе-фьордом',
    author: 'Maarten Heerlien',
    license: 'CC BY 2.0',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:Preikestolen_1_(52606536704).jpg',
  ),
  ImageCredit(
    asset: 'assets/images/geirangerfjord.jpg',
    title: 'Гейрангер-фьорд',
    author: 'Andreas Trepte',
    license: 'CC BY-SA 2.5',
    sourceUrl: 'https://commons.wikimedia.org/wiki/File:Geirangerfjord_.jpg',
  ),
];

ImageCredit? creditFor(String asset) {
  for (final c in imageCredits) {
    if (c.asset == asset) return c;
  }
  return null;
}
