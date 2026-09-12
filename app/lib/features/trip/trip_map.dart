import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Карта поездки: контур Норвегии с отмеченными местами.
///
/// Это не интерактивная карта и не заменитель ей. Тайлов, зума и
/// прокрутки здесь нет — только силуэт страны и точки там, где человек
/// побывал. Такой картинкой можно поделиться, и именно ради неё всё
/// и рисуется.
///
/// Контур взят из Natural Earth (public domain), масштаб 1:50 млн:
/// 1 273 точки, 19 КБ. Более подробный контур весил бы 364 КБ и рисовался
/// заметно дольше, а на экране телефона разницы почти не видно. Свальбард
/// исключён намеренно: он лежит так далеко на севере, что материк рядом
/// с ним превращается в узкую полоску.
class NorwayShape {
  const NorwayShape(this.rings);

  /// Контуры: каждый — замкнутая последовательность точек [долгота, широта].
  final List<List<List<double>>> rings;

  static NorwayShape? _cached;

  static Future<NorwayShape> load() async {
    if (_cached != null) return _cached!;
    final raw = await rootBundle.loadString('assets/geo/norway-shape.json');
    final data = (jsonDecode(raw) as List<dynamic>)
        .map(
          (ring) => (ring as List<dynamic>)
              .map(
                (p) => (p as List<dynamic>)
                    .map((v) => (v as num).toDouble())
                    .toList(),
              )
              .toList(),
        )
        .toList();
    return _cached = NorwayShape(data);
  }

  /// Границы контура — нужны, чтобы вписать карту в отведённое место.
  ({double minLat, double maxLat, double minLon, double maxLon}) get bounds {
    var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (final ring in rings) {
      for (final point in ring) {
        final lon = point[0], lat = point[1];
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
      }
    }
    return (minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon);
  }
}

/// Точка на карте поездки.
@immutable
class TripPoint {
  const TripPoint({
    required this.lat,
    required this.lon,
    this.label,
    this.hasPhoto = false,
  });

  final double lat;
  final double lon;
  final String? label;

  /// У места есть собственный снимок — такие точки выделяются.
  final bool hasPhoto;
}

/// Рисует контур страны и точки поездки.
class TripMapPainter extends CustomPainter {
  TripMapPainter({
    required this.shape,
    required this.points,
    required this.landColor,
    required this.borderColor,
    required this.pointColor,
    required this.photoPointColor,
    required this.backgroundColor,
  });

  final NorwayShape shape;
  final List<TripPoint> points;
  final Color landColor;
  final Color borderColor;
  final Color pointColor;
  final Color photoPointColor;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final b = shape.bounds;

    // Меркатор: без него Норвегия выглядит сплюснутой — на широте 65°
    // градус долготы вдвое короче градуса широты, и страна получается
    // приземистой и неузнаваемой.
    double mercY(double lat) {
      final rad = lat * math.pi / 180;
      return math.log(math.tan(rad) + 1 / math.cos(rad));
    }

    final minY = mercY(b.minLat), maxY = mercY(b.maxLat);
    final spanX = b.maxLon - b.minLon;
    final spanY = maxY - minY;

    // Вписываем с полями, сохраняя пропорции.
    const padding = 12.0;
    final scale = math.min(
      (size.width - padding * 2) / spanX,
      (size.height - padding * 2) / spanY,
    );
    final offsetX = (size.width - spanX * scale) / 2;
    final offsetY = (size.height - spanY * scale) / 2;

    Offset project(double lat, double lon) {
      final x = offsetX + (lon - b.minLon) * scale;
      // Ось Y на экране растёт вниз, а широта — вверх.
      final y = offsetY + (maxY - mercY(lat)) * scale;
      return Offset(x, y);
    }

    final land = Paint()
      ..color = landColor
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (final ring in shape.rings) {
      if (ring.length < 3) continue;
      final path = Path();
      final first = project(ring[0][1], ring[0][0]);
      path.moveTo(first.dx, first.dy);
      for (var i = 1; i < ring.length; i++) {
        final p = project(ring[i][1], ring[i][0]);
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, land);
      canvas.drawPath(path, border);
    }

    // Точки поверх контура. Со снимками — крупнее и другим цветом:
    // именно они и есть история поездки, остальные — просто отметки.
    for (final point in points) {
      final pos = project(point.lat, point.lon);
      final radius = point.hasPhoto ? 6.0 : 4.0;
      final color = point.hasPhoto ? photoPointColor : pointColor;

      canvas.drawCircle(
        pos,
        radius + 1.5,
        Paint()..color = backgroundColor.withValues(alpha: 0.9),
      );
      canvas.drawCircle(pos, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(TripMapPainter old) =>
      old.points != points || old.shape != shape;
}
