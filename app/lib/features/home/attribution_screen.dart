import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/attribution.dart';

/// Экран источников и лицензий.
///
/// Обязателен в MVP по §7 спецификации. Данные и тексты приходят из
/// OpenStreetMap, Wikipedia и Wikimedia Commons под лицензиями, которые
/// требуют указания источника и автора. Отсутствие этого экрана — не
/// небрежность, а нарушение условий, на которых мы получили контент.
///
/// Экран всегда на английском, независимо от языка приложения.
///
/// Причина не в лени переводчика. Названия лицензий («CC BY-SA 4.0»,
/// «ODbL») — это термины, у которых юридическую силу имеет английская
/// формулировка; переведённый пересказ условий уже не является этими
/// условиями. Имена авторов не переводятся тем более. Один язык здесь
/// означает, что и норвежский правообладатель, и китайский пользователь
/// видят ровно тот текст, на который мы ссылаемся.
class AttributionScreen extends StatelessWidget {
  const AttributionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sources and licences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'This guide is built on open data. Thanks to everyone who '
            'collects and publishes it.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This page is shown in English in every language of the app: '
            'licence names and author credits are legally meaningful as '
            'written, and a translation would no longer be the licence.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          const _Source(
            title: 'OpenStreetMap',
            body:
                'Map data, coordinates and place details.\n'
                '© OpenStreetMap contributors, licensed under ODbL',
            url: 'https://www.openstreetmap.org/copyright',
          ),
          const _Source(
            title: 'Wikipedia and Wikivoyage',
            body:
                'Descriptions of towns and places of interest.\n'
                'Licensed under CC BY-SA 4.0',
            url: 'https://creativecommons.org/licenses/by-sa/4.0/',
          ),
          const _Source(
            title: 'Wikimedia Commons',
            body:
                'Photographs, each with its own author and licence.\n'
                'Only CC0, CC BY and CC BY-SA files are used',
            url: 'https://commons.wikimedia.org/',
          ),
          const _Source(
            title: 'Wikidata',
            body:
                'Links between objects and names in different languages.\n'
                'Licensed under CC0',
            url: 'https://www.wikidata.org/',
          ),
          const SizedBox(height: 8),
          Text('Images', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final credit in imageCredits)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(credit.title),
                subtitle: Text('${credit.author} · ${credit.license}'),
                // У сгенерированной картинки нет страницы источника,
                // и стрелка «открыть» на ней была бы обманом.
                trailing: credit.sourceUrl.isEmpty
                    ? null
                    : const Icon(Icons.open_in_new, size: 18),
                onTap: credit.sourceUrl.isEmpty
                    ? null
                    : () => _open(credit.sourceUrl),
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

/// Открывает ссылку во внешнем браузере.
///
/// Без предварительной проверки canLaunchUrl: она требует объявления
/// намерений в манифесте Android и без него возвращает false даже там,
/// где браузер есть. Из-за неё приложение однажды уверяло, что нет
/// интернета, при работающей сети. Пробуем открыть и молчим, если
/// не вышло, — предложить тут всё равно нечего.
Future<void> _open(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Открывать нечем — это не повод показывать ошибку на экране
    // с лицензиями.
  }
}
