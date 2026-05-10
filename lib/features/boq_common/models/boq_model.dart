import 'dart:convert';

class CommonBoqItem {
  final String id;
  final String siteId;
  final String description;
  final double totalQuantity;
  final String unit;
  final String category; // Civil, Erection, Roofing, Fabrication
  final double weightPerUnit;

  CommonBoqItem({
    required this.id,
    required this.siteId,
    required this.description,
    required this.totalQuantity,
    required this.unit,
    required this.category,
    this.weightPerUnit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'siteId': siteId,
      'description': description,
      'totalQuantity': totalQuantity,
      'unit': unit,
      'category': category,
      'weightPerUnit': weightPerUnit,
    };
  }

  factory CommonBoqItem.fromMap(Map<String, dynamic> map) {
    return CommonBoqItem(
      id: map['id'] ?? '',
      siteId: map['siteId'] ?? '',
      description: map['description'] ?? '',
      totalQuantity: (map['totalQuantity'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'MT',
      category: map['category'] ?? '',
      weightPerUnit: (map['weightPerUnit'] ?? 0.0).toDouble(),
    );
  }
}
