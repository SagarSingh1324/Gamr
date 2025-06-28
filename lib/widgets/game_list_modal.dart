import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../models/played_session_list.dart';
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
    final gameLists = ref.watch(gameLibraryProvider);
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
            child: ListView.builder(
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
  }
  
  void _handleShare(BuildContext context, dynamic gameList) {
    final items = _getItems(gameList);

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
            style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
            onPressed: () {
              if (gameList is GameList) {
                final updatedGames = List<GameInstance>.from(gameList.games)..remove(game);
                final updatedList = gameList.copyWith(games: updatedGames);
                ref.read(gameLibraryProvider.notifier).updateList(listIndex, updatedList);
              } else if (gameList is PastSessionList) {
                final updatedGames = List<PastSession>.from(gameList.sessions)
                  ..removeWhere((ps) => ps.game.id == game.id);
                final updatedList = gameList.copyWith(sessions: updatedGames);
                ref.read(gameLibraryProvider.notifier).updateList(listIndex, updatedList);
              }

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
      ),
    );
  }

  /// Returns a list of GameInstance or PlayedGame from either list type
  List<dynamic> _getItems(dynamic gameList) {
    if (gameList is GameList) return gameList.games;
    if (gameList is PastSessionList) return gameList.sessions;
    return [];
  }
}