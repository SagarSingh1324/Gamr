class GamePop {
  final int gameId;
  final double value;
  final int popularityType;

  GamePop({
    required this.gameId,
    required this.value,
    required this.popularityType,
  });

  // Factory constructor to create GamePop from JSON
  factory GamePop.fromJson(Map<String, dynamic> json) {
    return GamePop(
      gameId: json['game_id'] as int,
      value: (json['value'] as num).toDouble(),
      popularityType: json['popularity_type'] as int,
    );
  }

  // Method to convert GamePop to JSON
  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'value': value,
      'popularity_type': popularityType,
    };
  }

  // Copy method for creating modified instances
  GamePop copyWith({
    int? gameId,
    double? value,
    int? popularityType,
  }) {
    return GamePop(
      gameId: gameId ?? this.gameId,
      value: value ?? this.value,
      popularityType: popularityType ?? this.popularityType,
    );
  }
}