import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:gamr/models/game_instance.dart';
import '../models/game_list.dart';
import '../models/past_session.dart';
import '../models/past_session_list.dart';
import '../models/current_session.dart';
import '../providers/api_service_provider.dart';

class GameLibraryNotifier extends AsyncNotifier<List<dynamic>> {
  // ===========================================
  // CORE LISTS (PastSessionList) - Constants
  // ===========================================

  static const String currentlyPlayingId = 'core_currently_playing';
  static const String completedId = 'core_completed';

  // ===========================================
  // NON-CORE LISTS (GameList) - Constants
  // ===========================================

  static const String wishlistId = 'non_core_wishlist';

  @override
  Future<List<dynamic>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('game_lists');

    List<dynamic> lists = [];

    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      lists = decoded.map((e) {
        final map = Map<String, dynamic>.from(e);
        final id = map['id'];
        final type = map['type'];

        if (type == 'played' || id == currentlyPlayingId || id == completedId) {
          return PastSessionList.fromJson(map);
        } else {
          return GameList.fromJson(map);
        }
      }).toList();
    }

    // Ensure core lists exist
    lists = _initializeCoreLists(lists);
    lists = _initializeNonCoreLists(lists);

    return lists; 
  }

  // ===========================================
  // CORE LISTS (PastSessionList) - Initialization
  // ===========================================

  List<dynamic> _initializeCoreLists(List<dynamic> state) {
    final hasCurrentlyPlaying = state.any((list) => list is PastSessionList && list.id == currentlyPlayingId);
    final hasCompleted = state.any((list) => list is PastSessionList && list.id == completedId);

    final newLists = [...state];

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

    return newLists;
  }

  // ===========================================
  // NON-CORE LISTS (GameList) - Initialization
  // ===========================================

  List<dynamic> _initializeNonCoreLists(List<dynamic> lists) {
    final hasWishlist = lists.any((list) => list is GameList && list.id == wishlistId);

    final newLists = [...lists];

    if (!hasWishlist) {
      newLists.add(GameList(
        id: wishlistId,
        label: 'Wishlist',
        games: [],
        isCore: true,
        icon: Icons.favorite,
      ));
    }

    return newLists;
  }

  // ===========================================
  // GENERIC LIST OPERATIONS
  // ===========================================
  
  void addList(dynamic list) {
    state = AsyncValue.data([
      ...(state.value ?? []),
      list,
    ]);
    _saveToPrefs();
  }

  void removeList(dynamic list) {
    if (list.isCore == true) return;
    final updated = (state.value ?? []).where((l) => l != list).toList();
    state = AsyncValue.data(updated);
    _saveToPrefs();
  }

  void updateList(String listId, dynamic newList) {
    final current = [...(state.value ?? [])];
    final index = current.indexWhere((l) => l.id == listId);
    if (index != -1) {
      current[index] = newList;
      state = AsyncValue.data(current);
      _saveToPrefs();
    }
  }

  // ===========================================
  // CORE LISTS (PastSessionList) - Operations
  // ===========================================

  void addToCurrentlyPlaying(CurrentSession session) {
    // Remove game from completed list if it exists there
    _removePlayedGameFromCorePlaylist(completedId, session.game);

    final currentLists = [...(state.value ?? [])];
    final currentlyPlayingIndex = currentLists.indexWhere(
      (list) => list is PastSessionList && list.id == currentlyPlayingId
    );

    if (currentlyPlayingIndex != -1) {
      final playlist = currentLists[currentlyPlayingIndex] as PastSessionList;
      final existingIndex = playlist.sessions.indexWhere((s) => s.game.id == session.game.id);

      if (existingIndex == -1) {
        // Game not in currently playing — add it
        final newSession = PastSession(
          game: session.game,
          startedAt: session.startTime ?? DateTime.now(),
          completedAt: DateTime.fromMillisecondsSinceEpoch(0), // Not completed yet
          totalPlaytime: (session.totalPlaytime + session.elapsed),
        );
        
        final updatedSessions = [...playlist.sessions, newSession];
        final updatedPlaylist = playlist.copyWith(sessions: updatedSessions);
        currentLists[currentlyPlayingIndex] = updatedPlaylist;
      } else {
        // Game already exists — update playtime
        final existing = playlist.sessions[existingIndex];
        final updatedSession = PastSession(
          game: existing.game,
          startedAt: existing.startedAt,
          completedAt: existing.completedAt,
          totalPlaytime: (existing.totalPlaytime + session.elapsed),
        );
        
        final updatedSessions = [...playlist.sessions];
        updatedSessions[existingIndex] = updatedSession;
        final updatedPlaylist = playlist.copyWith(sessions: updatedSessions);
        currentLists[currentlyPlayingIndex] = updatedPlaylist;
      }

      state = AsyncValue.data(currentLists);
      _saveToPrefs();
    }
  }

  void addToCompleted(CurrentSession session) {
    // Remove game from currently playing list
    _removePlayedGameFromCorePlaylist(currentlyPlayingId, session.game);

    final currentLists = [...(state.value ?? [])];
    final completedIndex = currentLists.indexWhere(
      (list) => list is PastSessionList && list.id == completedId
    );

    if (completedIndex != -1) {
      final playlist = currentLists[completedIndex] as PastSessionList;
      final existingIndex = playlist.sessions.indexWhere((s) => s.game.id == session.game.id);

      if (existingIndex == -1) {
        // Game not in completed list — add it
        final newSession = PastSession(
          game: session.game,
          startedAt: session.startTime ?? DateTime.now(),
          completedAt: DateTime.now(), // Mark as completed now
          totalPlaytime: (session.totalPlaytime + session.elapsed),
        );
        
        final updatedSessions = [...playlist.sessions, newSession];
        final updatedPlaylist = playlist.copyWith(sessions: updatedSessions);
        currentLists[completedIndex] = updatedPlaylist;
      } else {
        // Game already exists — update playtime and completion time
        final existing = playlist.sessions[existingIndex];
        final updatedSession = PastSession(
          game: existing.game,
          startedAt: existing.startedAt,
          completedAt: DateTime.now(), // Update completion time
          totalPlaytime: (existing.totalPlaytime + session.elapsed),
        );
        
        final updatedSessions = [...playlist.sessions];
        updatedSessions[existingIndex] = updatedSession;
        final updatedPlaylist = playlist.copyWith(sessions: updatedSessions);
        currentLists[completedIndex] = updatedPlaylist;
      }

      state = AsyncValue.data(currentLists);
      _saveToPrefs();
    }
  }

  void _removePlayedGameFromCorePlaylist(String playlistId, GameInstance game) {
    final currentLists = [...(state.value ?? [])];
    final index = currentLists.indexWhere(
      (list) => list is PastSessionList && list.id == playlistId,
    );

    if (index != -1) {
      final playlist = currentLists[index] as PastSessionList;

      final updatedSessions = playlist.sessions
          .where((g) => g.game.id != game.id)
          .toList();

      final updatedList = playlist.copyWith(sessions: updatedSessions);
      currentLists[index] = updatedList;

      state = AsyncValue.data(currentLists);
      _saveToPrefs();
    }
  }

  // ===========================================
  // NON-CORE LISTS (GameList) - Operations
  // ===========================================

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
        debugPrint('Error fetching game with id $id: $e');
      }
    }

    final newGameList = GameList(
      id: UniqueKey().toString(),
      label: listName,
      games: games,
    );

    state = AsyncValue.data([
      ...(state.value ?? []),
      newGameList,
    ]);

    _saveToPrefs();
  }

  // ===========================================
  // PERSISTENCE
  // ===========================================

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = state.value ?? [];
    final jsonData = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('game_lists', jsonData);
  }

  // ===========================================
  // CORE LISTS (PastSessionList) - Helpers
  // ===========================================

  PastSessionList get currentlyPlayingList {
    return (state.value ?? [])
        .firstWhere((list) => list is PastSessionList && list.id == currentlyPlayingId)
        as PastSessionList;
  }

  PastSessionList get completedList {
    return (state.value ?? [])
        .firstWhere((list) => list is PastSessionList && list.id == completedId)
        as PastSessionList;
  }

  // ===========================================
  // NON-CORE LISTS (GameList) - Helpers
  // ===========================================

  GameList? get wishlist {
    return (state.value ?? [])
        .firstWhere(
          (list) => list is GameList && list.id == wishlistId,
          orElse: () => null,
        ) as GameList?;
  }

  List<GameList> get nonCoreLists {
    return (state.value ?? [])
        .whereType<GameList>()
        .where((list) => list.id != wishlistId)
        .toList();
  }

  List<PastSessionList> get coreLists {
    return (state.value ?? [])
        .whereType<PastSessionList>()
        .toList();
  }
}