import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/profile.dart';
import '../../core/providers.dart';
import '../../data/database.dart';
import '../place/place_screen.dart';

/// Второй путь входа: смотреть страну по городам, а не по расстоянию.
///
/// Нужен, когда человек ещё дома и планирует поездку — тогда «рядом со мной»
/// бесполезно, а «что есть в Бергене» это ровно то, что он ищет.
class CitiesScreen extends ConsumerWidget {
  const CitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Города')),
      body: cities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Городов пока нет'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final city = list[i];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.location_city, size: 20),
                ),
                title: Text(city.nameNo),
                subtitle: city.population == null
                    ? null
                    : Text('${_thousands(city.population!)} жителей'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CityScreen(city: city)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Места одного города.
class CityScreen extends ConsumerWidget {
  const CityScreen({super.key, required this.city});

  final City city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesInCityProvider(city.id));

    return Scaffold(
      appBar: AppBar(title: Text(city.nameNo)),
      body: places.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Для этого города мест пока нет',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = list[i];
              return ListTile(
                title: Text(item.name),
                subtitle: item.summary == null
                    ? null
                    : Text(
                        item.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () {
                  ref.read(placeViewCountProvider.notifier).state++;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaceScreen(placeId: item.place.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

String _thousands(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(s[i]);
  }
  return buffer.toString();
}
