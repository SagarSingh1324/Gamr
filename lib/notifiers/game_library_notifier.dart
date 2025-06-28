import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../models/played_game.dart';
import '../models/played_game_list.dart';
import '../models/current_game_session.dart';
import '../providers/api_service_provider.dart';

class GameLibraryNotifier extends Notifier<List<dynamic>> {
  static const String currentlyPlayingId = 'core_currently_playing';
  static const String completedId = 'core_completed';
  static const String wishlistId = 'core_wishlist';

  @override
  List<dynamic> build() {
    _loadFromPrefs();
    return [];
  }

  void _initializeCorePlaylist() {
    final hasCurrentlyPlaying = state.any((list) => list is PlayedGameList && list.id == currentlyPlayingId);
    final hasCompleted = state.any((list) => list is PlayedGameList && list.id == completedId);
    final hasWishlist = state.any((list) => list is GameList && list.id == wishlistId);

    final List<dynamic> newLists = [];

    if (!hasCurrentlyPlaying) {
      newLists.add(PlayedGameList(
        id: currentlyPlayingId,
        label: 'Currently Playing',
        playedGames: [],
        isCore: true,
        icon: Icons.play_arrow,
      ));
    }

    if (!hasCompleted) {
      newLists.add(PlayedGameList(
        id: completedId,
        label: 'Completed',
        playedGames: [],
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
      state = [...newLists, ...state];
      _saveToPrefs();
    }
  }

  void addList(dynamic list) {
    state = [...state, list];
    _saveToPrefs();
  }

  void removeList(dynamic list) {
    if (list.isCore == true) return;
    state = state.where((l) => l != list).toList();
    _saveToPrefs();
  }

  void updateList(int index, dynamic newList) {
    final newState = [...state];
    newState[index] = newList;
    state = newState;
    _saveToPrefs();
  }

  // ---------------------
  // 🎮 Core operations
  // ---------------------

  void addToCurrentlyPlaying(CurrentGameSession session) {
    final playedGame = PlayedGame(
      game: session.game,
      startedAt: session.startTime ?? DateTime.now(),
      completedAt: DateTime.fromMillisecondsSinceEpoch(0),
      totalPlayTime: session.elapsed,
    );
    _addPlayedGameToCorePlaylist(currentlyPlayingId, playedGame);
  }

  void addToCompleted(CurrentGameSession session) {
    _removePlayedGameFromCorePlaylist(currentlyPlayingId, session.game);

    final playedGame = PlayedGame(
      game: session.game,
      startedAt: session.startTime ?? DateTime.now(),
      completedAt: DateTime.now(),
      totalPlayTime: session.elapsed,
    );
    _addPlayedGameToCorePlaylist(completedId, playedGame);
  }

  void _addPlayedGameToCorePlaylist(String playlistId, PlayedGame game) {
    final newState = [...state];
    final index = newState.indexWhere((list) => list is PlayedGameList && list.id == playlistId);
    if (index != -1) {
      final playlist = newState[index] as PlayedGameList;
      if (!playlist.playedGames.any((g) => g.game.id == game.game.id)) {
        final updatedGames = [...playlist.playedGames, game];
        final updatedList = playlist.copyWith(playedGames: updatedGames);
        newState[index] = updatedList;
        state = newState;
        _saveToPrefs();
      }
    }
  }
  
  void _removePlayedGameFromCorePlaylist(String playlistId, GameInstance game) {
    final newState = [...state];
    final index = newState.indexWhere(
      (list) => list is PlayedGameList && list.id == playlistId,
    );

    if (index != -1) {
      final playlist = newState[index] as PlayedGameList;

      final updatedGames = playlist.playedGames
          .where((g) => g.game.id != game.id)
          .toList();

      final updatedList = playlist.copyWith(playedGames: updatedGames);
      newState[index] = updatedList;

      state = newState;
      _saveToPrefs();
    }
  }
  // ---------------------
  // 💾 Persistence
  // ---------------------

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
      state = decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        final id = map['id'];
        final type = map['type']; // must be set during serialization

        if (type == 'played' || id == currentlyPlayingId || id == completedId) {
          return PlayedGameList.fromJson(map);
        } else {
          return GameList.fromJson(map);
        }
      }).toList();
    }

    _initializeCorePlaylist();
  }

  // ---------------------
  // 🛠 Helpers
  // ---------------------

  PlayedGameList? get currentlyPlayingList {
    try {
      return state.firstWhere((list) => list is PlayedGameList && list.id == currentlyPlayingId) as PlayedGameList;
    } catch (_) {
      return null;
    }
  }

  PlayedGameList? get completedList {
    try {
      return state.firstWhere((list) => list is PlayedGameList && list.id == completedId) as PlayedGameList;
    } catch (_) {
      return null;
    }
  }

  GameList? get wishlistList {
    try {
      return state.firstWhere((list) => list is GameList && list.id == wishlistId) as GameList;
    } catch (_) {
      return null;
    }
  }

  Future<void> importGamesFromIdList(String listName, List<int> ids) async {
    final List<GameInstance> games = [];
    for (final id in ids) {
      try {
        final responseList = await ref.read(apiServiceProvider).fetchGameById(id);
        if (responseList.isNotEmpty) {
          final game = GameInstance.fromJson(responseList.first);
          games.add(game);
        }
      } catch (e) {
        // Handle fetch error
      }
    }

    final newGameList = GameList(
      id: UniqueKey().toString(),
      label: listName,
      games: games,
    );
    state = [...state, newGameList];
    _saveToPrefs();
  }
}
