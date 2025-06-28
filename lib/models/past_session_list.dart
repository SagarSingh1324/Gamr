import 'package:flutter/material.dart';
import 'past_session.dart';

class PastSessionList {
  final String id;           // Unique identifier for core playlists
  final String label;         // Display name
  final List<PastSession> sessions;
  final bool isCore;          // Whether this is a core (non-deletable) playlist
  final IconData? icon;       // Optional icon for display
  final DateTime? createdAt;  // When the playlist was created
  
  PastSessionList({
    required this.id,
    required this.label,
    required this.sessions,
    this.isCore = false,
    this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // Copy with method for immutable updates
  PastSessionList copyWith({
    String? id,
    String? label,
    List<PastSession>? sessions,
    bool? isCore,
    IconData? icon,
    DateTime? createdAt,
  }) {
    return PastSessionList(
      id: id ?? this.id,
      label: label ?? this.label,
      sessions: sessions ?? this.sessions,
      isCore: isCore ?? this.isCore,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  // Convenience getters
  int get gameCount => sessions.length;
  bool get isEmpty => sessions.isEmpty;
  bool get isNotEmpty => sessions.isNotEmpty;
  
  // Check if a game exists in this list
  bool containsGame(PastSession session) {
    return sessions.any((g) => g.game.id == session.game.id);
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'games': sessions.map((g) => g.toJson()).toList(),
    'isCore': isCore,
    'iconCodePoint': icon?.codePoint,  
    'iconFontFamily': icon?.fontFamily,
    'createdAt': createdAt?.toIso8601String(),
  };
  
factory PastSessionList.fromJson(Map<String, dynamic> json) {
  IconData? iconData;
  if (json['iconCodePoint'] != null) {
    iconData = IconData(
      json['iconCodePoint'] as int,
      fontFamily: json['iconFontFamily'] as String?,
    );
  }

  final gamesJson = json['games'];
  final List<PastSession> sessions;

  if (gamesJson is List) {
    sessions = gamesJson
        .whereType<Map<String, dynamic>>()
        .map((g) => PastSession.fromJson(g))
        .toList();
  } else {
    sessions = [];
  }

  return PastSessionList(
    id: json['id'] as String,
    label: json['label'] as String,
    sessions: sessions,
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
    return other is PastSessionList &&
        other.id == id &&
        other.label == label &&
        other.isCore == isCore;
  }
  
  @override
  int get hashCode => Object.hash(id, label, isCore);
  
  @override
  String toString() {
    return 'GameList(id: $id, label: $label, games: ${sessions.length}, isCore: $isCore)';
  }
}