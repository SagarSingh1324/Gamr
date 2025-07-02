import './game_instance.dart';

class PastSession {
  final GameInstance game;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration totalPlaytime;

  PastSession({
    required this.game,
    required this.startedAt,
    required this.completedAt,
    required this.totalPlaytime,
  });

  PastSession copyWith({
    GameInstance? game,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? totalPlaytime,
  }) {
    return PastSession(
      game: game ?? this.game,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalPlaytime: totalPlaytime ?? this.totalPlaytime,
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
      totalPlaytime: Duration(seconds: json['totalPlaytime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game': game.toJson(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'totalPlaytime': totalPlaytime.inSeconds,
    };
  }
}
