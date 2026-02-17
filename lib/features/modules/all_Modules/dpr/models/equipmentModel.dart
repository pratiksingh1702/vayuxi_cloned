import 'package:untitled2/features/modules/all_Modules/dpr/models/rate_file_models.dart';

class EquipmentItem {
  final String id;
  final String materialName;
  final String image;
  final double qty;
  final String uom;
  final double length;
  final double rmt;
  final double diameter;
  final double weight;
  final double power;
  final double actualRate;
  final double rate;
  final String moc;
  final String size;
  final String location;
  final String plant;
  final List<String> designation;
  final String calculationCategory;
  final String remarks;
  final bool isFromRateFile;
  final String? rateFileId;
  final String? rateVariantId;
  final List<DynamicField> dynamicFields;

  const EquipmentItem({
    required this.id,
    required this.materialName,
    required this.image,
    required this.qty,
    required this.uom,
    required this.length,
    required this.rmt,
    required this.diameter,
    required this.weight,
    required this.power,
    this.dynamicFields = const [],
    required this.actualRate,
    required this.rate,
    required this.moc,
    required this.size,
    required this.location,
    required this.plant,
    required this.designation,
    required this.calculationCategory,
    this.remarks = '',
    this.isFromRateFile = false,
    this.rateFileId,
    this.rateVariantId,
  });

  factory EquipmentItem.fromJson(Map<String, dynamic> json) {
    return EquipmentItem(
      id: json['_id'] ?? json['id'] ?? '',
      materialName: json['materialName'] ?? '',
      image: json['image'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      length: (json['length'] ?? 0).toDouble(),
      rmt: (json['rmt'] ?? 0).toDouble(),
      diameter: (json['diameter'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      power: (json['power'] ?? 0).toDouble(),
      actualRate: (json['actualRate'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      moc: json['moc'] ?? '',
      size: json['size'] ?? '',
      // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐
      dynamicFields: (json['dynamicFields'] ?? [])
          .map<DynamicField>((e) => DynamicField.fromJson(e))
          .toList(),
      // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐

      location: json['location'] ?? '',
      plant: json['plant'] ?? '',
      designation: List<String>.from(json['designation'] ?? const []),
      calculationCategory: json['calculationCategory'] ?? '',
      remarks: json['remarks'] ?? '',
      isFromRateFile: json['isFromRateFile'] ?? false,
      rateFileId: json['rateFileId'],
      rateVariantId: json['rateVariantId'],
    );
  }

  // Convert from RateFileMaterial to EquipmentItem
  factory EquipmentItem.fromRateMaterial(RateFileMaterial rateMaterial, RateVariant variant) {
    // Parse size range if available
    String size = '';
    if (variant.sizeRange != null) {
      final sr = variant.sizeRange!;
      size = '${sr['min'] ?? ''}-${sr['max'] ?? ''} ${sr['unit'] ?? ''}';
    }

    return EquipmentItem(
      id: rateMaterial.id, // Will be generated when saving
      materialName: rateMaterial.normalizedMaterialName,
      image: rateMaterial.image,
      qty: 0, // Default quantity
      uom: variant.uom,
      length: 0,
      rmt: 0,
      dynamicFields: rateMaterial.dynamicFields,
      diameter: 0,
      weight: 0,
      power: 0,
      actualRate: variant.rate,
      rate: variant.rate,
      moc: variant.moc.isNotEmpty ? variant.moc : rateMaterial.normalizedMoc,
      size: size,
      location: variant.floor,
      plant: '',
      designation: rateMaterial.designation,
      calculationCategory: rateMaterial.calculationCategory,
      remarks: variant.remarks,
      isFromRateFile: true,
      rateFileId: rateMaterial.id,
      rateVariantId: '', // You might want to generate a variant ID
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialName': materialName,
      'image': image,
      'qty': qty,
      'uom': uom,
      'length': length,
      'rmt': rmt,
      'diameter': diameter,
      'weight': weight,
      'power': power,
      'actualRate': actualRate,
      'rate': rate,
      'moc': moc,
      'size': size,
      'location': location,
      'plant': plant,
      'designation': designation,
      'calculationCategory': calculationCategory,
      'remarks': remarks,
      'isFromRateFile': isFromRateFile,
      'rateFileId': rateFileId,
      'rateVariantId': rateVariantId,
    };
  }

  EquipmentItem copyWith({
    String? id,
    String? materialName,
    String? image,
    double? qty,
    String? uom,
    double? length,
    double? rmt,
    double? diameter,
    double? weight,
    double? power,
    double? actualRate,
    double? rate,
    String? moc,
    String? size,
    List<DynamicField>? dynamicFields,
    String? location,
    String? plant,
    List<String>? designation,
    String? calculationCategory,
    String? remarks,
    bool? isFromRateFile,
    String? rateFileId,
    String? rateVariantId,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      materialName: materialName ?? this.materialName,
      image: image ?? this.image,
      qty: qty ?? this.qty,
      uom: uom ?? this.uom,
      dynamicFields: dynamicFields ?? this.dynamicFields,
      length: length ?? this.length,
      rmt: rmt ?? this.rmt,
      diameter: diameter ?? this.diameter,
      weight: weight ?? this.weight,
      power: power ?? this.power,
      actualRate: actualRate ?? this.actualRate,
      rate: rate ?? this.rate,
      moc: moc ?? this.moc,
      size: size ?? this.size,
      location: location ?? this.location,
      plant: plant ?? this.plant,
      designation: designation ?? this.designation,
      calculationCategory: calculationCategory ?? this.calculationCategory,
      remarks: remarks ?? this.remarks,
      isFromRateFile: isFromRateFile ?? this.isFromRateFile,
      rateFileId: rateFileId ?? this.rateFileId,
      rateVariantId: rateVariantId ?? this.rateVariantId,
    );
  }

  static EquipmentItem empty() => const EquipmentItem(
    id: '',
    materialName: '',
    image: '',
    qty: 0,
    uom: '',
    length: 0,
    dynamicFields: const [],
    rmt: 0,
    diameter: 0,
    weight: 0,
    power: 0,
    actualRate: 0,
    rate: 0,
    moc: '',
    size: '',
    location: '',
    plant: '',
    designation: [],
    calculationCategory: '',
    remarks: '',
    isFromRateFile: false,
  );
}