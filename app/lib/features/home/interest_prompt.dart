import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../profile/profile_sheet.dart';

/// Ненавязчивое приглашение указать интересы — внизу главного экрана.
///
/// Не анкета и не преграда: приложение открывается сразу на содержимом,
/// а это строка, которую можно не заметить. Ориентир по умолчанию —
/// турист; рыбак и охотник получают свою выдачу, только если сами скажут.
///
/// Исчезает, как только человек ответил или закрыл вопрос: показывать
/// одно и то же приглашение каждый запуск — верный способ раздражать.
class InterestPrompt extends ConsumerWidget {
  const InterestPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile.answered || profile.interestIds.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final l = L.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showProfileSheet(context, ref),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 18, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.promptTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l.promptSubtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Крестик, а не только переход: отказаться должно быть
                // так же легко, как согласиться.
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                  tooltip: l.profileSkip,
                  onPressed: () =>
                      ref.read(profileProvider.notifier).markAnswered(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
