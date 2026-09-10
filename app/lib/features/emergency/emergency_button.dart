import 'package:flutter/material.dart';

import 'emergency_screen.dart';

/// Кнопка перехода к экстренной помощи.
///
/// Намеренно неброская: обычная иконка в ряду прочих, без красного цвета
/// и без надписи. Приложение — гид, а не тревожная кнопка, и постоянно
/// напоминать о несчастных случаях человеку в отпуске незачем.
///
/// Узнаваемость держится на самой иконке: «звезда жизни» — международный
/// символ экстренной медицинской помощи, понятный без подписи и на любом
/// языке. Это важнее слова, которое пришлось бы переводить на шесть языков
/// и которое всё равно читается не всеми.
class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key, this.onDark = false});

  /// На тёмной подложке — например, поверх фотографии на главном экране.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.emergency_outlined,
        color: onDark ? Colors.white70 : null,
        size: 22,
      ),
      tooltip: 'Экстренная помощь',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const EmergencyScreen()),
      ),
    );
  }
}
