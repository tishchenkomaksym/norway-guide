import 'package:flutter/material.dart';

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

const emergencyContacts = <EmergencyContact>[
  EmergencyContact(
    number: '113',
    title: 'Скорая помощь',
    subtitle: 'Ambulanse · угроза жизни, тяжёлая травма',
    icon: Icons.medical_services,
    color: Color(0xFFC62828),
    critical: true,
  ),
  EmergencyContact(
    number: '112',
    title: 'Полиция',
    subtitle: 'Politi · преступление, авария, пропал человек',
    icon: Icons.local_police,
    color: Color(0xFF1565C0),
    critical: true,
  ),
  EmergencyContact(
    number: '110',
    title: 'Пожарная служба',
    subtitle: 'Brann · пожар, задымление, утечка газа',
    icon: Icons.local_fire_department,
    color: Color(0xFFE65100),
    critical: true,
  ),
  EmergencyContact(
    number: '116 117',
    title: 'Дежурный врач',
    subtitle: 'Legevakt · срочно, но жизни ничто не угрожает',
    icon: Icons.health_and_safety,
    color: Color(0xFF2E7D32),
  ),
  EmergencyContact(
    number: '120',
    title: 'Спасение на воде',
    subtitle: 'Hovedredningssentralen · происшествие в море',
    icon: Icons.sailing,
    color: Color(0xFF00695C),
  ),
  EmergencyContact(
    number: '22 59 13 00',
    title: 'Отравления',
    subtitle: 'Giftinformasjonen · круглосуточно',
    icon: Icons.science,
    color: Color(0xFF6A1B9A),
  ),
  EmergencyContact(
    number: '175',
    title: 'Дорожная служба',
    subtitle: 'Vegtrafikksentralen · перекрытые дороги, лавины',
    icon: Icons.warning_amber,
    color: Color(0xFFF9A825),
  ),
];

/// Что важно знать до того, как придётся звонить.
///
/// Не медицинские советы: приложение не имеет права их давать. Только
/// сведения о том, как устроен вызов помощи в Норвегии.
const emergencyNotes = <(IconData, String, String)>[
  (
    Icons.signal_cellular_alt,
    'Работает без сети и без SIM',
    'Звонок на 112 и 113 проходит через любую доступную вышку, даже если '
        'у вашего оператора нет покрытия и в телефоне нет SIM-карты.'
  ),
  (
    Icons.my_location,
    'Назовите координаты',
    'В горах и на фьордах адреса нет. Продиктуйте широту и долготу — они '
        'ниже на этом экране, их можно скопировать. Оператор поймёт.'
  ),
  (
    Icons.translate,
    'Английский понимают',
    'Операторы экстренных служб Норвегии говорят по-английски. Говорите '
        'спокойно и коротко: что случилось, где, сколько пострадавших.'
  ),
  (
    Icons.hiking,
    'В горах — 112',
    'Спасением в горах занимается полиция, отдельного номера нет. '
        'Не выключайте телефон: по нему вас будут искать.'
  ),
];
