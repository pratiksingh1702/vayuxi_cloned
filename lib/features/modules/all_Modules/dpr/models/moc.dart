class MOC {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isPredefined; // true = mock, false = user
  final DateTime createdAt;

  MOC({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isPredefined = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  MOC copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isPredefined,
    DateTime? createdAt,
  }) {
    return MOC(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isPredefined: isPredefined ?? this.isPredefined,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MOC.fromJson(Map<String, dynamic> json) {
    return MOC(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      isPredefined: json['isPredefined'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isPredefined': isPredefined,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
