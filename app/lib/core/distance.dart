import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Расстояние и направление словами.
///
/// Раньше эти функции жили в экране «Рядом со мной» и возвращали русский
/// текст жёстко: «4.2 км», «СВ». На английской или китайской локали
/// человек видел ровно то же самое — ошибка не бросалась в глаза, потому
/// что разработка ведётся по-русски, а тесты проверяли числа, а не буквы.
///
/// Точность подобрана под задачу «дойти или доехать»: до километра
/// показываем метры целыми, дальше — десятые доли, а за десять километров
/// десятые уже не нужны. «4237 метров» никому не помогает.
String formatDistance(BuildContext context, double meters) {
  final l = L.of(context);
  if (meters < 1000) return l.distanceMeters(meters.round());
  if (meters < 10000) {
    return l.distanceKm((meters / 1000).toStringAsFixed(1));
  }
  return l.distanceKm((meters / 1000).round().toString());
}

/// Сторона света по азимуту.
///
/// Восемь румбов, а не шестнадцать: «северо-северо-восток» человек всё
/// равно не отличит от «северо-востока», стоя на смотровой площадке.
String compassLabel(BuildContext context, double bearing) {
  final l = L.of(context);
  final points = [
    l.compassN,
    l.compassNE,
    l.compassE,
    l.compassSE,
    l.compassS,
    l.compassSW,
    l.compassW,
    l.compassNW,
  ];
  final index = ((bearing + 22.5) % 360 ~/ 45).clamp(0, 7);
  return points[index];
}
