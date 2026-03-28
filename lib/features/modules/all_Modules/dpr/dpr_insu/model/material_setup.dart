// lib/features/modules/all_Modules/dpr/dpr_insu/model/material_setup.dart

import 'field_config.dart';

class MaterialSetup {
  final String id;
  final String name;
  final String materialCode;
  final List<String> image;
  final String uom;
  final String designation;
  final String calculationType;
  final FieldConfig fieldConfig;
  final CalculationConfig? calculationConfig;
  final Map<String, dynamic>? isConstants;
  final bool isDefault;
  final bool isDeleted;
  final int displayOrder;
  final String siteId;
  final String companyId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MaterialSetup({
    required this.id,
    required this.name,
    required this.materialCode,
    required this.image,
    required this.uom,
    required this.designation,
    required this.calculationType,
    required this.fieldConfig,
    this.calculationConfig,
    this.isConstants,
    this.isDefault = false,
    this.isDeleted = false,
    this.displayOrder = 0,
    required this.siteId,
    required this.companyId,
    this.createdAt,
    this.updatedAt,
  });

  factory MaterialSetup.fromJson(Map<String, dynamic> json) {
    return MaterialSetup(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      materialCode: json['materialCode'] as String? ?? '',
      image: (json['image'] as List?)?.cast<String>() ?? [],
      uom: json['uom'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      calculationType: json['calculationType'] as String? ?? '',
      fieldConfig: json['fieldConfig'] != null
          ? FieldConfig.fromJson(json['fieldConfig'] as Map<String, dynamic>)
          : FieldConfig(
        fields: [],
        unitDropdowns: UnitDropdowns.fromJson({}),
        defaults: FieldDefaults.fromJson({}),
        ui: UiConfig.fromJson({}),
      ),
      calculationConfig: json['calculationConfig'] != null
          ? CalculationConfig.fromJson(
          json['calculationConfig'] as Map<String, dynamic>)
          : null,
      isConstants: json['isConstants'] as Map<String, dynamic>?,
      isDefault: json['isDefault'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int? ?? 0,
      siteId: _extractId(json['siteId']),
      companyId: _extractId(json['company']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  static String _extractId(dynamic value) {
    if (value is String) return value;
    if (value is Map<String, dynamic>) return value['_id'] as String? ?? '';
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'materialCode': materialCode,
      'image': image,
      'uom': uom,
      'designation': designation,
      'calculationType': calculationType,
      'fieldConfig': fieldConfig.toJson(),
      if (calculationConfig != null)
        'calculationConfig': calculationConfig!.toJson(),
      if (isConstants != null) 'isConstants': isConstants,
      'isDefault': isDefault,
      'isDeleted': isDeleted,
      'displayOrder': displayOrder,
      'siteId': siteId,
      'company': companyId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  MaterialSetup copyWith({
    String? id,
    String? name,
    String? materialCode,
    List<String>? image,
    String? uom,
    String? designation,
    String? calculationType,
    FieldConfig? fieldConfig,
    CalculationConfig? calculationConfig,
    Map<String, dynamic>? isConstants,
    bool? isDefault,
    bool? isDeleted,
    int? displayOrder,
    String? siteId,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialSetup(
      id: id ?? this.id,
      name: name ?? this.name,
      materialCode: materialCode ?? this.materialCode,
      image: image ?? this.image,
      uom: uom ?? this.uom,
      designation: designation ?? this.designation,
      calculationType: calculationType ?? this.calculationType,
      fieldConfig: fieldConfig ?? this.fieldConfig,
      calculationConfig: calculationConfig ?? this.calculationConfig,
      isConstants: isConstants ?? this.isConstants,
      isDefault: isDefault ?? this.isDefault,
      isDeleted: isDeleted ?? this.isDeleted,
      displayOrder: displayOrder ?? this.displayOrder,
      siteId: siteId ?? this.siteId,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}