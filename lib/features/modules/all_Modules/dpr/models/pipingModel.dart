import 'package:untitled2/features/modules/all_Modules/dpr/models/rate_file_models.dart';

class PipingItem {
  final String id;

  // 🔥 MATERIAL NAMES (IMPORTANT FOR TRACEABILITY)
  final String rawMaterialName;
  final String normalizedMaterialName;
  final String materialName;

  final String image;

  final double qty;
  final String uom;
  final double length;
  final double rmt;
  final double diameter;
  final double weight;
  final double power;

  final String floor;
  final String elevation;

  final double actualRate;
  final double rate;

  final String moc;
  final String size;
  final String location;
  final String plant;

  final List<String> designation;
  final String calculationCategory;
  final String remarks;

  final List<DynamicField> dynamicFields;

  /// 🔥 Rate file tracking
  final bool isFromRateFile;
  final String? rateFileId;
  final String? rateVariantId;

  const PipingItem({
    required this.id,
    required this.rawMaterialName,
    required this.normalizedMaterialName,
    required this.materialName,
    required this.image,
    required this.qty,
    required this.uom,
    required this.length,
    required this.rmt,
    required this.diameter,
    required this.weight,
    required this.power,
    required this.floor,
    required this.elevation,
    required this.actualRate,
    required this.rate,
    required this.moc,
    required this.size,
    required this.location,
    required this.plant,
    required this.designation,
    required this.calculationCategory,
    required this.dynamicFields,
    this.remarks = '',
    this.isFromRateFile = false,
    this.rateFileId,
    this.rateVariantId,
  });

  // ==============================
  // FROM JSON (Backend → App)
  // ==============================

