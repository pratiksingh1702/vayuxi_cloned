// models/floor_model.dart
class Floor {
  final String id;
  final String name;
  final String code;
  final String image;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Floor({
    required this.id,
    required this.name,
    required this.code,
    required this.image,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from JSON
  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      image: json['image'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toString()),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'image': image,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updates
  Floor copyWith({
    String? id,
    String? name,
    String? code,
    String? image,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Floor(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Floor(id: $id, name: $name, code: $code, image: $image, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Floor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}