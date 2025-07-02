import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_list.dart';
import '../models/past_session_list.dart';
import '../providers/game_library_provider.dart';
import '../providers/current_session_provider.dart';
import '../widgets/currently_playing_card.dart';
import '../widgets/game_list_modal.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreSessionListsAsync = ref.watch(coreSessionListsProvider); // Changed to store AsyncValue
    final nonCoreGameLists = ref.watch(nonCoreGameListsProvider);
    final currentSession = ref.watch(currentSessionProvider);
    final gameLibraryController = ref.read(gameLibraryProvider.notifier);
    final gameSessionController = ref.read(currentSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Library')),
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
              onLogSession: () {
                gameLibraryController.addToCurrentlyPlaying(currentSession);
                gameSessionController.logSession();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session Logged!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

          const SizedBox(height: 4),
          Expanded(
            child: coreSessionListsAsync.when(
              data: (coreSessionLists) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===========================================
                  // CORE LISTS (PastSessionList) SECTION
                  // ===========================================
                  _buildSectionHeader(
                    'Gaming Progress',
                    Icons.games,
                    Colors.purple,
                  ),
                  const SizedBox(height: 8),
                  if (coreSessionLists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No core lists available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...coreSessionLists.map((sessionList) => _buildCoreListTile(
                        context,
                        ref,
                        sessionList,
                        _findListIndex(ref, sessionList),
                      )),

                  const SizedBox(height: 24),

                  // ===========================================
                  // NON-CORE LISTS (GameList) SECTION
                  // ===========================================
                  _buildSectionHeader(
                    'Game Collections',
                    Icons.library_books,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  ...nonCoreGameLists.map((gameList) => _buildNonCoreListTile(
                        context,
                        ref,
                        gameList,
                        _findListIndex(ref, gameList),
                      )),

                  const SizedBox(height: 16),

                  // ===========================================
                  // ADD NEW LIST BUTTON (Only for GameList)
                  // ===========================================
                  ElevatedButton(
                    onPressed: () => _createNewPlaylist(context, ref),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Add New Game Collection',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading lists: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCoreListTile(BuildContext context, WidgetRef ref, PastSessionList sessionList, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            sessionList.icon ?? Icons.gamepad,
            color: Colors.purple,
            size: 28,
          ),
          title: Text(
            sessionList.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${sessionList.sessions.length} sessions',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBottomSheet(context, ref, index),
        ),
      ),
    );
  }

  Widget _buildNonCoreListTile(BuildContext context, WidgetRef ref, GameList gameList, int index) {
    final isWishlist = gameList.id == 'non_core_wishlist';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            isWishlist ? Icons.favorite : Icons.library_books,
            color: isWishlist ? Colors.red : Colors.blue,
            size: 28,
          ),
          title: Text(
            gameList.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${gameList.games.length} games',
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_forward_ios, size: 16),
              if (!gameList.isCore) // Only show delete for non-core lists
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePlaylist(context, ref, gameList),
                ),
            ],
          ),
          onTap: () => _showBottomSheet(context, ref, index),
        ),
      ),
    );
  }

  int _findListIndex(WidgetRef ref, dynamic list) {
    final allLists = ref.read(gameLibraryProvider).value ?? [];
    return allLists.indexWhere((l) => l.id == list.id);
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
              title: const Text('Add New Game Collection'),
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
                    const Text('Create an empty collection and add games later', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Collection name', hintText: 'Enter a name for your collection'),
                      autofocus: true,
                    ),
                  ] else ...[
                    const Text('Import a shared collection (includes name and games)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: importController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(labelText: 'Shared collection data', hintText: 'Paste the shared collection here'),
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
                            SnackBar(content: Text('Created "$label" collection'), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        final sharedText = importController.text.trim();
                        if (sharedText.isEmpty) return;

                        setState(() => isLoading = true);

                        try {
                          final nameMatch = RegExp(r'"([^"]+)"').firstMatch(sharedText);
                          final listName = nameMatch?.group(1) ?? 'Imported Collection';

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
                                content: Text('Failed to import collection'),
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
    final label = gameList.label;
    final count = gameList.games.length;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Delete "$label"?', style: TextStyle(color: Colors.red[700])),
          content: Text(
            'All $count games in this collection will be permanently removed.',
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
}