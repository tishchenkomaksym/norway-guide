import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'settings.dart';

/// Профиль пользователя: что ему интересно и когда он едет.
///
/// Ключевое правило (CLAUDE.md, docs/onboarding-profiles.md): профиль
/// **ранжирует, но не скрывает**. Полный каталог остаётся доступен через
/// поиск и фильтры. Человек выбирает интересы за три секунды на экране,
/// смысл которого ещё не понимает, — строить на этом необратимые решения
/// нельзя.

/// Интерес пользователя и веса, которые он даёт категориям мест.
class Interest {
  const Interest({
    required this.id,
    required this.emoji,
    required this.weights,
    this.tags = const {},
  });

  final String id;
  final String emoji;

  /// Категория места → прибавка к весу.
  final Map<String, double> weights;

  /// Мультитеги, которые этот интерес поднимает (см. таблицу place_tags).
  final Map<String, double> tags;
}

const interests = <Interest>[
  Interest(
    id: 'nature',
    emoji: '🏔',
    weights: {'fjord': 1.0, 'viewpoint': 0.8, 'waterfall': 0.8, 'glacier': 0.8},
  ),
  Interest(
    id: 'hiking',
    emoji: '🥾',
    weights: {'hike': 1.2, 'viewpoint': 0.5, 'glacier': 0.4},
  ),
  Interest(
    id: 'fishing',
    emoji: '🎣',
    weights: {'beach': 0.6, 'fjord': 0.5, 'lake': 1.2, 'river': 1.0},
    tags: {'fishing': 1.5},
  ),
  Interest(
    id: 'hunting',
    emoji: '🏹',
    weights: {'hike': 0.3},
    tags: {'hunting': 1.5},
  ),
  Interest(
    id: 'culture',
    emoji: '🏛',
    weights: {'museum': 1.2, 'church': 0.9},
    tags: {'unesco': 0.6},
  ),
  Interest(
    id: 'photo',
    emoji: '📷',
    weights: {'viewpoint': 1.1, 'waterfall': 0.9, 'fjord': 0.7, 'glacier': 0.6},
  ),
  Interest(
    id: 'kids',
    emoji: '👨‍👩‍👧',
    weights: {'museum': 0.5, 'beach': 0.6},
    tags: {'kids_friendly': 1.3},
  ),
  Interest(
    id: 'roadtrip',
    emoji: '🚐',
    weights: {'viewpoint': 0.8, 'waterfall': 0.6, 'fjord': 0.6},
  ),
  Interest(
    id: 'winter',
    emoji: '⛷',
    weights: {'glacier': 0.5},
    tags: {'winter_open': 1.0},
  ),
  Interest(
    id: 'cruise',
    emoji: '🚢',
    weights: {},
    tags: {'near_port': 1.5},
  ),
];

/// Когда человек путешествует. Влияет на сезонные ограничения: горные дороги
/// закрыты с октября по май, и предлагать их зимой — значит отправить человека
/// к закрытому шлагбауму.
enum TravelTime { now, soon, browsing }

class UserProfile {
  const UserProfile({
    this.interestIds = const {},
    this.travelTime,
    this.answered = false,
  });

  final Set<String> interestIds;
  final TravelTime? travelTime;

  /// Вопрос уже задавали. Повторно не пристаём — менять можно в настройках.
  final bool answered;

  bool get isEmpty => interestIds.isEmpty;

  UserProfile copyWith({
    Set<String>? interestIds,
    TravelTime? travelTime,
    bool? answered,
  }) {
    return UserProfile(
      interestIds: interestIds ?? this.interestIds,
      travelTime: travelTime ?? this.travelTime,
      answered: answered ?? this.answered,
    );
  }

  /// Прибавка к весу места этой категории с этими тегами.
  double boostFor(String category, Set<String> placeTags) {
    if (interestIds.isEmpty) return 0;
    var boost = 0.0;
    for (final interest in interests) {
      if (!interestIds.contains(interest.id)) continue;
      boost += interest.weights[category] ?? 0;
      for (final tag in placeTags) {
        boost += interest.tags[tag] ?? 0;
      }
    }
    return boost;
  }
}

/// Подпись интереса на языке пользователя.
///
/// Раньше подписи лежали прямо в описании интересов и были только
/// по-русски: приложение на шести языках предлагало бы немцу выбрать
/// «Рыбалка».
String interestLabel(BuildContext context, String id) {
  final l = L.of(context);
  switch (id) {
    case 'nature':
      return l.intNature;
    case 'hiking':
      return l.intHiking;
    case 'fishing':
      return l.intFishing;
    case 'hunting':
      return l.intHunting;
    case 'culture':
      return l.intCulture;
    case 'photo':
      return l.intPhoto;
    case 'kids':
      return l.intKids;
    case 'roadtrip':
      return l.intRoadtrip;
    case 'winter':
      return l.intWinter;
    case 'cruise':
      return l.intCruise;
    default:
      return id;
  }
}

/// Счётчик открытых карточек — один из триггеров вопроса о профиле.
final placeViewCountProvider = StateProvider<int>((ref) => 0);

/// Пора ли спрашивать про интересы.
///
/// Сигнал заинтересованности, а не таймер: человек уже полистал приложение
/// и понимает, зачем отвечает. См. docs/onboarding-profiles.md.
final shouldAskProfileProvider = Provider<bool>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile.answered) return false;
  return ref.watch(placeViewCountProvider) >= 3;
});
