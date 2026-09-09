import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile.dart';

/// Вопрос об интересах.
///
/// Появляется НЕ на старте, а после сигнала заинтересованности — когда человек
/// уже полистал приложение (см. docs/onboarding-profiles.md). Показывается
/// один раз: отклонили — больше не пристаём, менять можно в настройках.
///
/// Форма — лист поверх карты, а не полный экран: контент остаётся виден, и это
/// физически передаёт мысль «приложение уже работает, а это лишь уточнение».
Future<void> showProfileSheet(BuildContext context, WidgetRef ref) async {
  ref.read(profileProvider.notifier).markAnswered();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet();

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _step == 0
            ? _interestsStep(context, profile)
            : _timeStep(context),
      ),
    );
  }

  List<Widget> _interestsStep(BuildContext context, UserProfile profile) {
    return [
      Text(
        'Что вам интереснее всего?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(
        'Подберём, что показывать первым. Ничего не спрячем — весь каталог '
        'остаётся доступен через поиск.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final interest in interests)
            FilterChip(
              label: Text('${interest.emoji}  ${interest.label}'),
              selected: profile.interestIds.contains(interest.id),
              onSelected: (_) =>
                  ref.read(profileProvider.notifier).toggleInterest(interest.id),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Пропустить'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Дальше'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _timeStep(BuildContext context) {
    return [
      Text(
        'Когда планируете поездку?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(
        'Горные дороги и часть троп закрыты зимой — не будем предлагать '
        'то, куда сейчас не проехать.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      for (final entry in const {
        TravelTime.now: 'Я сейчас в Норвегии',
        TravelTime.soon: 'В ближайшие месяцы',
        TravelTime.browsing: 'Просто смотрю',
      }.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(profileProvider.notifier).setTravelTime(entry.key);
                Navigator.of(context).pop();
                _confirm(context);
              },
              child: Text(entry.value),
            ),
          ),
        ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Пропустить'),
      ),
    ];
  }

  /// После ответа выдача должна измениться заметно — иначе непонятно, зачем
  /// спрашивали.
  void _confirm(BuildContext context) {
    final count = ref.read(profileProvider).interestIds.length;
    if (count == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Готово — подходящие места теперь выше в списке'
              : 'Готово — учли $count интереса в порядке выдачи',
        ),
      ),
    );
  }
}
