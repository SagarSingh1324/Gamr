import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamr/models/game_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_list.dart';
import '../services/api_service.dart';

class GameLibraryNotifier extends Notifier<List<GameList>> {
  final ApiService _apiService = ApiService();

  @override
  List<GameList> build() {
    _loadFromPrefs();
    return [];
  }

  void addList(GameList list) {
    state = [...state, list];
    _saveToPrefs();
  }

  void removeList(GameList list) {
    state = state.where((l) => l != list).toList();
    _saveToPrefs();
  }

  void updateList(int index, GameList newList) {
    final newState = [...state];
    newState[index] = newList;
    state = newState;
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString('game_lists', jsonData);
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('game_lists');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      state = decoded.map((e) => GameList.fromJson(e)).toList();
    }
  }

  Future<void> importGamesFromIdList(String listName, List<int> ids) async {

    final List<GameInstance> games = [];

    for (final id in ids) {
      try {
        final responseList = await _apiService.fetchGameById(id); 
        if (responseList.isNotEmpty) {
          final game = GameInstance.fromJson(responseList.first); 
          games.add(game);
        }
      } catch (e) {
        // Handle fetch error if needed
      }
    }

    final newGameList = GameList(label: listName, games: games);
    state = [...state, newGameList];
    _saveToPrefs();
  }
}

// Global provider
final gameLibraryProvider =
    NotifierProvider<GameLibraryNotifier, List<GameList>>(GameLibraryNotifier.new);
