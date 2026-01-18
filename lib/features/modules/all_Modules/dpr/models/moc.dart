class MOC {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isPredefined; // derived locally
  final DateTime createdAt;

  const MOC({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isPredefined = false,
    required this.createdAt,
  });

  /// COPY
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

  /// FROM API JSON
  factory MOC.fromJson(Map<String, dynamic> json) {
    return MOC(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'] ?? json['image'],
      isPredefined: json['isPredefined'] ?? false, // fallback if backend adds later
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// TO JSON (for local use, not multipart)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isPredefined': isPredefined,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
