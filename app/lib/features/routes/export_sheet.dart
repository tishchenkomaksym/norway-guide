import 'package:flutter/material.dart';

import '../../core/gpx_share.dart';
import '../../l10n/app_localizations.dart';

/// Объяснение перед отправкой файла маршрута.
///
/// Зачем оно нужно. Без него человек нажимает значок «поделиться»,
/// получает файл с расширением `.gpx` — и остаётся с ним один на один.
/// Что это, куда его девать и почему он не открывается двойным нажатием,
/// неочевидно никому, кроме тех, кто и так знает.
///
/// Поэтому вместо немедленной отправки показывается лист: что это за файл,
/// куда его можно открыть и чего он НЕ делает. Последнее важно не меньше:
/// человек, ожидающий навигацию внутри нашего приложения, будет разочарован
/// вдвойне, если мы пообещаем это намёком.
Future<void> showExportSheet(
  BuildContext context, {
  required String fileName,
  required String content,
  required String subject,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l = L.of(sheetContext);
      final theme = Theme.of(sheetContext);

      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hiking, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.exportSheetTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.exportSheetWhat, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),

            // Конкретные названия приложений, а не «совместимые устройства»:
            // человек должен узнать своё или понять, что оно не для него.
            _Point(text: l.exportSheetApps),
            _Point(text: l.exportSheetWatches),

            const SizedBox(height: 12),
            // Чего файл не делает. Обещать навигацию мы не можем и не будем.
            Text(
              l.exportSheetNot,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l.exportSheetCancel),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.ios_share, size: 18),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await shareGpx(
                      context,
                      fileName: fileName,
                      content: content,
                      subject: subject,
                    );
                  },
                  label: Text(l.exportSheetSend),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _Point extends StatelessWidget {
  const _Point({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