  factory PipingItem.fromJson(Map<String, dynamic> json) {
    return PipingItem(
      id: json['_id'] ?? json['id'] ?? '',
      rawMaterialName: json['rawMaterialName'] ?? '',
      normalizedMaterialName: json['normalizedMaterialName'] ?? '',
      materialName: json['materialName'] ?? '',
      image: json['image'] ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      length: (json['length'] ?? 0).toDouble(),
      rmt: (json['rmt'] ?? 0).toDouble(),
      diameter: (json['diameter'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      power: (json['power'] ?? 0).toDouble(),
      floor: json['floor'] ?? '',
      elevation: json['elevation'] ?? '',
      actualRate: (json['actualRate'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
      moc: json['moc'] ?? '',
      size: json['size'] ?? '',
      location: json['location'] ?? '',
      plant: json['plant'] ?? '',
      designation: List<String>.from(json['designation'] ?? const []),
      calculationCategory: json['calculationCategory'] ?? '',
      remarks: json['remarks'] ?? '',
      dynamicFields: (json['dynamicFields'] ?? [])
          .map<DynamicField>((e) => DynamicField.fromJson(e))
          .toList(),
      isFromRateFile: json['isFromRateFile'] ?? false,
      rateFileId: json['rateFileId'],
      rateVariantId: json['rateVariantId'],
    );
  }

  // ==========================================
  // RateFileMaterial → PipingItem
  // ==========================================

  factory PipingItem.fromRateMaterial(
      RateFileMaterial rateMaterial,
      RateVariant variant,
      ) {
    String size = '';
    if (variant.sizeRange != null) {
      final sr = variant.sizeRange!;
      size = '${sr['min'] ?? ''}-${sr['max'] ?? ''} ${sr['unit'] ?? ''}';
    }

    final variantKey =
        '${rateMaterial.id}|${variant.moc}|${variant.floor}|${variant.uom}|${variant.rate}';

    return PipingItem(
      id: rateMaterial.id,
      rawMaterialName: rateMaterial.rawMaterialName,
      normalizedMaterialName: rateMaterial.normalizedMaterialName,
      materialName: rateMaterial.MaterialName,
      image: rateMaterial.image,
      qty: 0,
      uom: rateMaterial.uom.isNotEmpty
          ? rateMaterial.uom
          : variant.uom,
      length: 0,
      rmt: 0,
      diameter: 0,
      weight: 0,
      power: 0,
      floor: variant.floor,
      elevation: variant.elevation,
      actualRate: variant.rate,
      rate: variant.rate,
      moc: variant.moc.isNotEmpty
          ? variant.moc
          : rateMaterial.normalizedMoc,
      size: size,
      location: variant.floor,
      plant: '',
      designation: rateMaterial.designation,
      calculationCategory: rateMaterial.calculationCategory,
      remarks: variant.remarks,
      dynamicFields: rateMaterial.dynamicFields,
      isFromRateFile: true,
      rateFileId: rateMaterial.id,
      rateVariantId: variantKey,
    );
  }

  // ==============================
  // TO JSON (App → Backend)
  // ==============================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawMaterialName': rawMaterialName,
      'normalizedMaterialName': normalizedMaterialName,
      'materialName': materialName,
      'image': image,
      'qty': qty,
      'uom': uom,
      'length': length,
      'rmt': rmt,
      'diameter': diameter,
      'weight': weight,
      'power': power,
      'floor': floor,
      'elevation': elevation,
      'actualRate': actualRate,
      'rate': rate,
      'moc': moc,
      'size': size,
      'location': location,
      'plant': plant,
      'designation': designation,
      'calculationCategory': calculationCategory,
      'remarks': remarks,
      'dynamicFields':
      dynamicFields.map((e) => e.toJson()).toList(),
      'isFromRateFile': isFromRateFile,
      'rateFileId': rateFileId,
      'rateVariantId': rateVariantId,
    };
  }

  // ==============================
  // COPY WITH
  // ==============================

  PipingItem copyWith({
    String? id,
    String? rawMaterialName,
    String? normalizedMaterialName,
    String? materialName,
    String? image,
    double? qty,
    String? uom,
    double? length,
    double? rmt,
    double? diameter,
    double? weight,
    double? power,
    String? floor,
    String? elevation,
    double? actualRate,
    double? rate,
    String? moc,
    String? size,
    String? location,
    String? plant,
    List<String>? designation,
    String? calculationCategory,
    String? remarks,
    List<DynamicField>? dynamicFields,
    bool? isFromRateFile,
    String? rateFileId,
    String? rateVariantId,
  }) {
    return PipingItem(
      id: id ?? this.id,
      rawMaterialName: rawMaterialName ?? this.rawMaterialName,
      normalizedMaterialName:
      normalizedMaterialName ?? this.normalizedMaterialName,
      materialName: materialName ?? this.materialName,
      image: image ?? this.image,
      qty: qty ?? this.qty,
      uom: uom ?? this.uom,
      length: length ?? this.length,
      rmt: rmt ?? this.rmt,
      diameter: diameter ?? this.diameter,
      weight: weight ?? this.weight,
      power: power ?? this.power,
      floor: floor ?? this.floor,
      elevation: elevation ?? this.elevation,
      actualRate: actualRate ?? this.actualRate,
      rate: rate ?? this.rate,
      moc: moc ?? this.moc,
      size: size ?? this.size,
      location: location ?? this.location,
      plant: plant ?? this.plant,
      designation: designation ?? this.designation,
      calculationCategory:
      calculationCategory ?? this.calculationCategory,
      remarks: remarks ?? this.remarks,
      dynamicFields: dynamicFields ?? this.dynamicFields,
      isFromRateFile: isFromRateFile ?? this.isFromRateFile,
      rateFileId: rateFileId ?? this.rateFileId,
      rateVariantId: rateVariantId ?? this.rateVariantId,
    );
  }

  // ==============================
  // EMPTY
  // ==============================

  static PipingItem empty() => const PipingItem(
    id: '',
    rawMaterialName: '',
    normalizedMaterialName: '',
    materialName: '',
    image: '',
    qty: 0,
    uom: '',
    length: 0,
    rmt: 0,
    diameter: 0,
    weight: 0,
    power: 0,
    floor: '',
    elevation: '',
    actualRate: 0,
    rate: 0,
    moc: '',
    size: '',
    location: '',
    plant: '',
    designation: [],
    calculationCategory: '',
    dynamicFields: [],
    remarks: '',
    isFromRateFile: false,
  );
  static PipingItem base({
    required String id,
    required String materialName,
    required String image,
    required String uom,
    required String calculationCategory,
    double actualRate = 0,
  }) {
    return PipingItem(
      id: id,
      rawMaterialName: materialName,
      normalizedMaterialName: materialName.toLowerCase().trim(),
      materialName: materialName,
      image: image,
      qty: 1,
      uom: uom,
      length: 0,
      rmt: 0,
      diameter: 0,
      weight: 0,
      power: 0,
      floor: '',
      elevation: '',
      actualRate: actualRate,
      rate: 0,
      moc: 'ms',
      size: 'ALL',
      location: 'sector 23',
      plant: 'plant',
      designation: const ['piping'],
      calculationCategory: calculationCategory,
      dynamicFields: const [],
      remarks: '',
      isFromRateFile: false,
    );
  }
}
