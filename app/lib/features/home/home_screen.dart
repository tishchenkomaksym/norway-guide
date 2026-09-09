import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cities/cities_screen.dart';
import '../nearby/nearby_screen.dart';
import 'fjord_backdrop.dart';

/// Стартовый экран: два способа начать.
///
/// Никаких вопросов при входе — сперва человек видит, что это за приложение,
/// и выбирает путь. Вопрос об интересах приходит позже, по сигналу
/// заинтересованности (docs/onboarding-profiles.md).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onBackdrop = dark ? Colors.white : const Color(0xFF08202E);

    return Scaffold(
      // Без прокрутки: Spacer требует ограниченной высоты, а
      // SingleChildScrollView даёт неограниченную — вместе они роняют
      // построение, и на экране остаётся один фон.
      body: FjordBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                Text(
                  'nordguide',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: onBackdrop,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Норвегия без интернета',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: onBackdrop.withValues(alpha: 0.75),
                      ),
                ),
                const Spacer(flex: 3),
                _ChoiceCard(
                  icon: Icons.near_me,
                  title: 'Что интересного рядом',
                  subtitle: 'Ближайшие места с расстоянием и направлением',
                  onTap: () => _go(context, const NearbyScreen()),
                ),
                const SizedBox(height: 12),
                _ChoiceCard(
                  icon: Icons.location_city,
                  title: 'Города и достопримечательности',
                  subtitle: 'Смотреть по городам и регионам страны',
                  onTap: () => _go(context, const CitiesScreen()),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 28, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
