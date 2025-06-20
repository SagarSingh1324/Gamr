import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../services/api_service.dart';

class ExploreNotifier extends AsyncNotifier<List<GameInstance>> {
  final ApiService _apiService = ApiService();

  @override
  Future<List<GameInstance>> build() async {
    return await _fetchItems(); // Initial load
  }

  Future<List<GameInstance>> _fetchItems() async {
    final jsonList = await _apiService.fetchGameInstances();
    return jsonList.map((json) => GameInstance.fromJson(json)).toList();
  }

  Future<void> refreshItems() async {
    state = const AsyncLoading(); // Show loading indicator
    try {
      final items = await _fetchItems();
      state = AsyncData(items);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final exploreProvider =
    AsyncNotifierProvider<ExploreNotifier, List<GameInstance>>(ExploreNotifier.new);
