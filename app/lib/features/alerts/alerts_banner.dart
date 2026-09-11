import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/alerts.dart';
import '../../l10n/app_localizations.dart';

/// Полоса с предупреждением о погоде.
///
/// Появляется, только когда предупреждение действительно есть и относится
/// к месту, где человек находится. Постоянной строки «предупреждений нет»
/// не будет: она занимает место и приучает не смотреть в эту часть экрана.
///
/// Цвет соответствует официальному уровню, а не нашему представлению
/// о серьёзности: жёлтый, оранжевый, красный — та же шкала, что на met.no
/// и на дорожных табло. Человек, увидевший оранжевый в приложении и
/// оранжевый на въезде в долину, должен понимать, что это одно и то же.
class AlertsBanner extends ConsumerWidget {
  const AlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(weatherAlertsProvider).valueOrNull ?? const [];
    if (alerts.isEmpty) return const SizedBox.shrink();

    // Самое серьёзное вперёд: если действует и жёлтое, и красное,
    // показывать надо красное.
    final sorted = [...alerts]
      ..sort((a, b) => b.level.index.compareTo(a.level.index));
    final top = sorted.first;
    final l = L.of(context);

    return Material(
      color: _background(context, top.level),
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AlertsScreen())),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              Icon(
                top.marine ? Icons.sailing : Icons.warning_amber_rounded,
                color: _foreground(top.level),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sorted.length == 1
                          ? top.event
                          : '${top.event} · ${l.alertsMore(sorted.length - 1)}',
                      style: TextStyle(
                        color: _foreground(top.level),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      top.area,
                      style: TextStyle(
                        color: _foreground(top.level).withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _foreground(top.level).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _background(BuildContext context, AlertLevel level) =>
      switch (level) {
        AlertLevel.red => const Color(0xFFB3261E),
        AlertLevel.orange => const Color(0xFFE8710A),
        AlertLevel.yellow => const Color(0xFFFFD54F),
      };

  static Color _foreground(AlertLevel level) => switch (level) {
    AlertLevel.red || AlertLevel.orange => Colors.white,
    // На жёлтом белый текст нечитаем — это та ошибка, из-за которой
    // предупреждения в приложениях выглядят как декорация.
    AlertLevel.yellow => const Color(0xFF3E2723),
  };
}

/// Полный текст предупреждений.
///
/// Показываем ровно то, что написал метеоинститут, и ссылку на его сайт.
/// Никаких своих выводов: приложение, которое скажет «можно идти», а
/// человек попадёт в шторм, хуже приложения, которое молчит.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final alerts = ref.watch(weatherAlertsProvider).valueOrNull ?? const [];
    final fetchedAt = ref.watch(alertsFetchedAtProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.alertsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.alertsNone, textAlign: TextAlign.center),
            ),
          for (final alert in alerts) _AlertCard(alert: alert),

          // Источник и время получения. И то и другое обязательно: без
          // источника человеку нечего перепроверить, без времени он не
          // знает, свежее это или сохранённое вчера.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              fetchedAt == null
                  ? l.alertsSource
                  : '${l.alertsSource}\n${l.alertsFetched(_time(fetchedAt))}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('met.no'),
              onPressed: () => _open('https://www.met.no/en'),
            ),
          ),
        ],
      ),
    );
  }

  static String _time(DateTime value) {
    final local = value.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final WeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AlertsBanner._background(context, alert.level),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(alert.event, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alert.marine ? '${alert.area} · ${l.alertsMarine}' : alert.area,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 10),
            Text(alert.description, style: theme.textTheme.bodyMedium),
            if (alert.consequences != null &&
                alert.consequences!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                alert.consequences!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (alert.instruction != null && alert.instruction!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.instruction!,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            if (alert.endsAt != null) ...[
              const SizedBox(height: 10),
              Text(
                l.alertsUntil(_until(alert.endsAt!)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _until(DateTime value) {
    final local = value.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$d.$mo, $h:$mi';
  }
}

Future<void> _open(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // Открывать нечем — молчим.
  }
}
