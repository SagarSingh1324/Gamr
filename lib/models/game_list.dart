import 'package:flutter/material.dart';
import './game_instance.dart';

class GameList {
  final String id;        
  final String label;        
  final List<GameInstance> games;
  final bool isCore;        
  final IconData? icon;    
  final DateTime? createdAt; 
  
  GameList({
    required this.id,
    required this.label,
    required this.games,
    this.isCore = false,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Copy with method for immutable updates
  GameList copyWith({
    String? id,
    String? label,
    List<GameInstance>? games,
    bool? isCore,
    IconData? icon,
    DateTime? createdAt,
  }) {
    return GameList(
      id: id ?? this.id,
      label: label ?? this.label,
      games: games ?? this.games,
      isCore: isCore ?? this.isCore,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Convenience getters
  int get gameCount => games.length;
  bool get isEmpty => games.isEmpty;
  bool get isNotEmpty => games.isNotEmpty;
  
  // Check if a game exists in this list
  bool containsGame(GameInstance game) {
    return games.any((g) => g.id == game.id);
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'games': games.map((g) => g.toJson()).toList(),
    'isCore': isCore,
    'iconCodePoint': icon?.codePoint,  // Store icon as code point
    'iconFontFamily': icon?.fontFamily,
    'createdAt': createdAt?.toIso8601String(),
  };
  
  factory GameList.fromJson(Map<String, dynamic> json) {
    IconData? iconData;
    if (json['iconCodePoint'] != null) {
      iconData = IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
      );
    }
    
    return GameList(
      id: json['id'] as String,
      label: json['label'] as String,
      games: (json['games'] as List)
          .map((g) => GameInstance.fromJson(g))
          .toList(),
      isCore: json['isCore'] as bool? ?? false,
      icon: iconData,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameList &&
        other.id == id &&
        other.label == label &&
        other.isCore == isCore;
  }
  
  @override
  int get hashCode => Object.hash(id, label, isCore);
  
  @override
  String toString() {
    return 'GameList(id: $id, label: $label, games: ${games.length}, isCore: $isCore)';
  }
}