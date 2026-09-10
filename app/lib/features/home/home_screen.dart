import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/attribution.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../cities/browse_screen.dart';
import '../emergency/emergency_button.dart';
import '../favorites/favorites_screen.dart';
import '../nearby/nearby_screen.dart';
import '../top/most_visited_screen.dart';
import 'attribution_screen.dart';
import 'interest_prompt.dart';
import 'language_switcher.dart';

/// Стартовый экран.
///
/// Устроен как в туристических приложениях: фотография на весь экран,
/// затемнение к низу, название и способы начать поверх снимка. Смысл приёма
/// не в красоте — фотография места сразу отвечает на вопрос «о чём это
/// приложение» быстрее любого текста.
///
/// Никаких вопросов при входе: профиль спрашивается позже, по сигналу
/// заинтересованности (docs/onboarding-profiles.md).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Рорбу под северным сиянием — иллюстрация, нарисованная нейросетью
  // (метка C2PA trainedAlgorithmicMedia в файле). Это не снимок реального
  // места, и в экране источников она так и подписана.
  //
  // Верхние 30% исходника срезаны: там была нарисована надпись
  // «Norway Explore». Заголовок рисует само приложение и берёт его из
  // локализации — иначе на русском и китайском экране висел бы английский
  // текст, а заголовков оказалось бы два. Обрезка делается командой
  // `go run ./cmd/appart splash`, чтобы замена картинки не превращалась
  // в ручную возню в редакторе.
  //
  // Прежняя заставка — настоящее фото Гейрангера со смотровой Эрнесвинген —
  // осталась в assets и в справочнике атрибуции.
  static const heroPhoto = 'assets/images/first-screen.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final credit = creditFor(heroPhoto);
    final favoriteCount = ref.watch(favoritesProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            heroPhoto,
            fit: BoxFit.cover,
            // Пока фото грузится, показываем ровный тёмный фон, а не белую
            // вспышку: на старте приложения она особенно заметна.
            frameBuilder: (context, child, frame, wasSync) {
              if (wasSync || frame != null) return child;
              return Container(color: const Color(0xFF0B1B2B));
            },
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFF0B1B2B)),
          ),

          // Затемнение снизу: без него белый текст читается через раз,
          // в зависимости от того, что попало в кадр.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 1.0],
                colors: [
                  Color(0x33000000),
                  Color(0x66000000),
                  Color(0xE6000B14),
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),

          // Прокрутка включается только когда содержимое не помещается.
          //
          // С четвёртой плашкой экран перестал влезать в 360×640 — типичный
          // недорогой телефон — и переполнялся на 132 пикселя. Простой
          // SingleChildScrollView здесь не годится: Spacer внутри него теряет
          // ограничение по высоте, и экран однажды уже перестал строиться
          // вовсе, оставив одну фотографию. Связка ConstrainedBox с
          // minHeight и IntrinsicHeight возвращает Spacer конечную высоту:
          // на большом экране вёрстка та же, что была, на маленьком
          // содержимое прокручивается.
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Временно, для проверки переводов — см. класс.
                              const LanguageSwitcher(onDark: true),
                              const EmergencyButton(onDark: true),
                              IconButton(
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white70,
                                ),
                                tooltip: l.sourcesTooltip,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AttributionScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            l.appTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              height: 1.05,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.appTagline,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _ChoiceCard(
                            icon: Icons.near_me,
                            title: l.nearbyTitle,
                            subtitle: l.nearbySubtitle,
                            onTap: () => _go(context, const NearbyScreen()),
                          ),
                          const SizedBox(height: 10),
                          _ChoiceCard(
                            icon: Icons.explore_outlined,
                            title: l.browseTitle,
                            subtitle: l.browseSubtitle,
                            onTap: () => _go(context, const BrowseScreen()),
                          ),
                          const SizedBox(height: 10),
                          // Топ-20 стоит отдельной плашкой, а не вкладкой внутри
                          // «Куда поехать»: это ответ на первый вопрос человека,
                          // который едет в страну впервые, и прятать его на второй
                          // уровень — значит заставлять искать очевидное.
                          _ChoiceCard(
                            icon: Icons.star_outline,
                            title: l.mostVisitedTitle,
                            subtitle: l.mostVisitedSubtitle,
                            onTap: () =>
                                _go(context, const MostVisitedScreen()),
                          ),
                          // Третий путь появляется, только когда в нём есть смысл:
                          // пустое «Моя поездка» на первом запуске — это обещание
                          // без содержания.
                          if (favoriteCount > 0) ...[
                            const SizedBox(height: 10),
                            _ChoiceCard(
                              icon: Icons.favorite_border,
                              title: l.favoritesTitle,
                              subtitle: l.favoritesSaved(favoriteCount),
                              onTap: () =>
                                  _go(context, const FavoritesScreen()),
                            ),
                          ],
                          const InterestPrompt(),
                          const SizedBox(height: 14),
                          // Подпись под снимком существует ради лицензии:
                          // CC BY-SA требует указывать автора везде, где
                          // показана фотография. У нарисованной картинки
                          // такого требования нет, и подпись на заставке
                          // была бы шумом. Запись о ней остаётся в экране
                          // источников — там она к месту.
                          if (credit != null && !credit.generated)
                            Text(
                              l.photoBy(credit.short),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // Склонение числительных больше не пишем руками: ARB-формат берёт
  // правила множественного числа из ICU, и они разные для каждого языка —
  // в русском три формы, в английском две, в китайском одна.
}

/// Полупрозрачная карточка поверх фотографии.
///
/// Матовая, а не сплошная: сквозь неё виден снимок, и экран не распадается
/// на «картинку сверху и панель снизу».
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
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
