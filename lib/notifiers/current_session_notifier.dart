import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../providers/api_service_provider.dart';
import '../models/current_session.dart';
import '../providers/game_library_provider.dart'; 
import '../models/past_session.dart';

class CurrentSessionNotifier extends Notifier<CurrentSession?> {
  Timer? _ticker;
  
  @override
  CurrentSession? build() {
    return null; // start empty
  }
  
  // // Is the current session's game in Currently Playing?
  // bool get isInCurrentlyPlaying {
  //   final current = state;
  //   if (current == null) return false;

  //   final list = ref.read(gameLibraryProvider.notifier).currentlyPlayingList;
  //   if (list == null) return false;
  //   return list.sessions.any((s) => s.game.id == current.game.id);
  // }

  // // Is the current session's game in Completed?
  // bool get isInCompleted {
  //   final current = state;
  //   if (current == null) return false;

  //   final list = ref.read(gameLibraryProvider.notifier).completedList;
  //   if (list == null) return false;
  //   return list.sessions.any((s) => s.game.id == current.game.id);
  // }

  Future<void> startGame(GameInstance game) async {
    _ticker?.cancel();
    
    // Check if we need to fetch timeToBeat data
    GameInstance gameToUse = game;
    if (game.timeToBeat == null && (game.gameModes.contains(1) || game.gameModes.contains(3))) {

      try {
        final timeToBeatData =
            await ref.read(apiServiceProvider).fetchGameTimeToBeat(game.id);

        if (timeToBeatData != null) {
          final timeToBeat = TimeToBeat.fromJson(timeToBeatData);
          gameToUse = game.copyWith(timeToBeat: timeToBeat);
        } else {
        }
      } catch (e) {
        // Continue
      }
    } 

    // Check past playtime
    final library = ref.read(gameLibraryProvider.notifier);
    final currentlyPlaying = library.currentlyPlayingList;
    final completed = library.completedList;

    PastSession? existingSession;

    for (final session in [...?currentlyPlaying?.sessions, ...?completed?.sessions]) {
      if (session.game.id == game.id) {
        existingSession = session;
        break;
      }
    }

    final previousPlaytime = existingSession?.totalPlayTime ?? Duration(minutes:10);

    state = CurrentSession(
      game: gameToUse,
      startTime: DateTime.now(),
      totalPlaytime: previousPlaytime,
      isPlaying: true,
    );
    _startTimer();
  }
  
  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == null || !state!.isPlaying) return;
      final elapsed = DateTime.now().difference(state!.startTime!);
      state = state!.copyWith(elapsed: elapsed);
    });
  }
  
  void pause() {
    if (state == null || !state!.isPlaying) return;
    final elapsed = DateTime.now().difference(state!.startTime!);
    _ticker?.cancel();
    state = state!.copyWith(
      isPlaying: false,
      elapsed: elapsed,
      startTime: null,
    );
  }
  
  void resume() {
    if (state == null || state!.isPlaying) return;
    final startTime = DateTime.now().subtract(state!.elapsed);
    state = state!.copyWith(
      isPlaying: true,
      startTime: startTime,
    );
    _startTimer();
  }
  
  void markCompleted() {
    _ticker?.cancel();
    state = null;
  }

  void logSession() {
    _ticker?.cancel();
    state = null;
  }
  
  // @override
  void onDispose() {
    _ticker?.cancel();
  }
}



