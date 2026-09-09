import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Заставка: стилизованный фьорд, нарисованный кодом.
///
/// Намеренно не фотография. Снимки придут из Wikimedia Commons и обязаны
/// нести автора и лицензию (§7 спеки); класть чужое фото в бандл «на время»
/// нельзя. Рисунок ничего не весит, масштабируется под любой экран и
/// одинаково выглядит в светлой и тёмной теме.
class FjordBackdrop extends StatelessWidget {
  const FjordBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _FjordPainter(dark: dark)),
        ?child,
      ],
    );
  }
}

class _FjordPainter extends CustomPainter {
  _FjordPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Небо: холодный северный градиент, к горизонту светлее.
    final sky = dark
        ? const [Color(0xFF0B1B2B), Color(0xFF15364B), Color(0xFF2C5C74)]
        : const [Color(0xFF9FC6DE), Color(0xFFCFE3ED), Color(0xFFE8F1F5)];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Offset.zero & Size(w, h * 0.62)),
    );

    final waterLine = h * 0.62;

    // Три гряды гор: дальняя бледнее, ближняя темнее — так читается глубина.
    _mountains(
      canvas,
      w,
      waterLine,
      baseY: waterLine,
      height: h * 0.26,
      seed: 3,
      peaks: 5,
      color: dark ? const Color(0xFF1D3A4E) : const Color(0xFF8FAEC2),
    );
    _mountains(
      canvas,
      w,
      waterLine,
      baseY: waterLine,
      height: h * 0.34,
      seed: 11,
      peaks: 4,
      color: dark ? const Color(0xFF162C3C) : const Color(0xFF5F8399),
    );
    _mountains(
      canvas,
      w,
      waterLine,
      baseY: waterLine,
      height: h * 0.44,
      seed: 7,
      peaks: 3,
      color: dark ? const Color(0xFF0E1F2C) : const Color(0xFF3A5D72),
    );

    // Вода.
    canvas.drawRect(
      Rect.fromLTRB(0, waterLine, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [Color(0xFF0C2233), Color(0xFF061520)]
              : const [Color(0xFF3E7392), Color(0xFF1E4B63)],
        ).createShader(Rect.fromLTRB(0, waterLine, w, h)),
    );

    // Отражение гор в воде: то же, но перевёрнуто и приглушено.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, waterLine, w, h));
    canvas.translate(0, waterLine * 2);
    canvas.scale(1, -1);
    _mountains(
      canvas,
      w,
      waterLine,
      baseY: waterLine,
      height: h * 0.44,
      seed: 7,
      peaks: 3,
      color: (dark ? const Color(0xFF0E1F2C) : const Color(0xFF3A5D72))
          .withValues(alpha: 0.35),
    );
    canvas.restore();

    // Блики на воде — короткие горизонтальные штрихи, редеющие к низу.
    final glint = Paint()
      ..color = (dark ? Colors.white : Colors.white).withValues(alpha: 0.10)
      ..strokeWidth = 1.2;
    final rnd = math.Random(42);
    for (var i = 0; i < 40; i++) {
      final y = waterLine + rnd.nextDouble() * (h - waterLine);
      final len = (1 - (y - waterLine) / (h - waterLine)) * w * 0.18 + 8;
      final x = rnd.nextDouble() * (w - len);
      canvas.drawLine(Offset(x, y), Offset(x + len, y), glint);
    }
  }

  /// Гряда гор: ломаная из [peaks] вершин со случайной, но стабильной формой.
  void _mountains(
    Canvas canvas,
    double w,
    double waterLine, {
    required double baseY,
    required double height,
    required int seed,
    required int peaks,
    required Color color,
  }) {
    final rnd = math.Random(seed);
    final path = Path()..moveTo(0, baseY);

    final step = w / peaks;
    var x = 0.0;
    path.lineTo(0, baseY - height * (0.45 + rnd.nextDouble() * 0.2));

    for (var i = 0; i < peaks; i++) {
      final peakX = x + step * (0.35 + rnd.nextDouble() * 0.3);
      final peakY = baseY - height * (0.6 + rnd.nextDouble() * 0.4);
      final valleyX = x + step;
      final valleyY = baseY - height * (0.25 + rnd.nextDouble() * 0.25);
      path.lineTo(peakX, peakY);
      path.lineTo(valleyX, valleyY);
      x = valleyX;
    }

    path
      ..lineTo(w, baseY)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _FjordPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
