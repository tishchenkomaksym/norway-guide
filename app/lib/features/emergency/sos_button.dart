import 'package:flutter/material.dart';

import 'emergency_screen.dart';

/// Кнопка вызова экстренной помощи.
///
/// Красная и заметная, но не навязчивая: человек должен найти её мгновенно,
/// когда понадобится, и не спотыкаться о неё в обычной поездке.
///
/// Ставится в шапку экранов, а не плавающей кнопкой поверх списков:
/// плавающая перекрывала бы карточки и нажималась случайно.
class SosButton extends StatelessWidget {
  const SosButton({super.key, this.onDark = false});

  /// На тёмной подложке (фото на главном экране) нужен светлый контур.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFC62828);
    final background = onDark ? Colors.white.withValues(alpha: 0.16) : red;
    final foreground = onDark ? Colors.white : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmergencyScreen()),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: onDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.35))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emergency, size: 16, color: foreground),
                const SizedBox(width: 5),
                Text(
                  'SOS',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
