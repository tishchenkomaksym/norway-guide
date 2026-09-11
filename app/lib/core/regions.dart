import 'package:flutter/foundation.dart';

/// Регионы скачивания — те же, что в пайплайне.
///
/// ВАЖНО: этот список обязан совпадать с `pipeline/internal/regions`.
/// Расхождение проявится тихо и неприятно: приложение предложит скачать
/// «Фьорды» человеку, чьи места на самом деле лежат в пакете «Рогаланд»,
/// и после загрузки фотографий не прибавится. Поэтому в обоих проектах
/// стоят одинаковые тесты по одним и тем же контрольным точкам —
/// расхождение ловится ими, а не пользователем.
///
/// Дублирование здесь осознанное. Альтернатива — присылать границы
/// в манифесте — означала бы, что без сети приложение не знает, где
/// находится человек, а это ровно тот случай, ради которого всё и
/// затевалось: турист во фьорде без связи.
@immutable
class DownloadRegion {
  const DownloadRegion({
    required this.id,
    required this.nameEn,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  final String id;
  final String nameEn;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  bool contains(double lat, double lon) =>
      lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
}

/// Порядок важен: первый подошедший выигрывает. Рогаланд стоит перед
/// фьордами, потому что прямоугольники перекрываются, а Кьераг с
/// Прекестуленом должны попадать в один пакет — их смотрят за одну поездку.
const downloadRegions = <DownloadRegion>[
  DownloadRegion(
    id: 'svalbard',
    nameEn: 'Svalbard',
    minLat: 74.0,
    maxLat: 81.5,
    minLon: 5.0,
    maxLon: 40.0,
  ),
  DownloadRegion(
    id: 'north',
    nameEn: 'Northern Norway',
    minLat: 68.6,
    maxLat: 72.0,
    minLon: 10.0,
    maxLon: 32.0,
  ),
  DownloadRegion(
    id: 'lofoten',
    nameEn: 'Lofoten and Nordland',
    minLat: 65.0,
    maxLat: 68.6,
    minLon: 10.0,
    maxLon: 20.0,
  ),
  DownloadRegion(
    id: 'trondelag',
    nameEn: 'Trøndelag',
    minLat: 62.5,
    maxLat: 65.0,
    minLon: 7.0,
    maxLon: 15.0,
  ),
  DownloadRegion(
    id: 'rogaland',
    nameEn: 'Rogaland',
    minLat: 58.2,
    maxLat: 59.6,
    minLon: 5.0,
    maxLon: 7.2,
  ),
  DownloadRegion(
    id: 'fjords',
    nameEn: 'Fjord Norway',
    minLat: 59.0,
    maxLat: 63.2,
    minLon: 4.0,
    maxLon: 8.6,
  ),
  DownloadRegion(
    id: 'south',
    nameEn: 'Southern Norway',
    minLat: 57.5,
    maxLat: 59.3,
    minLon: 6.5,
    maxLon: 10.0,
  ),
  DownloadRegion(
    id: 'east',
    nameEn: 'Eastern Norway',
    minLat: 58.5,
    maxLat: 62.8,
    minLon: 7.5,
    maxLon: 13.0,
  ),
];

/// Регион точки — или null, если человек не в Норвегии.
///
/// В отличие от пайплайна, здесь нет региона-уловителя: там он нужен,
/// чтобы ни один снимок не потерялся, а тут null означает «предлагать
/// нечего». Человеку в Берлине незачем видеть предложение скачать
/// норвежские фотографии.
DownloadRegion? regionFor(double lat, double lon) {
  for (final region in downloadRegions) {
    if (region.contains(lat, lon)) return region;
  }
  return null;
}
