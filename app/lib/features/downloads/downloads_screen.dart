import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/packs.dart';
import '../../l10n/app_localizations.dart';

/// Состояние загрузок: что качается и с каким прогрессом.
///
/// Отдельный нотифаер, а не поле в провайдере пакетов: прогресс меняется
/// десятки раз в секунду, и перестраивать из-за него весь экран со списком
/// регионов не нужно.
class DownloadsNotifier extends StateNotifier<Map<String, double>> {
  DownloadsNotifier(this._ref) : super({});

  final Ref _ref;

  bool isBusy(String regionId) => state.containsKey(regionId);

  Future<void> download(PackInfo info) async {
    if (isBusy(info.regionId)) return;
    state = {...state, info.regionId: 0};
    try {
      await downloadPack(
        info,
        onProgress: (value) {
          state = {...state, info.regionId: value};
        },
      );
      _ref.invalidate(installedPacksProvider);
      _ref.invalidate(downloadedPhotosProvider);
    } finally {
      final next = {...state}..remove(info.regionId);
      state = next;
    }
  }

  Future<void> remove(String regionId) async {
    await removePack(regionId);
    _ref.invalidate(installedPacksProvider);
    _ref.invalidate(downloadedPhotosProvider);
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, Map<String, double>>(
      DownloadsNotifier.new,
    );

/// Экран «Скачать перед поездкой».
///
/// Здесь нет ни одной автоматической загрузки. Приложение не тратит трафик
/// без явного нажатия: человек может быть в роуминге посреди фьорда, и
/// фоновая докачка тридцати мегабайт — это реальные деньги. При выходе
/// новой версии пакета показывается пометка, и только (см. решение
/// «Карта не обновляется сама» в docs/decisions.md).
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final manifest = ref.watch(packManifestProvider);
    final installed = ref.watch(installedPacksProvider).valueOrNull ?? {};
    final progress = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.downloadsTitle)),
      body: manifest.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Offline(installed: installed),
        data: (data) {
          // Манифест не скачался — почти всегда это просто отсутствие сети.
          // Экран обязан открыться и показать, что уже есть на устройстве.
          if (data == null) return _Offline(installed: installed);

          return ListView(
            children: [
              _Explanation(builtAt: data.builtAt),
              for (final pack in data.packs)
                _PackTile(
                  pack: pack,
                  installedVersion: installed[pack.regionId],
                  progress: progress[pack.regionId],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Explanation extends StatelessWidget {
  const _Explanation({required this.builtAt});

  final String builtAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = L.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.downloadsNote, style: theme.textTheme.bodySmall),
          if (builtAt.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l.downloadsBuiltAt(builtAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Нет сети: показываем только то, что уже скачано.
class _Offline extends StatelessWidget {
  const _Offline({required this.installed});

  final Map<String, int> installed;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 44, color: theme.colorScheme.outline),
            const SizedBox(height: 14),
            Text(l.downloadsOffline, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              installed.isEmpty
                  ? l.downloadsNothingInstalled
                  : l.downloadsInstalledCount(installed.length),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackTile extends ConsumerWidget {
  const _PackTile({
    required this.pack,
    required this.installedVersion,
    required this.progress,
  });

  final PackInfo pack;
  final int? installedVersion;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final theme = Theme.of(context);
    final isInstalled = installedVersion != null;
    final isOutdated = isInstalled && installedVersion! < pack.packVersion;
    final busy = progress != null;

    return ListTile(
      leading: Icon(
        isInstalled ? Icons.offline_pin : Icons.download_outlined,
        color: isInstalled ? theme.colorScheme.primary : null,
      ),
      title: Text(pack.nameEn.isEmpty ? pack.regionId : pack.nameEn),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pack.sizeMb.toStringAsFixed(1)} MB · '
            '${l.downloadsPhotos(pack.photos)}',
            style: theme.textTheme.bodySmall,
          ),
          if (busy) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress),
          ],
          // Новая версия — это пометка, а не действие. Приложение не качает
          // ничего само: скачанный регион живёт, пока человек сам его
          // не обновит.
          if (isOutdated && !busy)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.downloadsUpdateAvailable,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
        ],
      ),
      trailing: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isInstalled
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.downloadsRemove,
              onPressed: () =>
                  ref.read(downloadsProvider.notifier).remove(pack.regionId),
            )
          : IconButton(
              icon: const Icon(Icons.download),
              tooltip: l.downloadsStart,
              onPressed: () => _start(context, ref),
            ),
      onTap: busy || isInstalled ? null : () => _start(context, ref),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = L.of(context);
    try {
      await ref.read(downloadsProvider.notifier).download(pack);
    } catch (e) {
      // Ошибку показываем словами человека, а не текстом исключения:
      // «SocketException» ему ничего не говорит.
      messenger.showSnackBar(
        SnackBar(content: Text('${l.downloadsFailed}: $e')),
      );
    }
  }
}
