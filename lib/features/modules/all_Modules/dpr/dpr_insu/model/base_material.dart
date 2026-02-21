abstract class BaseMaterial {
  final String id; // ✅ identity belongs in base

  final String name;
  final List<String> image;
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
  final String remarks;
  final String uom;

  const BaseMaterial({
    required this.id,
    required this.name,
    required this.image,
    required this.qty,
    required this.length,
    required this.circumference,
    required this.circumference1,
    required this.circumference2,
    required this.zHeight,
    required this.gSlantHeight,
    required this.constant,
    required this.totalArea,
    required this.diameterA3,
    required this.diameterB3,
    required this.diameterA2,
    required this.diameterB2,
    required this.diameterA1,
    required this.diameterB1,
    required this.circumferenceFinal,
    required this.layer1Area,
    required this.layer2Area,
    required this.layer3Area,
    required this.circumference3,
    required this.circumference2Calc,
    required this.circumference1Calc,
    required this.o3,
    required this.o2,
    required this.o1,
    required this.remarks,
    required this.uom,
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
    String? remarks,
    String? uom,
  });
}
