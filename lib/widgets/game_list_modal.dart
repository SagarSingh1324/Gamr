import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../models/past_session_list.dart';
import '../providers/game_library_provider.dart';
import '../widgets/game_card_small.dart';
import '../widgets/past_session_card.dart';
import 'package:share_plus/share_plus.dart';
import '../models/past_session.dart';

class GameListModal extends ConsumerWidget {
  final int listIndex;
  const GameListModal({super.key, required this.listIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameListsAsync = ref.watch(gameLibraryProvider);

    return gameListsAsync.when(
      data: (gameLists) {
        // Check if the list index is valid
        if (listIndex >= gameLists.length) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.9,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'List not found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }

        final gameList = gameLists[listIndex];
        final items = _getItems(gameList);

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
                    children: [
                      Text(
                        gameList.label,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _handleShare(context, gameList),
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
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.games,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No games in this list',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return GestureDetector(
                            onLongPress: () => _deleteGameFromList(context, ref, gameList, listIndex, item),
                            child: item is PastSession
                                ? PastSessionCard(
                                    session: item,
                                    onRemove: () => _deleteGameFromList(context, ref, gameList, listIndex, item),
                                  )
                                : GameInstanceCardSmall(
                                    item: item as GameInstance,
                                  ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.9,
        width: double.infinity,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading game lists...'),
          ],
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.9,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading game lists',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleShare(BuildContext context, dynamic gameList) {
    final items = _getItems(gameList);

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No games to share'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final gameIds = items.map((item) {
      final game = item is PastSession ? item.game : item;
      return game.id.toString();
    }).join(',');

    final text = 'Game IDs in "${gameList.label}":\n[$gameIds]';

    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Game List: ${gameList.label}',
      ),
    );
  }

  void _deleteGameFromList(BuildContext context, WidgetRef ref, dynamic gameList, int listIndex, dynamic item) {
    final game = item is PastSession ? item.game : item;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${game.name}"?', style: TextStyle(color: Colors.red[700])),
        content: Text('${game.name} will be removed from the list.'),
        backgroundColor: Colors.red[50],
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red, 
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
            onPressed: () {
              try {
                if (gameList is GameList) {
                  final updatedGames = List<GameInstance>.from(gameList.games)..remove(game);
                  final updatedList = gameList.copyWith(games: updatedGames);
                  ref.read(gameLibraryProvider.notifier).updateList(listIndex, updatedList);
                } else if (gameList is PastSessionList) {
                  final updatedSessions = List<PastSession>.from(gameList.sessions)
                    ..removeWhere((ps) => ps.game.id == game.id);
                  final updatedList = gameList.copyWith(sessions: updatedSessions);
                  ref.read(gameLibraryProvider.notifier).updateList(listIndex, updatedList);
                }

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${game.name} removed'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error removing ${game.name}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Returns a list of GameInstance or PastSession from either list type
  List<dynamic> _getItems(dynamic gameList) {
    if (gameList is GameList) return gameList.games;
    if (gameList is PastSessionList) return gameList.sessions;
    return [];
  }
}