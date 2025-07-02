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

  Future<void> startGame(GameInstance game) async {
    _ticker?.cancel();

    // First, save the currently active session if one exists
    if (state != null) {
      final gameLibrary = ref.read(gameLibraryProvider.notifier);
      
      // Update the elapsed time before saving
      final currentElapsed = state!.isPlaying 
          ? DateTime.now().difference(state!.startTime!)
          : state!.elapsed;
      
      final sessionToSave = state!.copyWith(
        elapsed: currentElapsed,
        isPlaying: false,
      );
      
      // Save current session to currently playing list
      gameLibrary.addToCurrentlyPlaying(sessionToSave);
    }
    
    // Check if we need to fetch timeToBeat data
    GameInstance gameToUse = game;
    if (game.timeToBeat == null) {

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
    final gameLibrary = ref.read(gameLibraryProvider.notifier);
    final currentlyPlaying = gameLibrary.currentlyPlayingList; 
    final completed = gameLibrary.completedList;    

    PastSession? existingSession;

    for (final session in [...currentlyPlaying.sessions, ...completed.sessions]) {
      if (session.game.id == game.id) {
        existingSession = session;
        break;
      }
    }

    final previousPlaytime = existingSession?.totalPlaytime;

    state = CurrentSession(
      game: gameToUse,
      startTime: DateTime.now(),
      totalPlaytime: previousPlaytime ?? Duration(seconds:0),
      elapsed: Duration(seconds:0),
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



