import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../models/game_pop.dart';
import '../providers/api_service_provider.dart';

class HomeNotifier extends AsyncNotifier<Map<String, List<GameInstance>>> {
  final List<int> popTypes = [1, 2, 3, 4, 5, 6, 7, 8];

  String getPopularityName(int id) {
    switch (id) {
      case 1: return 'Visits';
      case 2: return 'Want to Play';
      case 3: return 'Playing';
      case 4: return 'Played';
      case 5: return '24hr Peak Players';
      case 6: return 'Positive Reviews';
      case 7: return 'Negative Reviews';
      case 8: return 'Total Reviews';
      default: return 'Unknown';
    }
  }

  List<String> getAvailableCategories() => [
        'Visits',
        'Want to Play',
        'Playing',
        'Played',
        '24hr Peak Players',
        'Positive Reviews',
        'Negative Reviews',
        'Total Reviews',
      ];

  @override
  Future<Map<String, List<GameInstance>>> build() async {
    state = const AsyncData({});
    await fetchPopTypesIncrementally();
    return state.asData?.value ?? {};
  }

  Future<void> fetchPopTypesIncrementally() async {
    Map<String, List<GameInstance>> popData = state.asData?.value ?? {};

    for (int popType in popTypes) {
      try {
        final gamePopList = await _fetchGamePopItems(popType);
        final fullGames = await _fetchGameDataForItems(gamePopList);

        popData = {
          ...popData,
          popType.toString(): fullGames,
        };
      } catch (e) {
        popData = {
          ...popData,
          popType.toString(): [],
        };
      }

      state = AsyncData(popData);
    }
  }

  Future<List<GamePop>> _fetchGamePopItems(int popType) async {
    final jsonList = await ref.read(apiServiceProvider).fetchGameByPop(popType);
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map((json) => GamePop.fromJson(json))
        .toList();
  }

  Future<List<GameInstance>> _fetchGameDataForItems(List<GamePop> items) async {
    List<GameInstance> updatedItems = [];

    for (GamePop item in items) {
      try {
        final gameDataList = await ref.read(apiServiceProvider).fetchGameById(item.gameId);

        if (gameDataList.isNotEmpty) {
          final gameData = gameDataList.first as Map<String, dynamic>;
          final updatedItem = GameInstance.fromJson(gameData);
          updatedItems.add(updatedItem);
        }
      } catch (e) {
        // skip failed item
      }
    }

    return updatedItems;
  }

  Future<void> refreshItems() async {
    state = const AsyncLoading();
    try {
      await fetchPopTypesIncrementally();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<GameInstance>> fetchByName(String query) async {
    final jsonList = await ref.read(apiServiceProvider).fetchGameByName(query);
    return jsonList.map((json) => GameInstance.fromJson(json)).toList();
  }

  List<GameInstance> getGamesForPopType(int popType) {
    return state.when(
      data: (data) => data[popType.toString()] ?? [],
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Future<GameInstance?> fetchGameDataById(int id) async {
    try {
      final gameDataList = await ref.read(apiServiceProvider).fetchGameById(id);
      if (gameDataList.isNotEmpty) {
        final gameData = gameDataList.first as Map<String, dynamic>;
        return GameInstance.fromJson(gameData);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
