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
    required this.actualRate,
    required this.rate,
    required this.moc,
    required this.size,
    required this.location,
    required this.plant,
    required this.designation,
    required this.calculationCategory,
    this.remarks = '',
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
      location: json['location'] ?? '',
      plant: json['plant'] ?? '',
      designation: List<String>.from(json['designation'] ?? const []),
      calculationCategory: json['calculationCategory'] ?? '',
      remarks: json['remarks'] ?? '',
    );
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
    String? location,
    String? plant,
    List<String>? designation,
    String? calculationCategory,
    String? remarks,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      materialName: materialName ?? this.materialName,
      image: image ?? this.image,
      qty: qty ?? this.qty,
      uom: uom ?? this.uom,
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
      calculationCategory:
      calculationCategory ?? this.calculationCategory,
      remarks: remarks ?? this.remarks,
    );
  }

  static EquipmentItem empty() => const EquipmentItem(
    id: '',
    materialName: '',
    image: '',
    qty: 0,
    uom: '',
    length: 0,
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
  );
}
