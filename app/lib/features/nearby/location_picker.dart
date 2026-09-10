import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/known_places.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

/// Диалог «где вы находитесь».
///
/// Заменяет GPS там, где его нет: на десктопе, при отказе в разрешении или
/// когда определение не сработало. Пользователь пишет название города —
/// поиск понимает и норвежское, и русское, и английское написание,
/// а также вариант без диакритики («alesund» находит «Ålesund»).
Future<void> showLocationPicker(BuildContext context, WidgetRef ref) async {
  final selected = await showDialog<KnownPlace>(
    context: context,
    builder: (_) => const _LocationDialog(),
  );

  if (selected != null) {
    ref.read(mockPositionProvider.notifier).set((
      name: selected.name,
      lat: selected.lat,
      lon: selected.lon,
    ));
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog();

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  final _controller = TextEditingController();
  List<KnownPlace> _results = searchPlaces('');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _results = searchPlaces(value));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L.of(context).whereAreYou),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: L.of(context).cityHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _onChanged,
              onSubmitted: (_) {
                if (_results.isNotEmpty) {
                  Navigator.of(context).pop(_results.first);
                }
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(L.of(context).nothingFound))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final place = _results[i];
                        return ListTile(
                          leading: const Icon(Icons.location_city),
                          title: Text(place.name),
                          subtitle: Text(
                            '${place.lat.toStringAsFixed(3)}, '
                            '${place.lon.toStringAsFixed(3)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () => Navigator.of(context).pop(place),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L.of(context).cancel),
        ),
      ],
    );
  }
}
