import './game_instance.dart';

class PastSession {
  final GameInstance game;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration totalPlayTime;

  PastSession({
    required this.game,
    required this.startedAt,
    required this.completedAt,
    required this.totalPlayTime,
  });

  PastSession copyWith({
    GameInstance? game,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? totalPlayTime,
  }) {
    return PastSession(
      game: game ?? this.game,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
    );
  }

  factory PastSession.fromJson(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) {
      throw ArgumentError('Invalid or null JSON provided to PlayedGame.fromJson');
    }

    return PastSession(
      game: GameInstance.fromJson(json['game']),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: DateTime.parse(json['completedAt']),
      totalPlayTime: Duration(seconds: json['totalPlayTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game': game.toJson(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'totalPlayTime': totalPlayTime.inSeconds,
    };
  }
}
