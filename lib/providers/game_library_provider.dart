import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_list.dart';
import '../models/played_game_list.dart';
import '../models/game_instance.dart';
import '../notifiers/game_library_notifier.dart';

// 🎯 Main game library provider (holds both GameList and PlayedGameList)
final gameLibraryProvider =
    NotifierProvider<GameLibraryNotifier, List<dynamic>>(GameLibraryNotifier.new);

// 🎮 Derived providers for core played lists
final currentlyPlayingListProvider = Provider<PlayedGameList?>((ref) {
  return ref.read(gameLibraryProvider.notifier).currentlyPlayingList;
});

final completedListProvider = Provider<PlayedGameList?>((ref) {
  return ref.read(gameLibraryProvider.notifier).completedList;
});

final wishlistProvider = Provider<GameList?>((ref) {
  return ref.read(gameLibraryProvider.notifier).wishlistList;
});

// 📁 Provider for custom user-created (non-core) GameLists
final customGameListsProvider = Provider<List<GameList>>((ref) {
  final allLists = ref.watch(gameLibraryProvider);
  return allLists
      .whereType<GameList>()
      .where((list) => list.isCore != true)
      .toList();
});

// 📌 Core lists (both GameList and PlayedGameList)
final coreGameListsProvider = Provider<List<dynamic>>((ref) {
  final allLists = ref.watch(gameLibraryProvider);
  return allLists.where((list) => list.isCore == true).toList();
});

// ❓ Check if a game exists in any list
final gameInListProvider = Provider.family<dynamic, GameInstance>((ref, game) {
  final allLists = ref.watch(gameLibraryProvider);

  for (final list in allLists) {
    if (list is GameList && list.games.any((g) => g.id == game.id)) {
      return list;
    }
    if (list is PlayedGameList && list.playedGames.any((pg) => pg.game.id == game.id)) {
      return list;
    }
  }

  return null;
});

// 🔢 Get count of games in a list by ID
final listGamesCountProvider = Provider.family<int, String>((ref, listId) {
  final allLists = ref.watch(gameLibraryProvider);
  final list = allLists.firstWhere((l) => l.id == listId, orElse: () => null);

  if (list is GameList) return list.games.length;
  if (list is PlayedGameList) return list.playedGames.length;
  return 0;
});
