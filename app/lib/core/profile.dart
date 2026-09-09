import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.label,
    required this.emoji,
    required this.weights,
    this.tags = const {},
  });

  final String id;
  final String label;
  final String emoji;

  /// Категория места → прибавка к весу.
  final Map<String, double> weights;

  /// Мультитеги, которые этот интерес поднимает (см. таблицу place_tags).
  final Map<String, double> tags;
}

const interests = <Interest>[
  Interest(
    id: 'nature',
    label: 'Природа и виды',
    emoji: '🏔',
    weights: {'fjord': 1.0, 'viewpoint': 0.8, 'waterfall': 0.8, 'glacier': 0.8},
  ),
  Interest(
    id: 'hiking',
    label: 'Походы и треккинг',
    emoji: '🥾',
    weights: {'hike': 1.2, 'viewpoint': 0.5, 'glacier': 0.4},
  ),
  Interest(
    id: 'fishing',
    label: 'Рыбалка',
    emoji: '🎣',
    weights: {'beach': 0.6, 'fjord': 0.5},
    tags: {'fishing': 1.2},
  ),
  Interest(
    id: 'culture',
    label: 'Музеи и культура',
    emoji: '🏛',
    weights: {'museum': 1.2, 'church': 0.9},
    tags: {'unesco': 0.6},
  ),
  Interest(
    id: 'photo',
    label: 'Фотография',
    emoji: '📷',
    weights: {'viewpoint': 1.1, 'waterfall': 0.9, 'fjord': 0.7, 'glacier': 0.6},
  ),
  Interest(
    id: 'kids',
    label: 'С детьми',
    emoji: '👨‍👩‍👧',
    weights: {'museum': 0.5, 'beach': 0.6},
    tags: {'kids_friendly': 1.3},
  ),
  Interest(
    id: 'roadtrip',
    label: 'Автопутешествие',
    emoji: '🚐',
    weights: {'viewpoint': 0.8, 'waterfall': 0.6, 'fjord': 0.6},
  ),
  Interest(
    id: 'winter',
    label: 'Зимний спорт',
    emoji: '⛷',
    weights: {'glacier': 0.5},
    tags: {'winter_open': 1.0},
  ),
  Interest(
    id: 'cruise',
    label: 'Круиз, несколько часов',
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

class ProfileNotifier extends StateNotifier<UserProfile> {
  ProfileNotifier() : super(const UserProfile());

  void toggleInterest(String id) {
    final next = Set<String>.from(state.interestIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(interestIds: next);
  }

  void setTravelTime(TravelTime time) {
    state = state.copyWith(travelTime: time);
  }

  void markAnswered() {
    state = state.copyWith(answered: true);
  }

  void reset() {
    state = const UserProfile();
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, UserProfile>((ref) {
  return ProfileNotifier();
});

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
