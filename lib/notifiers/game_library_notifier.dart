import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../models/past_session.dart';
import '../models/played_session_list.dart';
import '../models/current_session.dart';
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
    final hasCurrentlyPlaying = state.any((list) => list is PastSessionList && list.id == currentlyPlayingId);
    final hasCompleted = state.any((list) => list is PastSessionList && list.id == completedId);
    final hasWishlist = state.any((list) => list is GameList && list.id == wishlistId);

    final List<dynamic> newLists = [];

    if (!hasCurrentlyPlaying) {
      newLists.add(PastSessionList(
        id: currentlyPlayingId,
        label: 'Currently Playing',
        sessions: [],
        isCore: true,
        icon: Icons.play_arrow,
      ));
    }

    if (!hasCompleted) {
      newLists.add(PastSessionList(
        id: completedId,
        label: 'Completed',
        sessions: [],
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

  void addToCurrentlyPlaying(CurrentSession session) {
    final playedGame = PastSession(
      game: session.game,
      startedAt: session.startTime ?? DateTime.now(),
      completedAt: DateTime.fromMillisecondsSinceEpoch(0),
      totalPlayTime: session.elapsed,
    );
    _addPlayedGameToCorePlaylist(currentlyPlayingId, playedGame);
  }

  void addToCompleted(CurrentSession session) {
    _removePlayedGameFromCorePlaylist(currentlyPlayingId, session.game);

    final playedGame = PastSession(
      game: session.game,
      startedAt: session.startTime ?? DateTime.now(),
      completedAt: DateTime.now(),
      totalPlayTime: session.elapsed,
    );
    _addPlayedGameToCorePlaylist(completedId, playedGame);
  }

  void _addPlayedGameToCorePlaylist(String playlistId, PastSession session) {
    final newState = [...state];
    final index = newState.indexWhere((list) => list is PastSessionList && list.id == playlistId);
    if (index != -1) {
      final playlist = newState[index] as PastSessionList;
      if (!playlist.sessions.any((g) => g.game.id == session.game.id)) {
        final updatedGames = [...playlist.sessions, session];
        final updatedList = playlist.copyWith(sessions: updatedGames);
        newState[index] = updatedList;
        state = newState;
        _saveToPrefs();
      }
    }
  }
  
  void _removePlayedGameFromCorePlaylist(String playlistId, GameInstance game) {
    final newState = [...state];
    final index = newState.indexWhere(
      (list) => list is PastSessionList && list.id == playlistId,
    );

    if (index != -1) {
      final playlist = newState[index] as PastSessionList;

      final updatedGames = playlist.sessions
          .where((g) => g.game.id != game.id)
          .toList();

      final updatedList = playlist.copyWith(sessions: updatedGames);
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
          return PastSessionList.fromJson(map);
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

  PastSessionList? get currentlyPlayingList {
    try {
      return state.firstWhere((list) => list is PastSessionList && list.id == currentlyPlayingId) as PastSessionList;
    } catch (_) {
      return null;
    }
  }

  PastSessionList? get completedList {
    try {
      return state.firstWhere((list) => list is PastSessionList && list.id == completedId) as PastSessionList;
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
