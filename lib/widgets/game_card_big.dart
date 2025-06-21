import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../models/game_list.dart';
import '../notifiers/game_library_notifier.dart';

class GameInstanceCardBig extends StatelessWidget {
  final GameInstance item;
  final WidgetRef ref;

  const GameInstanceCardBig({
    super.key,
    required this.item,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                'https:${item.cover.url.replaceFirst('t_thumb', 't_720p')}',
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 170,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 170,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
            // Info Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showItemDetails(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addToLibrary(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${item.id}'),
            const SizedBox(height: 8),
            Text('Name: ${item.name}'),
            const SizedBox(height: 8),
            Text('Genres: ${item.genres.isNotEmpty 
                ? item.genres.map((genre) => genre.name).join(', ')
                : 'No genres available'}'),
            const SizedBox(height: 8),
            Text(
              'Summary: ${item.summary}',
              maxLines: 20,
              overflow: TextOverflow.ellipsis, 
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _addToLibrary(BuildContext context) {
    final gameLists = ref.read(gameLibraryProvider);
    final selectedLists = <String>{};

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add to your library:'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: gameLists.map((list) {
                  final isSelected = selectedLists.contains(list.label);
                  return CheckboxListTile(
                    title: Text(list.label),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selectedLists.add(list.label);
                        } else {
                          selectedLists.remove(list.label);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(gameLibraryProvider.notifier);
                  for (var list in gameLists) {
                    if (selectedLists.contains(list.label)) {
                      final updatedGames = List<GameInstance>.from(list.games);
                      if (!updatedGames.any((g) => g.id == item.id)) {
                        updatedGames.add(item);
                        final updatedList = GameList(label: list.label, games: updatedGames);
                        final index = gameLists.indexOf(list);
                        notifier.updateList(index, updatedList);
                      }
                    }
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
