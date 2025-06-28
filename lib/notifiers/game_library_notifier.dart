import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../services/api_service.dart';

class GameLibraryNotifier extends Notifier<List<GameList>> {
  final ApiService _apiService = ApiService();
  
  // Core playlist constants
  static const String currentlyPlayingId = 'core_currently_playing';
  static const String completedId = 'core_completed';
  static const String wishlistId = 'core_wishlist';
  
  @override
  List<GameList> build() {
    _loadFromPrefs();
    return [];
  }
  
  void _initializeCorePlaylist() {
    // Check if core playlists exist, if not create them
    final hasCurrentlyPlaying = state.any((list) => list.id == currentlyPlayingId);
    final hasCompleted = state.any((list) => list.id == completedId);
    final hasWishlist = state.any((list) => list.id == wishlistId);
    
    List<GameList> newLists = [];
    
    if (!hasCurrentlyPlaying) {
      newLists.add(GameList(
        id: currentlyPlayingId,
        label: 'Currently Playing',
        games: [],
        isCore: true,
        icon: Icons.play_arrow,
      ));
    }
    
    if (!hasCompleted) {
      newLists.add(GameList(
        id: completedId,
        label: 'Completed',
        games: [],
        isCore: true,
        icon: Icons.check_circle,
      ));
    }
    
    if (!hasWishlist) {
      newLists.add(GameList(
        id: wishlistId,
        label: 'Wishlist',
        games: [],
        isCore: true,
        icon: Icons.favorite,
      ));
    }
    
    if (newLists.isNotEmpty) {
      // Add core playlists at the beginning
      state = [...newLists, ...state];
      _saveToPrefs();
    }
  }
  
  void addList(GameList list) {
    state = [...state, list];
    _saveToPrefs();
  }
  
  void removeList(GameList list) {
    // Prevent removal of core playlists
    if (list.isCore == true) {
      return; // Or throw an exception/show error
    }
    state = state.where((l) => l != list).toList();
    _saveToPrefs();
  }
  
  void updateList(int index, GameList newList) {
    final newState = [...state];
    newState[index] = newList;
    state = newState;
    _saveToPrefs();
  }
  
  // Helper methods for core playlist operations
  void addToCurrentlyPlaying(GameInstance game) {
    _addGameToCorePlaylist(currentlyPlayingId, game);
  }
  
  void addToCompleted(GameInstance game) {
    // Remove from currently playing if it exists there
    _removeGameFromCorePlaylist(currentlyPlayingId, game);
    // Add to completed
    _addGameToCorePlaylist(completedId, game);
  }
  
  void addToWishlist(GameInstance game) {
    _addGameToCorePlaylist(wishlistId, game);
  }
  
  void _addGameToCorePlaylist(String playlistId, GameInstance game) {
    final newState = [...state];
    final playlistIndex = newState.indexWhere((list) => list.id == playlistId);
    
    if (playlistIndex != -1) {
      final playlist = newState[playlistIndex];
      // Check if game already exists
      if (!playlist.games.any((g) => g.id == game.id)) {
        final updatedGames = [...playlist.games, game];
        newState[playlistIndex] = playlist.copyWith(games: updatedGames);
        state = newState;
        _saveToPrefs();
      }
    }
  }
  
  void _removeGameFromCorePlaylist(String playlistId, GameInstance game) {
    final newState = [...state];
    final playlistIndex = newState.indexWhere((list) => list.id == playlistId);
    
    if (playlistIndex != -1) {
      final playlist = newState[playlistIndex];
      final updatedGames = playlist.games.where((g) => g.id != game.id).toList();
      newState[playlistIndex] = playlist.copyWith(games: updatedGames);
      state = newState;
      _saveToPrefs();
    }
  }
  
  // Getters for core playlists
  GameList? get currentlyPlayingList {
    try {
      return state.firstWhere((list) => list.id == currentlyPlayingId);
    } catch (e) {
      return null;
    }
  }
  
  GameList? get completedList {
    try {
      return state.firstWhere((list) => list.id == completedId);
    } catch (e) {
      return null;
    }
  }
  
  GameList? get wishlistList {
    try {
      return state.firstWhere((list) => list.id == wishlistId);
    } catch (e) {
      return null;
    }
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
    // Always ensure core playlists exist after loading
    _initializeCorePlaylist();
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
    final newGameList = GameList(id: UniqueKey().toString(), label: listName, games: games);
    state = [...state, newGameList];
    _saveToPrefs();
  }
}

// Global provider
final gameLibraryProvider =
    NotifierProvider<GameLibraryNotifier, List<GameList>>(GameLibraryNotifier.new);