import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Экстренные службы Норвегии.
///
/// Номера проверены по официальным источникам (politiet.no, helsenorge.no,
/// hovedredningssentralen.no) на 2026-09-10. Они не менялись десятилетиями,
/// но при обновлении данных стоит сверяться заново: ошибка в этом списке
/// опаснее любой другой ошибки в приложении.
///
/// Главное, что нужно знать пользователю: **112 и 113 работают без сети
/// оператора и без SIM-карты** — телефон подключится к любой доступной
/// вышке. Именно поэтому раздел уместен в офлайн-гиде.
class EmergencyContact {
  const EmergencyContact({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.critical = false,
  });

  /// Номер в том виде, в каком его набирают.
  final String number;

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  /// Служба спасения жизни — показывается крупно и первой.
  final bool critical;

  /// Для набора: у норвежских шестизначных номеров вроде 116 117 пробелы
  /// в наборе не нужны.
  String get dialNumber => number.replaceAll(' ', '');
}

/// Список служб на языке пользователя.
///
/// Названия переводятся, но норвежские слова в подписи (Politi, Legevakt,
/// Giftinformasjonen) сохраняются на всех языках: именно их человек увидит
/// на вывеске и услышит от оператора.
List<EmergencyContact> emergencyContacts(BuildContext context) {
  final l = L.of(context);
  return [
    EmergencyContact(
      number: '113',
      title: l.emgAmbulance,
      subtitle: l.emgAmbulanceSub,
      icon: Icons.medical_services,
      color: const Color(0xFFC62828),
      critical: true,
    ),
    EmergencyContact(
      number: '112',
      title: l.emgPolice,
      subtitle: l.emgPoliceSub,
      icon: Icons.local_police,
      color: const Color(0xFF1565C0),
      critical: true,
    ),
    EmergencyContact(
      number: '110',
      title: l.emgFire,
      subtitle: l.emgFireSub,
      icon: Icons.local_fire_department,
      color: const Color(0xFFE65100),
      critical: true,
    ),
    EmergencyContact(
      number: '116 117',
      title: l.emgDoctor,
      subtitle: l.emgDoctorSub,
      icon: Icons.health_and_safety,
      color: const Color(0xFF2E7D32),
    ),
    EmergencyContact(
      number: '120',
      title: l.emgSea,
      subtitle: l.emgSeaSub,
      icon: Icons.sailing,
      color: const Color(0xFF00695C),
    ),
    EmergencyContact(
      number: '22 59 13 00',
      title: l.emgPoison,
      subtitle: l.emgPoisonSub,
      icon: Icons.science,
      color: const Color(0xFF6A1B9A),
    ),
    EmergencyContact(
      number: '175',
      title: l.emgRoad,
      subtitle: l.emgRoadSub,
      icon: Icons.warning_amber,
      color: const Color(0xFFF9A825),
    ),
  ];
}

/// Номера служб отдельно от текстов — для проверок, которым интерфейс
/// не нужен. Ошибка здесь опаснее любой другой в приложении, поэтому
/// список продублирован в тесте.
const emergencyNumbers = <String>['113', '112', '110', '116 117', '120',
    '22 59 13 00', '175'];

/// Что важно знать до того, как придётся звонить.
///
/// Не медицинские советы: приложение не имеет права их давать. Только
/// сведения о том, как устроен вызов помощи в Норвегии.
List<(IconData, String, String)> emergencyNotes(BuildContext context) {
  final l = L.of(context);
  return [
    (Icons.signal_cellular_alt, l.emgNoteSimTitle, l.emgNoteSimBody),
    (Icons.my_location, l.emgNoteCoordsTitle, l.emgNoteCoordsBody),
    (Icons.translate, l.emgNoteEnglishTitle, l.emgNoteEnglishBody),
    (Icons.hiking, l.emgNoteMountainTitle, l.emgNoteMountainBody),
  ];
}
