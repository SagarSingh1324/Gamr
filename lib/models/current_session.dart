import './game_instance.dart';

class CurrentSession {
  final GameInstance game;
  final DateTime? startTime;
  final Duration totalPlaytime;
  final Duration elapsed;
  final bool isPlaying;

  CurrentSession({
    required this.game,
    this.startTime,
    this.totalPlaytime = Duration.zero,
    this.elapsed = Duration.zero,
    this.isPlaying = false,
  });

  CurrentSession copyWith({
    DateTime? startTime,
    Duration? totalPlaytime,
    Duration? elapsed,
    bool? isPlaying,
  }) {
    return CurrentSession(
      game: game,
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      totalPlaytime: totalPlaytime ?? this.totalPlaytime,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
