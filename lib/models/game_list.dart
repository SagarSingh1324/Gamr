import 'package:flutter/material.dart';
import '../models/icons_preserver.dart';
import './game_instance.dart';

class GameList {
  final String id;
  final String label;
  final List<GameInstance> games;
  final bool isCore;
  final String? iconKey;         // <- new
  final DateTime? createdAt;

  GameList({
    required this.id,
    required this.label,
    required this.games,
    this.isCore = false,
    this.iconKey,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  IconData? get icon => iconKey != null ? IconPreserver.iconMap[iconKey] : null;

  GameList copyWith({
    String? id,
    String? label,
    List<GameInstance>? games,
    bool? isCore,
    String? iconKey,
    DateTime? createdAt,
  }) {
    return GameList(
      id: id ?? this.id,
      label: label ?? this.label,
      games: games ?? this.games,
      isCore: isCore ?? this.isCore,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'games': games.map((g) => g.toJson()).toList(),
    'isCore': isCore,
    'iconKey': iconKey,  // <- new
    'createdAt': createdAt?.toIso8601String(),
  };

  factory GameList.fromJson(Map<String, dynamic> json) {
    return GameList(
      id: json['id'] as String,
      label: json['label'] as String,
      games: (json['games'] as List)
          .map((g) => GameInstance.fromJson(g))
          .toList(),
      isCore: json['isCore'] as bool? ?? false,
      iconKey: json['iconKey'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
