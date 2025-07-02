import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../providers/api_service_provider.dart';

class ExploreNotifier extends AsyncNotifier<Map<String, List<GameInstance>>> {
  // Mutable array of genres
  final List<String> genres = [
    "Adventure",
    "Arcade",
    "Card & Board Game",
    "Fighting",
    "Hack and slash/Beat 'em up",
    "Indie",
    "MOBA",
    "Music",
    "Pinball",
    "Platform",
    "Point-and-click",
    "Puzzle",
    "Quiz/Trivia",
    "Racing",
    "Real Time Strategy (RTS)",
    "Role-playing (RPG)",
    "Shooter",
    "Simulator",
    "Sport",
    "Strategy",
    "Tactical",
    "Turn-based strategy (TBS)",
    "Visual Novel"
  ];

  @override
  Future<Map<String, List<GameInstance>>> build() async {
    // Start with an empty map
    state = const AsyncData({});
    // Fetch genres one-by-one
    await fetchGenresIncrementally();
    // Return final state map (just for the method signature)
    return state.asData?.value ?? {};
  }

  Future<void> fetchGenresIncrementally() async {
    // Get current state or start with empty map
    Map<String, List<GameInstance>> genreData = state.asData?.value ?? {};
    
    for (String genre in genres) {
      try {
        final items = await _fetchItems(genre, "total_rating_count");
        genreData = {
          ...genreData,
          genre: items,
        };
      } catch (e) {
        genreData = {
          ...genreData,
          genre: [],
        };
      }
      // Update state after each genre fetch
      state = AsyncData(genreData);
    }
  }

  Future<List<GameInstance>> _fetchItems(String genre, String sortBy) async {
    final jsonList = await ref.read(apiServiceProvider).fetchGameInstances(genre, sortBy);
    return jsonList.map((json) => GameInstance.fromJson(json)).toList();
  }

  Future<void> refreshItems() async {
    state = const AsyncLoading();
    try {
      await fetchGenresIncrementally();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  //Fetch games by search query
  Future<List<GameInstance>> fetchByName(String query) async {
    final jsonList = await ref.read(apiServiceProvider).fetchGameByName(query);
    return jsonList.map((json) => GameInstance.fromJson(json)).toList();
  }

  // Optional: Add genre
  void addGenre(String genre) {
    if (!genres.contains(genre)) {
      genres.add(genre);
    }
  }

  // Optional: Remove genre
  void removeGenre(String genre) {
    genres.remove(genre);
  }

  List<GameInstance> getGamesForGenre(String genre) {
    return state.when(
      data: (data) => data[genre] ?? [],
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<String> getAvailableGenres() {
    return List.from(genres);
  }
}