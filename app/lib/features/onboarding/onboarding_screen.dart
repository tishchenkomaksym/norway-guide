import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile.dart';
import '../../core/settings.dart';
import '../../l10n/app_localizations.dart';
import '../home/fjord_backdrop.dart';

/// Вопрос «кто вы» перед первым входом.
///
/// Показывается один раз: дальше приложение открывается сразу на главном
/// экране. Ответ определяет, что показывать первым, но ничего не скрывает —
/// полный каталог остаётся доступен через поиск и фильтры.
///
/// Решение пересмотрено 2026-09-10: раньше вопрос задавался позже, после
/// трёх открытых карточек. Обоснование обратного порядка — в
/// docs/decisions.md; вкратце, у рыбака и охотника выдача отличается
/// настолько, что показывать им общий список бессмысленно.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final profile = ref.watch(profileProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onBackdrop = dark ? Colors.white : const Color(0xFF08202E);

    return Scaffold(
      body: FjordBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.onboardingTitle,
                        style: TextStyle(
                          color: onBackdrop,
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.onboardingSubtitle,
                        style: TextStyle(
                          color: onBackdrop.withValues(alpha: 0.75),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final interest in interests)
                            _InterestChip(
                              interest: interest,
                              selected: profile.interestIds.contains(
                                interest.id,
                              ),
                              onTap: () => ref
                                  .read(profileProvider.notifier)
                                  .toggleInterest(interest.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Оговорка сразу, а не после выбора: человек должен
                      // понимать, что ничего не потеряет, отметив одно.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 15,
                            color: onBackdrop.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.onboardingNothingHidden,
                              style: TextStyle(
                                color: onBackdrop.withValues(alpha: 0.6),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        l.profileSkip,
                        style: TextStyle(
                          color: onBackdrop.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _finish,
                      child: Text(
                        profile.isEmpty ? l.onboardingStart : l.profileNext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _finish() {
    // Отмечаем, что спрашивали, даже если человек пропустил: повторять
    // вопрос при каждом запуске — худшее, что можно сделать с онбордингом.
    ref.read(profileProvider.notifier).markAnswered();
    widget.onDone();
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primary : Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(interest.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                interestLabel(context, interest.id),
                style: TextStyle(
                  color: selected ? scheme.onPrimary : Colors.white,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
