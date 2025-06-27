import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../notifiers/game_library_notifier.dart';
import '../widgets/game_card_small.dart';
import '../widgets/currently_playing_card.dart';
import 'package:share_plus/share_plus.dart';

final GameInstance currentGame = GameInstance(
  id: 139090,
  name: "Inscryption",
  cover: Cover(
    id: 186672,
    url: "//images.igdb.com/igdb/image/upload/t_thumb/co401c.jpg",
  ),
  summary: "Inscryption is an inky black card-based odyssey that blends the deckbuilding roguelike, escape-room style puzzles, and psychological horror into a blood-laced smoothie. Darker still are the secrets inscrybed upon the cards...",
  genres: [
    Genre(id: 9, name: "Puzzle"),
    Genre(id: 15, name: "Strategy"),
    Genre(id: 31, name: "Adventure"),
    Genre(id: 32, name: "Indie"),
    Genre(id: 35, name: "Card & Board Game"),
  ],
);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameLists = ref.watch(gameLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CurrentlyPlayingCard(
            game: currentGame,
            startDate: DateTime(2025, 1, 1), 
            progress: 0.7,
            onMarkCompleted: () {
              //logic here
            },
          ),
          const SizedBox(height: 4),
          Expanded( 
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: gameLists.length + 1,
              itemBuilder: (context, index) {
                if (index == gameLists.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ElevatedButton(
                      onPressed: () => _createNewPlaylist(context, ref),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Add New List',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  );
                }

                final gameList = gameLists[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton(
                    onPressed: () => _showBottomSheet(context, ref, index),
                    onLongPress: () => _deletePlaylist(context, ref, gameList),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      '${gameList.label} (${gameList.games.length})',
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context, WidgetRef ref, int listIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GameListModal(listIndex: listIndex),
    );
  }

  void _createNewPlaylist(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final importController = TextEditingController();
    bool isImportMode = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New List'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => setState(() => isImportMode = false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isImportMode ? Colors.blue : Colors.grey.shade300,
                            foregroundColor: !isImportMode ? Colors.white : Colors.black,
                          ),
                          child: const Text('Empty List'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => setState(() => isImportMode = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isImportMode ? Colors.green : Colors.grey.shade300,
                            foregroundColor: isImportMode ? Colors.white : Colors.black,
                          ),
                          child: const Text('Import List'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isImportMode) ...[
                    const Text('Create an empty list and add games later', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'List name', hintText: 'Enter a name for your list'),
                      autofocus: true,
                    ),
                  ] else ...[
                    const Text('Import a shared list (includes list name and games)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: importController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Shared list data', hintText: 'Paste the shared list here'),
                      maxLines: 3,
                      autofocus: true,
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Fetching games...', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                if (!isLoading)
                  TextButton(
                    child: Text(isImportMode ? 'Import' : 'Create'),
                    onPressed: () async {
                      if (!isImportMode) {
                        final label = nameController.text.trim();
                        if (label.isNotEmpty) {
                          ref.read(gameLibraryProvider.notifier).addList(
                            GameList(label: label, games: []),
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Created "$label" list'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        final sharedText = importController.text.trim();
                        if (sharedText.isEmpty) return;

                        setState(() => isLoading = true);

                        try {
                          // Extract list name
                          final nameMatch = RegExp(r'"([^"]+)"').firstMatch(sharedText);
                          final listName = nameMatch?.group(1) ?? 'Imported List';

                          // Extract game IDs
                          final match = RegExp(r'\[([0-9,\s]+)\]').firstMatch(sharedText);
                          List<int> idList = [];
                          if (match != null) {
                            final innerText = match.group(1)!;
                            idList = innerText
                                .split(',')
                                .map((e) => int.tryParse(e.trim()))
                                .whereType<int>()
                                .toList();
                          }

                          // Use notifier method
                          await ref.read(gameLibraryProvider.notifier)
                              .importGamesFromIdList(listName, idList);

                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Imported "$listName" with ${idList.length} games'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            setState(() => isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to import list'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _deletePlaylist(BuildContext context, WidgetRef ref, GameList gameList) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Delete "${gameList.label}"?', style: TextStyle(color: Colors.red[700])),
          content: Text(
            'All ${gameList.games.length} games in this list will be permanently removed.',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red[50],
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('DELETE'),
              onPressed: () {
                ref.read(gameLibraryProvider.notifier).removeList(gameList);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${gameList.label} deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class GameListModal extends ConsumerWidget {
  final int listIndex;
  const GameListModal({super.key, required this.listIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameLists = ref.watch(gameLibraryProvider);
    final gameList = gameLists[listIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.9,
      width: double.infinity,
      child: Column(
        children: [
          // Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    gameList.label,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () =>_handleShare(context, ref),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Game List
          Expanded(
            child: ListView.builder(
              itemCount: gameList.games.length,
              itemBuilder: (context, index) {
                final game = gameList.games[index];

                return GestureDetector(
                  onLongPress: () => _deleteGameFromList(context, ref, listIndex, game),
                  child: GameInstanceCardSmall(item: game),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleShare(BuildContext context, WidgetRef ref){
    final gameLists = ref.read(gameLibraryProvider);
    final gameList = gameLists[listIndex];
    // Extract game IDs as plain text
    final gameIdsText = gameList.games
        .map((game) => game.id.toString())
        .join(',');
    // Compose and share the message
    SharePlus.instance.share(
      ShareParams(text:'Game IDs in "${gameList.label}":\n[$gameIdsText]',
      subject: 'Game IDs from ${gameList.label}',
      )
    );
  }

  void _deleteGameFromList(BuildContext context, WidgetRef ref, int listIndex, GameInstance game) {
    final gameLists = ref.watch(gameLibraryProvider);
    final gameList = gameLists[listIndex];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Delete "${game.name}"?', style: TextStyle(color: Colors.red[700])),
          content: Text(
            '${game.name} will be removed from list.',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red[50],
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('DELETE'),
              onPressed: () {
                final updatedGames = List<GameInstance>.from(gameList.games)..remove(game);
                final updatedList = GameList(
                  label: gameList.label,
                  games: updatedGames,
                );

                ref.read(gameLibraryProvider.notifier).updateList(listIndex, updatedList);
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${game.name} removed'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}