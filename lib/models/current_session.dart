import './game_instance.dart';

class CurrentSession {
  final GameInstance game;
  final DateTime? startTime;
  final Duration elapsed;
  final bool isPlaying;

  CurrentSession({
    required this.game,
    this.startTime,
    this.elapsed = Duration.zero,
    this.isPlaying = false,
  });

  CurrentSession copyWith({
    DateTime? startTime,
    Duration? elapsed,
    bool? isPlaying,
  }) {
    return CurrentSession(
      game: game,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
