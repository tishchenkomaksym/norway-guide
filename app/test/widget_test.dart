import 'package:flutter_test/flutter_test.dart';
import 'package:nordguide/data/database.dart';

void main() {
  group('расстояние и направление', () {
    test('расстояние Осло — Берген примерно 305 км', () {
      final d = distanceMeters(59.9139, 10.7522, 60.3913, 5.3221);
      expect(d / 1000, closeTo(305, 15));
    });

    test('расстояние до самой себя равно нулю', () {
      expect(distanceMeters(60.0, 5.0, 60.0, 5.0), closeTo(0, 0.001));
    });

    test('Берген строго западнее Осло', () {
      final b = bearingDegrees(59.9139, 10.7522, 60.3913, 5.3221);
      // Запад — это около 270°, с поправкой на то, что Берген чуть севернее.
      expect(b, greaterThan(240));
      expect(b, lessThan(300));
    });

    test('направление на север равно нулю градусов', () {
      final b = bearingDegrees(60.0, 5.0, 61.0, 5.0);
      expect(b, closeTo(0, 0.5));
    });
  });
}
