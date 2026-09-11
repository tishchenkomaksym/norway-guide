import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/usage_stats.dart';
import '../../l10n/app_localizations.dart';

/// Экран «как вы пользуетесь приложением».
///
/// Эти цифры нужны двоим. Владельцу продукта — чтобы через полгода решать
/// о развитии по фактам, а не по ощущениям: что открывают, качают ли
/// регионы, ищут ли что-нибудь. И самому человеку — потому что честно
/// показать, что именно считает приложение, гораздо убедительнее любого
/// абзаца в политике конфиденциальности.
///
/// Ничего из этого никуда не отправляется. Строка об этом стоит на экране
/// первой, и это не формальность: люди справедливо не верят обещаниям
/// «мы не собираем данные», когда проверить их нельзя. Здесь проверить
/// можно — весь список перед глазами, и его можно стереть.
class UsageScreen extends ConsumerWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final stats = ref.watch(usageStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.usageTitle)),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: Text(l.usageNote, style: theme.textTheme.bodySmall),
          ),
          _Row(label: l.usageLaunches, value: stats.launches),
          _Row(label: l.usagePlaces, value: stats.placesOpened),
          _Row(label: l.usageRoutes, value: stats.routesOpened),
          _Row(label: l.usageSearches, value: stats.searches),
          _Row(label: l.usagePacks, value: stats.packsDownloaded),
          if (stats.firstLaunch != null)
            ListTile(
              title: Text(l.usageSince),
              trailing: Text(
                l.usageDays(stats.daysSinceFirst),
                style: theme.textTheme.titleMedium,
              ),
            ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text(
              l.usageReset,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: Text(l.usageResetDetail),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(usageStatsProvider.notifier).reset();
              messenger.showSnackBar(SnackBar(content: Text(l.usageResetDone)));
            },
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text('$value', style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
