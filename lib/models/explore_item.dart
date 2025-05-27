class ExploreItem {
  final int id;
  final String name;

  ExploreItem({required this.id, required this.name});

  factory ExploreItem.fromJson(Map<String, dynamic> json) {
    return ExploreItem(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
