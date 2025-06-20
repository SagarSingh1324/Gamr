import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/game_list.dart';

class GameLibraryNotifier extends Notifier<List<GameList>> {
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
}

// Global provider
final gameLibraryProvider =
    NotifierProvider<GameLibraryNotifier, List<GameList>>(GameLibraryNotifier.new);
