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
        data: (items) {
          if (items.isEmpty) {
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

          return RefreshIndicator(
            onRefresh: () => exploreNotifier.refreshItems(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) => _buildGameInstanceCard(context, ref, items[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameInstanceCard(BuildContext context, WidgetRef ref, GameInstance item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            item.id.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text('ID: ${item.id}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showItemDetails(context, item),
        onLongPress: () => _addToLibrary(context, ref, item),
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
