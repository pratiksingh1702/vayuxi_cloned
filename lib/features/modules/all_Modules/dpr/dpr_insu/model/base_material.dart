import 'material_setup.dart';

abstract class BaseMaterial {
  final String id;
  final String name;
  final List<String> image;
  final String uom;
  final String remarks;
  
  // Legacy fields for backward compatibility
  final int qty;
  final double length;
  final double circumference;
  final double circumference1;
  final double circumference2;
  final double zHeight;
  final double gSlantHeight;
  final double constant;
  final double totalArea;
  final double diameterA3;
  final double diameterB3;
  final double diameterA2;
  final double diameterB2;
  final double diameterA1;
  final double diameterB1;
  final double circumferenceFinal;
  final double layer1Area;
  final double layer2Area;
  final double layer3Area;
  final double circumference3;
  final double circumference2Calc;
  final double circumference1Calc;
  final double o3;
  final double o2;
  final double o1;
  
  // New dynamic fields support
  final String? materialCode;
  final FieldValues? fieldValues;
  final Map<String, String>? customLabels;

  const BaseMaterial({
    required this.id,
    required this.name,
    required this.image,
    required this.uom,
    required this.remarks,
    this.materialCode,
    this.fieldValues,
    this.customLabels,
    this.qty = 0,
    this.length = 0,
    this.circumference = 0,
    this.circumference1 = 0,
    this.circumference2 = 0,
    this.zHeight = 0,
    this.gSlantHeight = 0,
    this.constant = 0,
    this.totalArea = 0,
    this.diameterA3 = 0,
    this.diameterB3 = 0,
    this.diameterA2 = 0,
    this.diameterB2 = 0,
    this.diameterA1 = 0,
    this.diameterB1 = 0,
    this.circumferenceFinal = 0,
    this.layer1Area = 0,
    this.layer2Area = 0,
    this.layer3Area = 0,
    this.circumference3 = 0,
    this.circumference2Calc = 0,
    this.circumference1Calc = 0,
    this.o3 = 0,
    this.o2 = 0,
    this.o1 = 0,
  });

  /// Child classes must implement their own factories
  factory BaseMaterial.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Use concrete material fromJson');
  }

  Map<String, dynamic> toJson();

  BaseMaterial copyWith({
    String? id,
    String? name,
    List<String>? image,
    String? uom,
    String? remarks,
    String? materialCode,
    FieldValues? fieldValues,
    Map<String, String>? customLabels,
    int? qty,
    double? length,
    double? circumference,
    double? circumference1,
    double? circumference2,
    double? zHeight,
    double? gSlantHeight,
    double? constant,
    double? totalArea,
    double? diameterA3,
    double? diameterB3,
    double? diameterA2,
    double? diameterB2,
    double? diameterA1,
    double? diameterB1,
    double? circumferenceFinal,
    double? layer1Area,
    double? layer2Area,
    double? layer3Area,
    double? circumference3,
    double? circumference2Calc,
    double? circumference1Calc,
    double? o3,
    double? o2,
    double? o1,
  });
}
