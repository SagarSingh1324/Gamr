import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../notifiers/explore_notifier.dart';

// Main explore provider
final exploreProvider =
    AsyncNotifierProvider<ExploreNotifier, Map<String, List<GameInstance>>>(
        ExploreNotifier.new);

// Derived providers for easier UI consumption
final availableGenresProvider = Provider<List<String>>((ref) {
  return ref.read(exploreProvider.notifier).getAvailableGenres();
});

final gamesForGenreProvider = Provider.family<List<GameInstance>, String>((ref, genre) {
  return ref.read(exploreProvider.notifier).getGamesForGenre(genre);
});

// Provider for search functionality
final searchResultsProvider = FutureProvider.family<List<GameInstance>, String>((ref, query) {
  return ref.read(exploreProvider.notifier).fetchByName(query);
});