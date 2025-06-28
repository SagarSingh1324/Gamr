import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_instance.dart';
import '../providers/api_service_provider.dart';
import '../models/current_game_session.dart';

class CurrentGameNotifier extends Notifier<CurrentGameSession?> {
  Timer? _ticker;
  
  @override
  CurrentGameSession? build() {
    return null; // start empty
  }
  
  Future<void> startGame(GameInstance game) async {
    _ticker?.cancel();
    
    // Check if we need to fetch timeToBeat data
    GameInstance gameToUse = game;
  if (game.timeToBeat == null && !(!game.gameModes.contains(1)&&!game.gameModes.contains(3))) {

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
    state = CurrentGameSession(
      game: gameToUse,
      startTime: DateTime.now(),
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
  
  // @override
  void onDispose() {
    _ticker?.cancel();
  }
}



