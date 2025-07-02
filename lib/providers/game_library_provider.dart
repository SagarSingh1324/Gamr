import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_list.dart';
import '../models/past_session_list.dart';
import '../models/game_instance.dart';
import '../notifiers/game_library_notifier.dart';

// ===========================================
// MAIN PROVIDER
// ===========================================
final gameLibraryProvider =
    AsyncNotifierProvider<GameLibraryNotifier, List<dynamic>>(GameLibraryNotifier.new);

// ===========================================
// CORE LISTS (PastSessionList) - PROVIDERS
// ===========================================

// Currently Playing list provider
final currentlyPlayingListProvider = Provider<PastSessionList>((ref) {
  return ref.read(gameLibraryProvider.notifier).currentlyPlayingList;
});

// Completed list provider
final completedListProvider = Provider<PastSessionList>((ref) {
  return ref.read(gameLibraryProvider.notifier).completedList;
});

// All core lists (PastSessionList) provider
final coreSessionListsProvider = Provider<AsyncValue<List<PastSessionList>>>((ref) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  return allListsAsync.when(
    data: (lists) => AsyncValue.data(lists.whereType<PastSessionList>().toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// ===========================================
// NON-CORE LISTS (GameList) - PROVIDERS
// ===========================================

// Wishlist provider
final wishlistProvider = Provider<GameList?>((ref) {
  return ref.read(gameLibraryProvider.notifier).wishlist;
});

// User-created (non-core) GameLists provider
final customGameListsProvider = Provider<List<GameList>>((ref) {
  return ref.read(gameLibraryProvider.notifier).nonCoreLists;
});

// All non-core lists (GameList) including wishlist
final nonCoreGameListsProvider = Provider<List<GameList>>((ref) {
  final allListsAsync = ref.watch(gameLibraryProvider);

  return allListsAsync.when(
    data: (lists) => lists.whereType<GameList>().toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// ===========================================
// COMBINED PROVIDERS
// ===========================================

// All core lists (both PastSessionList and default GameList like wishlist)
final allCoreListsProvider = Provider<List<dynamic>>((ref) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  return (allListsAsync.value ?? [])
      .where((list) => list.isCore == true)
      .toList();
});


// All lists separated by type
final gameListsByTypeProvider = Provider<Map<String, List<dynamic>>>((ref) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  final lists = allListsAsync.value ?? [];

  return {
    'coreSessions': lists.whereType<PastSessionList>().toList(),
    'gameCollections': lists.whereType<GameList>().toList(),
  };
});

// ===========================================
// UTILITY PROVIDERS
// ===========================================

// Check if a game exists in any list
final gameInListProvider = Provider.family<dynamic, GameInstance>((ref, game) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  final allLists = allListsAsync.value ?? [];

  for (final list in allLists) {
    if (list is GameList && list.games.any((g) => g.id == game.id)) {
      return list;
    }
    if (list is PastSessionList && list.sessions.any((ps) => ps.game.id == game.id)) {
      return list;
    }
  }

  return null;
});

// Get count of games in a list by ID
final listGamesCountProvider = Provider.family<int, String>((ref, listId) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  final allLists = allListsAsync.value ?? [];

  final list = allLists.firstWhere(
    (l) => l.id == listId,
    orElse: () => null,
  );

  if (list is GameList) return list.games.length;
  if (list is PastSessionList) return list.sessions.length;
  return 0;
});

// Get a specific list by ID
final listByIdProvider = Provider.family<dynamic, String>((ref, listId) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  final allLists = allListsAsync.value ?? [];

  return allLists.firstWhere(
    (l) => l.id == listId,
    orElse: () => null,
  );
});

// Check if a list is a core list
final isListCoreProvider = Provider.family<bool, String>((ref, listId) {
  final list = ref.watch(listByIdProvider(listId));
  return list?.isCore == true;
});

// Get all user-created lists (excludes all core lists)
final userCreatedListsProvider = Provider<List<GameList>>((ref) {
  final allListsAsync = ref.watch(gameLibraryProvider);
  final allLists = allListsAsync.value ?? [];

  return allLists
      .whereType<GameList>()
      .where((list) => list.isCore != true)
      .toList();
});
