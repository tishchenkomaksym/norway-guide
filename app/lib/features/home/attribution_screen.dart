import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/attribution.dart';
import '../../l10n/app_localizations.dart';

/// Экран атрибуции.
///
/// Обязателен в MVP по §7 спецификации. Данные и тексты приходят из
/// OpenStreetMap, Wikipedia и Wikimedia Commons под лицензиями, которые
/// требуют указания источника и автора. Отсутствие этого экрана — не
/// небрежность, а нарушение условий, на которых мы получили контент.
class AttributionScreen extends StatelessWidget {
  const AttributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L.of(context).sourcesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Приложение построено на открытых данных. Спасибо тем, кто их '
            'собирает и публикует.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _Source(
            title: 'OpenStreetMap',
            body:
                'Карта, координаты и сведения о местах.\n'
                '© участники OpenStreetMap, лицензия ODbL',
            url: 'https://www.openstreetmap.org/copyright',
          ),
          _Source(
            title: 'Wikipedia и Wikivoyage',
            body:
                'Описания городов и достопримечательностей.\n'
                'Лицензия CC BY-SA 4.0',
            url: 'https://creativecommons.org/licenses/by-sa/4.0/',
          ),
          _Source(
            title: 'Wikidata',
            body:
                'Связи между объектами и названия на разных языках.\n'
                'Лицензия CC0',
            url: 'https://www.wikidata.org/',
          ),
          const SizedBox(height: 8),
          Text('Фотографии', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final credit in imageCredits)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(credit.title),
                subtitle: Text('${credit.author} · ${credit.license}'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(credit.sourceUrl),
              ),
            ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.title, required this.body, required this.url});

  final String title;
  final String body;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _open(url),
            child: Text(
              url,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _open(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
