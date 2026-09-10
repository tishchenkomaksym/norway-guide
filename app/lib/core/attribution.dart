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
  });

  final String asset;
  final String title;
  final String author;
  final String license;
  final String sourceUrl;

  /// Короткая подпись под фото.
  String get short => '$author · $license';
}

const imageCredits = <ImageCredit>[
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
