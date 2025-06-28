import 'package:flutter/material.dart';
import '../models/played_game.dart';

class PlayedGameList {
  final String? id;           // Unique identifier for core playlists
  final String label;         // Display name
  final List<PlayedGame> playedGames;
  final bool isCore;          // Whether this is a core (non-deletable) playlist
  final IconData? icon;       // Optional icon for display
  final DateTime? createdAt;  // When the playlist was created
  
  PlayedGameList({
    this.id,
    required this.label,
    required this.playedGames,
    this.isCore = false,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Copy with method for immutable updates
  PlayedGameList copyWith({
    String? id,
    String? label,
    List<PlayedGame>? playedGames,
    bool? isCore,
    IconData? icon,
    DateTime? createdAt,
  }) {
    return PlayedGameList(
      id: id ?? this.id,
      label: label ?? this.label,
      playedGames: playedGames ?? this.playedGames,
      isCore: isCore ?? this.isCore,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Convenience getters
  int get gameCount => playedGames.length;
  bool get isEmpty => playedGames.isEmpty;
  bool get isNotEmpty => playedGames.isNotEmpty;
  
  // Check if a game exists in this list
  bool containsGame(PlayedGame game) {
    return playedGames.any((g) => g.game.id == game.game.id);
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'games': playedGames.map((g) => g.toJson()).toList(),
    'isCore': isCore,
    'iconCodePoint': icon?.codePoint,  
    'iconFontFamily': icon?.fontFamily,
    'createdAt': createdAt?.toIso8601String(),
  };
  
factory PlayedGameList.fromJson(Map<String, dynamic> json) {
  IconData? iconData;
  if (json['iconCodePoint'] != null) {
    iconData = IconData(
      json['iconCodePoint'] as int,
      fontFamily: json['iconFontFamily'] as String?,
    );
  }

  final gamesJson = json['games'];
  final List<PlayedGame> playedGames;

  if (gamesJson is List) {
    playedGames = gamesJson
        .whereType<Map<String, dynamic>>()
        .map((g) => PlayedGame.fromJson(g))
        .toList();
  } else {
    playedGames = [];
  }

  return PlayedGameList(
    id: json['id'] as String?,
    label: json['label'] as String,
    playedGames: playedGames,
    isCore: json['isCore'] as bool? ?? false,
    icon: iconData,
    createdAt: json['createdAt'] != null 
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );
}

  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayedGameList &&
        other.id == id &&
        other.label == label &&
        other.isCore == isCore;
  }
  
  @override
  int get hashCode => Object.hash(id, label, isCore);
  
  @override
  String toString() {
    return 'GameList(id: $id, label: $label, games: ${playedGames.length}, isCore: $isCore)';
  }
}