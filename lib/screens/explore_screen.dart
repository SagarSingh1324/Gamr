import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../models/game_list.dart';
import '../notifiers/explore_notifier.dart';
import '../notifiers/game_library_notifier.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exploreAsync = ref.watch(exploreProvider);
    final exploreNotifier = ref.read(exploreProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => exploreNotifier.refreshItems(),
          ),
        ],
      ),
      body: exploreAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading explore items...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => exploreNotifier.refreshItems(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (genreMap) {
          if (genreMap.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final availableGenres = exploreNotifier.getAvailableGenres();

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              ...availableGenres.map((genre) {
                final gamesForGenre = genreMap[genre] ?? [];
                
                if (gamesForGenre.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHorizontalList(context, ref, genre, gamesForGenre),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, WidgetRef ref, String title, List<GameInstance> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildGameInstanceCard(context, ref, items[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameInstanceCard(BuildContext context, WidgetRef ref, GameInstance item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            // Top Image (Fixed Height)
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
            // Info Section (Natural Height)
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                  Text(
                    'ID: ${item.id}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () => _showItemDetails(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addToLibrary(context, ref, item),
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

  void _showItemDetails(BuildContext context, GameInstance item) {
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
            Text('Summary: ${item.summary}'),
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

  void _addToLibrary(BuildContext context, WidgetRef ref, GameInstance game) {
    final gameLists = ref.read(gameLibraryProvider);
    final selectedLists = <String>{}; 

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
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
                        // Avoid duplicates
                        if (!updatedGames.any((g) => g.id == game.id)) {
                          updatedGames.add(game);
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
        );
      },
    );
  }
}
