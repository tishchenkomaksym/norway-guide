import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../data/database.dart';
import '../../l10n/app_localizations.dart';

/// Правила рыбалки и охоты.
///
/// Экран отвечает на вопрос «где узнать», а не «можно ли». Разрешение
/// зависит от коммуны, владельца воды или земли, сезона и вида; собрать
/// это автоматически нельзя, а ошибиться — значит подставить человека
/// под штраф.
///
/// Поэтому здесь три вещи: национальные правила со ссылками на источники,
/// контакты коммуны и честная оговорка о том, чего приложение не знает.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({
    super.key,
    required this.activity,
    this.placeId,
    this.placeName,
  });

  /// fishing | hunting
  final String activity;

  /// Если экран открыт с карточки места — правила для его коммуны.
  final String? placeId;
  final String? placeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final national = ref.watch(nationalRulesProvider(activity));
    final local = ref.watch(
      placeId != null
          ? placeRuleProvider(placeId!)
          : nearestKommuneRuleProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(activity == 'hunting' ? l.rulesHunting : l.rulesFishing),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Оговорка идёт первой, до всего остального. Человек, который
          // пролистает экран и уйдёт, должен успеть её увидеть.
          _Disclaimer(text: l.rulesDisclaimer),
          const SizedBox(height: 20),

          Text(
            l.rulesWhereToCheck,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          local.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (rule) => rule == null
                ? _NoKommune(text: l.rulesNoKommune)
                : _KommuneCard(rule: rule),
          ),

          const SizedBox(height: 24),
          Text(l.rulesNational, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          national.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (rules) =>
                Column(children: [for (final r in rules) _RuleCard(rule: r)]),
          ),
        ],
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Контакты коммуны: телефон важнее сайта.
///
/// Сайты меняют структуру и разделы про рыбалку прячутся в глубине, а номер
/// живёт годами, и на том конце сидит человек, который знает, кто владеет
/// водой.
class _KommuneCard extends StatelessWidget {
  const _KommuneCard({required this.rule});

  final PlaceRule rule;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.rulesKommune(rule.kommuneName),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (rule.countyName != null)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(
                  rule.countyName!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            if (rule.kommunePhone != null)
              _ActionRow(
                icon: Icons.call,
                label: l.rulesCallKommune,
                value: rule.kommunePhone!,
                onTap: () =>
                    _open('tel:${rule.kommunePhone!.replaceAll(' ', '')}'),
              ),
            if (rule.kommuneWebsite != null)
              _ActionRow(
                icon: Icons.language,
                label: l.rulesOpenSite,
                value: rule.kommuneWebsite!.replaceFirst('https://', ''),
                onTap: () => _open(rule.kommuneWebsite!),
              ),
            const SizedBox(height: 6),
            // Дата обязательна: контакты устаревают, и человек должен
            // видеть, насколько свежие сведения он читает.
            Text(
              l.rulesCheckedAt(rule.checkedAt),
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});

  final NationalRule rule;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rule.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              rule.body,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _open(rule.sourceUrl),
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 14, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l.rulesSource(rule.authority),
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoKommune extends StatelessWidget {
  const _NoKommune({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// Открывает ссылку или номер.
///
/// Без canLaunchUrl: он врёт при определённых настройках видимости
/// приложений на Android — см. docs/decisions.md.
Future<void> _open(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Молча: экран не должен падать из-за отсутствия браузера.
  }
}
