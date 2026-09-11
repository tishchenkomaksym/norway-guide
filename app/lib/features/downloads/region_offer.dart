import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/packs.dart';
import '../../core/providers.dart';
import '../../core/regions.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import 'downloads_screen.dart';

/// Есть ли сейчас Wi-Fi.
///
/// Мобильная сеть намеренно не считается подходящей: автоматическая
/// загрузка разрешена только по Wi-Fi, даже если человек её включил.
/// Турист в Норвегии чаще всего в роуминге, и двадцать мегабайт,
/// списанные без спроса, — это реальные деньги.
final onWifiProvider = FutureProvider<bool>((ref) async {
  try {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  } catch (_) {
    // Не смогли определить — считаем, что Wi-Fi нет. Ошибаться надо
    // в сторону «не тратить чужой трафик».
    return false;
  }
});

/// Регион, в котором человек находится, — если он в Норвегии.
final currentRegionProvider = Provider<DownloadRegion?>((ref) {
  final manual = ref.watch(mockPositionProvider);
  if (manual != null) return regionFor(manual.lat, manual.lon);

  final position = ref.watch(positionProvider).valueOrNull?.position;
  if (position == null) return null;
  return regionFor(position.latitude, position.longitude);
});

/// Предложение скачать фотографии региона, в котором человек находится.
///
/// Появляется само, но ничего само не качает: кнопку нажимает человек.
/// Исключение — включённая настройка «автоматически по Wi-Fi», и тогда
/// загрузка всё равно начинается только при Wi-Fi.
///
/// Показывается один раз на регион. Отказался — полоса больше не
/// возвращается, иначе она сопровождала бы всю поездку.
class RegionOffer extends ConsumerStatefulWidget {
  const RegionOffer({super.key});

  @override
  ConsumerState<RegionOffer> createState() => _RegionOfferState();
}

class _RegionOfferState extends ConsumerState<RegionOffer> {
  bool _autoStarted = false;

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(currentRegionProvider);
    if (region == null) return const SizedBox.shrink();

    final installed = ref.watch(installedPacksProvider).valueOrNull ?? {};
    if (installed.containsKey(region.id)) return const SizedBox.shrink();

    final offered = ref.watch(offeredRegionsProvider);
    if (offered.contains(region.id)) return const SizedBox.shrink();

    final manifest = ref.watch(packManifestProvider).valueOrNull;
    if (manifest == null) return const SizedBox.shrink();

    final pack = manifest.packs
        .where((p) => p.regionId == region.id)
        .cast<PackInfo?>()
        .firstWhere((_) => true, orElse: () => null);
    if (pack == null) return const SizedBox.shrink();

    final progress = ref.watch(downloadsProvider)[region.id];
    _maybeAutoStart(pack);

    final l = L.of(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 20,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.offerTitle(region.nameEn),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    l.offerSubtitle(
                      pack.photos,
                      pack.sizeMb.toStringAsFixed(1),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  if (progress != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: LinearProgressIndicator(value: progress),
                    ),
                ],
              ),
            ),
            if (progress == null) ...[
              TextButton(
                onPressed: () => ref
                    .read(offeredRegionsProvider.notifier)
                    .markOffered(region.id),
                child: Text(l.offerLater),
              ),
              FilledButton(
                onPressed: () => _start(pack),
                child: Text(l.downloadsStart),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Автозагрузка — только при включённой настройке и только по Wi-Fi.
  void _maybeAutoStart(PackInfo pack) {
    if (_autoStarted) return;
    if (!ref.read(autoDownloadWifiProvider)) return;
    if (ref.read(onWifiProvider).valueOrNull != true) return;

    _autoStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start(pack);
    });
  }

  Future<void> _start(PackInfo pack) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = L.of(context);
    try {
      await ref.read(downloadsProvider.notifier).download(pack);
      ref.read(offeredRegionsProvider.notifier).markOffered(pack.regionId);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${l.downloadsFailed}: $e')),
      );
    }
  }
}
