import './game_instance.dart';

class CurrentGameSession {
  final GameInstance game;
  final DateTime? startTime;
  final Duration elapsed;
  final bool isPlaying;

  CurrentGameSession({
    required this.game,
    this.startTime,
    this.elapsed = Duration.zero,
    this.isPlaying = false,
  });

  CurrentGameSession copyWith({
    DateTime? startTime,
    Duration? elapsed,
    bool? isPlaying,
  }) {
    return CurrentGameSession(
      game: game,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
