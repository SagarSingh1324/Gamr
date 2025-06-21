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

class GameInstance {
  final int id;
  final String name;
  final String summary;
  final Cover cover;

  GameInstance({
    required this.id,
    required this.name,
    required this.summary,
    required this.cover,
  });

  factory GameInstance.fromJson(Map<String, dynamic> json) {
    return GameInstance(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',
      summary: json['summary'] as String? ?? 'No summary',
      cover: json['cover'] != null
          ? Cover.fromJson(json['cover'] as Map<String, dynamic>)
          : Cover(id: 0, url: ''), // fallback
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'cover': cover.toJson(),
    };
  }
}
