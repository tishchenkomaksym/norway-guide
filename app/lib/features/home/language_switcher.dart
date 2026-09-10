import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// ВРЕМЕННЫЙ переключатель языка.
///
/// По решению из CLAUDE.md экрана выбора языка в приложении нет: язык
/// берётся из системы. Этот переключатель существует только чтобы
/// проверять переводы, не меняя язык всего телефона.
///
/// **Убрать перед релизом.** Оставленный в продукте, он противоречит
/// принятому решению и добавляет в интерфейс выбор, который человеку
/// делать не нужно.
class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.onDark = false});

  final bool onDark;

  /// Название языка на нём самом: человек, ищущий свой язык, узнаёт его
  /// написание, а не перевод на чужой.
  static const _names = {
    'ru': 'Русский',
    'en': 'English',
    'no': 'Norsk',
    'de': 'Deutsch',
    'es': 'Español',
    'zh': '中文',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.translate,
        color: onDark ? Colors.white70 : null,
        size: 22,
      ),
      tooltip: 'Язык (временно, для проверки переводов)',
      initialValue: current,
      onSelected: (lang) =>
          ref.read(languageProvider.notifier).state = lang,
      itemBuilder: (context) => [
        for (final entry in _names.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: entry.key == current
                      ? const Icon(Icons.check, size: 18)
                      : null,
                ),
                Text(entry.value),
              ],
            ),
          ),
      ],
    );
  }
}
