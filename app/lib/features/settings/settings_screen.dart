import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile.dart';
import '../../core/packs.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../downloads/downloads_screen.dart';
import '../downloads/region_offer.dart';
import '../home/attribution_screen.dart';
import '../profile/profile_sheet.dart';
import 'usage_screen.dart';

/// Настройки.
///
/// Заменяет временную кнопку переключения языка в шапке главного экрана:
/// та стояла там для проверки переводов и в релизе выглядела бы странно.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final lang = ref.watch(languageProvider);
    final autoWifi = ref.watch(autoDownloadWifiProvider);
    final profile = ref.watch(profileProvider);
    final installed = ref.watch(installedPacksProvider).valueOrNull ?? {};
    final onWifi = ref.watch(onWifiProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          _Header(text: l.settingsLanguage),
          // RadioGroup вместо groupValue у каждой строки: старый способ
          // объявлен устаревшим после Flutter 3.32.
          RadioGroup<String>(
            groupValue: lang,
            onChanged: (value) {
              if (value != null) {
                ref.read(languageProvider.notifier).set(value);
              }
            },
            child: Column(
              children: [
                for (final code in supportedLanguages)
                  RadioListTile<String>(
                    value: code,
                    title: Text(_languageName(code)),
                  ),
              ],
            ),
          ),

          const Divider(),
          _Header(text: l.settingsContent),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l.downloadsTitle),
            subtitle: Text(
              installed.isEmpty
                  ? l.downloadsNothingInstalled
                  : l.downloadsInstalledCount(installed.length),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DownloadsScreen())),
          ),
          SwitchListTile(
            value: autoWifi,
            onChanged: (value) =>
                ref.read(autoDownloadWifiProvider.notifier).set(value),
            title: Text(l.settingsAutoWifi),
            // Подпись объясняет ровно то, о чём человек беспокоится:
            // спишут ли у него мобильный трафик. Ответ — никогда.
            subtitle: Text(
              '${l.settingsAutoWifiDetail}\n'
              '${onWifi ? l.settingsWifiNow : l.settingsWifiNo}',
            ),
            isThreeLine: true,
          ),

          const Divider(),
          _Header(text: l.settingsProfileSection),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l.interestsTooltip),
            subtitle: Text(
              profile.interestIds.isEmpty
                  ? l.settingsNoInterests
                  : profile.interestIds
                        .map((id) => interestLabel(context, id))
                        .join(', '),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showProfileSheet(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l.settingsResetOffers),
            subtitle: Text(l.settingsResetOffersDetail),
            onTap: () {
              ref.read(offeredRegionsProvider.notifier).reset();
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l.settingsResetDone)));
            },
          ),

          const Divider(),
          _Header(text: l.settingsAbout),
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(l.settingsUsage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const UsageScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sources and licences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AttributionScreen()),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Название языка на нём самом — так его узнают, не зная нынешнего
  /// языка интерфейса.
  static String _languageName(String code) => switch (code) {
    'en' => 'English',
    'no' => 'Norsk',
    'de' => 'Deutsch',
    'es' => 'Español',
    'ru' => 'Русский',
    'zh' => '中文',
    _ => code,
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
