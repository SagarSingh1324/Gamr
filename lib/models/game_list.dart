import './game_instance.dart';

class GameList {
  final String label;
  final List<GameInstance> games;

  GameList({required this.label, required this.games});

  Map<String, dynamic> toJson() => {
    'label': label,
    'games': games.map((g) => g.toJson()).toList(),
  };

  factory GameList.fromJson(Map<String, dynamic> json) => GameList(
    label: json['label'],
    games: (json['games'] as List)
        .map((g) => GameInstance.fromJson(g))
        .toList(),
  );
}