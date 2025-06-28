class GameInstance {
  final int id;
  final String name;
  final String summary;
  final Cover cover;
  final List<Genre> genres;
  final List<int> gameModes; 
  final TimeToBeat? timeToBeat; 

  GameInstance({
    required this.id,
    required this.name,
    required this.summary,
    required this.cover,
    required this.genres,
    required this.gameModes,
    this.timeToBeat, 
  });

  factory GameInstance.fromJson(Map<String, dynamic> json) {
    return GameInstance(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      summary: json['summary'] as String? ?? 'No summary',
      cover: json['cover'] != null
          ? Cover.fromJson(json['cover'] as Map<String, dynamic>)
          : Cover(id: 0, url: ''),
      genres: json['genres'] != null
          ? (json['genres'] as List)
              .map((genreJson) =>
                  Genre.fromJson(genreJson as Map<String, dynamic>))
              .toList()
          : <Genre>[],
      gameModes: json['game_modes'] != null
          ? List<int>.from(json['game_modes'])
          : <int>[],
      // timeToBeat will be null initially, added separately
    );
  }

  // Copy method to add TTB data later
  GameInstance copyWith({
    int? id,
    String? name,
    String? summary,
    Cover? cover,
    List<Genre>? genres,
    List<int>? gameModes,
    TimeToBeat? timeToBeat,
  }) {
    return GameInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      cover: cover ?? this.cover,
      genres: genres ?? this.genres,
      gameModes: gameModes ?? this.gameModes,
      timeToBeat: timeToBeat ?? this.timeToBeat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'cover': cover.toJson(),
      'genres': genres.map((genre) => genre.toJson()).toList(),
      'game_modes': gameModes,
      'time_to_beat': timeToBeat?.toJson(),
    };
  }

  // Helper getter to check if TTB data is available
  bool get hasTimeToBeat => timeToBeat != null;
  
  // Helper getters for common TTB values (in seconds)
  int? get normalCompletionTime => timeToBeat?.normally;
  int? get fullCompletionTime => timeToBeat?.completely;
  int? get speedrunTime => timeToBeat?.hastily;
}

class TimeToBeat {
  final int? hastily;   // Speedrun/rushed time in seconds
  final int? normally;  // Normal completion time in seconds
  final int? completely; // 100% completion time in seconds

  TimeToBeat({
    this.hastily,
    this.normally,
    this.completely,
  });

  factory TimeToBeat.fromJson(Map<String, dynamic> json) {
    return TimeToBeat(
      hastily: json['hastily'] as int?,
      normally: json['normally'] as int?,
      completely: json['completely'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hastily': hastily,
      'normally': normally,
      'completely': completely,
    };
  }

  // Helper method to get the most relevant completion time in seconds
  int? get primaryTime => normally ?? completely ?? hastily;
}

class Cover {
  final int id;
  final String url;

  Cover({
    required this.id,
    required this.url,
  });

  factory Cover.fromJson(Map<String, dynamic> json) {
    return Cover(
      id: json['id'] as int,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
    };
  }
}

class Genre {
  final int id;
  final String name;

  Genre({
    required this.id,
    required this.name,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name, 
    };
  }
}