class GameInstance {
  final int id;
  final String name;     
  final String summary; 

  GameInstance({
    required this.id, 
    required this.name, 
    required this.summary,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
    };
  }

  factory GameInstance.fromJson(Map<String, dynamic> json) {
    return GameInstance(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown',              
      summary: json['summary'] as String? ?? 'No summary',   
    );
  }
}
