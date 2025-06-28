import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_list.dart';
import '../models/played_session_list.dart';
import '../providers/game_library_provider.dart';
import '../providers/current_game_provider.dart'; 
import '../widgets/currently_playing_card.dart';
import '../widgets/game_list_modal.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameLists = ref.watch(gameLibraryProvider);
    final currentSession = ref.watch(currentGameProvider);
    final gameLibraryController = ref.read(gameLibraryProvider.notifier);
    final gameSessionController = ref.read(currentGameProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (currentSession != null)
            CurrentlyPlayingCard(
              onMarkCompleted: () {
                gameLibraryController.addToCompleted(currentSession);
                gameSessionController.markCompleted();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marked as Completed!'),
                    backgroundColor: Colors.green,
                  ),
                );
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
                    onLongPress: (gameList is GameList && gameList.isCore) ? null : () => _deletePlaylist(context, ref, gameList),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${gameList.label} (${_getGameCount(gameList)})',
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        if (gameList is PastSessionList && gameList.isCore && gameList.icon != null)
                          Icon(gameList.icon, color: Colors.grey[600], size: 20),
                      ],
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
                            GameList(id: UniqueKey().toString(), label: label, games: []),
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
                          final nameMatch = RegExp(r'"([^"]+)"').firstMatch(sharedText);
                          final listName = nameMatch?.group(1) ?? 'Imported List';

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

  void _deletePlaylist(BuildContext context, WidgetRef ref, dynamic gameList) {
    final label = gameList.label;
    final count = _getGameCount(gameList);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Delete "$label"?', style: TextStyle(color: Colors.red[700])),
          content: Text(
            'All $count games in this list will be permanently removed.',
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
                    content: Text('$label deleted'),
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

  int _getGameCount(dynamic gameList) {
    if (gameList is GameList) return gameList.games.length;
    if (gameList is PastSessionList) return gameList.sessions.length;
    return 0;
  }
}
