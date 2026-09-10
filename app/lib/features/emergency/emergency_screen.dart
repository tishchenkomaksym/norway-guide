import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import 'emergency_data.dart';

/// Экстренная помощь.
///
/// Экран рассчитан на человека в стрессе: крупные кнопки, минимум текста,
/// самое важное сверху. Никакой прокрутки до главного — три номера службы
/// спасения видны сразу.
///
/// Работает полностью офлайн, и это не побочный эффект: именно там, где
/// нет интернета, помощь и нужна.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final critical = emergencyContacts.where((c) => c.critical).toList();
    final other = emergencyContacts.where((c) => !c.critical).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экстренная помощь'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          for (final c in critical) ...[
            _BigCallButton(contact: c),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          const _CoordinatesCard(),
          const SizedBox(height: 18),
          Text('Другие службы',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final c in other) _SmallCallTile(contact: c),
          const SizedBox(height: 22),
          Text('Что важно знать',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final (icon, title, body) in emergencyNotes)
            _Note(icon: icon, title: title, body: body),
          const SizedBox(height: 16),
          Text(
            'Номера действительны для Норвегии. Проверены 10.09.2026 по '
            'источникам politiet.no, helsenorge.no, hovedredningssentralen.no.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

/// Крупная кнопка вызова: набирается одним нажатием, промахнуться сложно.
class _BigCallButton extends StatelessWidget {
  const _BigCallButton({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: contact.color,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _call(context, contact),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(contact.icon, color: Colors.white, size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                contact.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallCallTile extends StatelessWidget {
  const _SmallCallTile({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.color.withValues(alpha: 0.15),
          child: Icon(contact.icon, color: contact.color, size: 20),
        ),
        title: Text(contact.title),
        subtitle: Text(contact.subtitle),
        trailing: Text(
          contact.number,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: contact.color,
          ),
        ),
        onTap: () => _call(context, contact),
      ),
    );
  }
}

/// Координаты для диктовки оператору.
///
/// В горах и на фьордах адреса не существует, и это первое, что спросит
/// диспетчер. Показываем и позволяем скопировать.
class _CoordinatesCard extends ConsumerWidget {
  const _CoordinatesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final origin = ref.watch(searchOriginProvider);
    final manual = ref.watch(mockPositionProvider);
    final scheme = Theme.of(context).colorScheme;

    return origin.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (o) {
        final text = '${o.lat.toStringAsFixed(5)}, ${o.lon.toStringAsFixed(5)}';
        // Если положение указано вручную или неизвестно, честно предупреждаем:
        // продиктовать чужие координаты спасателям хуже, чем никакие.
        final approximate = manual != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Icon(Icons.my_location, color: scheme.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ваши координаты',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        text,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (approximate)
                        Text(
                          'Положение задано вручную — не по GPS',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.error,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Скопировать',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Координаты скопированы')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Набирает номер.
///
/// В браузере набор не работает — там и телефона нет. Показываем номер,
/// чтобы его можно было переписать, вместо молчаливого отказа.
Future<void> _call(BuildContext context, EmergencyContact contact) async {
  final uri = Uri.parse('tel:${contact.dialNumber}');
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
  } catch (_) {
    // Падать на экране экстренной помощи нельзя ни при каких условиях.
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.title}: наберите ${contact.number}'),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
