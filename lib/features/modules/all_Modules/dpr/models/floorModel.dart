// models/floor_model.dart
class Floor {
  final String id;
  final String name;
  final String image;
  final String? siteId;
  final bool isApplied;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Floor({
    required this.id,
    required this.name,
    required this.image,
    this.siteId,
    required this.isApplied,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      siteId: json['siteId'] is String
          ? json['siteId']
          : json['siteId'] is Map
          ? json['siteId']['_id']
          : null,
      isApplied: json['isApplied'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Floor copyWith({
    String? id,
    String? name,
    String? image,
    String? siteId,
    bool? isApplied,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Floor(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      siteId: siteId ?? this.siteId,
      isApplied: isApplied ?? this.isApplied,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
