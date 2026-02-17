import 'package:untitled2/features/modules/all_Modules/dpr/models/rate_file_models.dart';

class PipingItem {
  final String id;
  final String materialName;
  final String image;
  final double qty;
  final String uom;
  final double length;
  final String floor;
  final String elevation;
  final double rmt;
  final double diameter;
  final double weight;
  final List<DynamicField> dynamicFields;

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

  /// 🔥 NEW – rate file tracking
  final bool isFromRateFile;
  final String? rateFileId;
  final String? rateVariantId;

  const PipingItem({
    required this.id,
    required this.materialName,
    required this.image,
    required this.qty,
    required this.uom,
    required this.length,
    required this.rmt,
    required this.diameter,
   this.floor='',
 this.elevation='',
    this.dynamicFields = const [],

    required this.weight,
    required this.power,
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
  factory PipingItem.fromJson(Map<String, dynamic> json) {
    return PipingItem(
      id: json['_id'] ?? json['id'] ?? '',
      materialName: json['materialName'] ?? '',
      image: json['image'] ?? '',
      floor: json['floor'] ?? '',
      elevation: json['elevation'] ?? '',
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
      location: json['location'] ?? '',
      plant: json['plant'] ?? '',
      designation: List<String>.from(json['designation'] ?? const []),
      calculationCategory: json['calculationCategory'] ?? '',
      remarks: json['remarks'] ?? '',

      // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐
      dynamicFields: (json['dynamicFields'] ?? [])
          .map<DynamicField>((e) => DynamicField.fromJson(e))
          .toList(),
      // ⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐⭐

      isFromRateFile: json['isFromRateFile'] ?? false,
      rateFileId: json['rateFileId'],
      rateVariantId: json['rateVariantId'],
    );
  }


  /// ✅ Convert RateFile → PipingItem
  factory PipingItem.fromRateMaterial(
      RateFileMaterial rateMaterial,
      RateVariant variant,
      ) {
    String size = '';
    if (variant.sizeRange != null) {
      final sr = variant.sizeRange!;
      size = '${sr['min'] ?? ''}-${sr['max'] ?? ''} ${sr['unit'] ?? ''}';
    }

    return PipingItem(
      id: rateMaterial.id,
      materialName: rateMaterial.MaterialName,
      image: rateMaterial.image,
      qty: 0,
      uom: variant.uom,
      length: 0,
      rmt: 0,
      dynamicFields: rateMaterial.dynamicFields,

      floor: variant.floor,
      elevation: variant.elevation,
      diameter: 0,
      weight: 0,
      power: 0,
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
      isFromRateFile: true,
      rateFileId: rateMaterial.id,
      rateVariantId: '',
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
      'floor': floor,
      'elevation': elevation,

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

  PipingItem copyWith({
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
    String? location,
    List<DynamicField>? dynamicFields,

    String? plant,
    List<String>? designation,
    String? calculationCategory,
    String? remarks,
    bool? isFromRateFile,
    String? rateFileId,
    String? rateVariantId,
    String? floor,
    String? elevation,

  }) {
    return PipingItem(
      id: id ?? this.id,
      materialName: materialName ?? this.materialName,
      image: image ?? this.image,
      qty: qty ?? this.qty,
      uom: uom ?? this.uom,
      length: length ?? this.length,
      rmt: rmt ?? this.rmt,
      dynamicFields: dynamicFields ?? this.dynamicFields,

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
      calculationCategory:

      calculationCategory ?? this.calculationCategory,
      floor: floor ?? this.floor,
      elevation: elevation ?? this.elevation,

      remarks: remarks ?? this.remarks,
      isFromRateFile: isFromRateFile ?? this.isFromRateFile,
      rateFileId: rateFileId ?? this.rateFileId,
      rateVariantId: rateVariantId ?? this.rateVariantId,
    );
  }
  static PipingItem empty() => const PipingItem(
    id: '',
    materialName: '',
    image: '',
    qty: 0,
    uom: '',
    length: 0,
    dynamicFields: const [],


    // ✅ REQUIRED
    floor: '',
    elevation: '',

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
