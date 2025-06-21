import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../services/api_service.dart';

class ExploreNotifier extends AsyncNotifier<Map<String, List<GameInstance>>> {
  final ApiService _apiService = ApiService();
  
  // Mutable array of genres
  final List<String> genres = [
    'Adventure',
    'Shooter',
    'MOBA',
    'Sport',
    'Racing',
    'Strategy',
    'Fighting',
    'Puzzle',
    'Platform',
    'Role-playing (RPG)',
  ];

  @override
  Future<Map<String, List<GameInstance>>> build() async {
    return await _fetchAllGenres();
  }

  Future<Map<String, List<GameInstance>>> _fetchAllGenres() async {
    final Map<String, List<GameInstance>> genreData = {};
    
    // Fetch data for each genre
    for (String genre in genres) {
      try {
        final items = await _fetchItems(genre, "total_rating_count");
        genreData[genre] = items;
      } catch (e) {
        // If a genre fails, add empty list to avoid breaking the entire fetch
        genreData[genre] = [];
      }
    }
    
    return genreData;
  }

  Future<List<GameInstance>> _fetchItems(String genre, String sortBy) async {
    final jsonList = await _apiService.fetchGameInstances(genre, sortBy);
    return jsonList.map((json) => GameInstance.fromJson(json)).toList();
  }

  Future<void> refreshItems() async {
    state = const AsyncLoading();
    try {
      final items = await _fetchAllGenres();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Method to add new genre to the list
  void addGenre(String genre) {
    if (!genres.contains(genre)) {
      genres.add(genre);
    }
  }

  // Method to remove genre from the list
  void removeGenre(String genre) {
    genres.remove(genre);
  }

  // Method to get games for a specific genre
  List<GameInstance> getGamesForGenre(String genre) {
    return state.when(
      data: (data) => data[genre] ?? [],
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Method to get all available genres
  List<String> getAvailableGenres() {
    return List.from(genres);
  }
}

final exploreProvider =
    AsyncNotifierProvider<ExploreNotifier, Map<String, List<GameInstance>>>(ExploreNotifier.new);