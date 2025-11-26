class PipingItem {
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
  final String? remarks;

  PipingItem({
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
    this.remarks
  });

  factory PipingItem.fromJson(Map<String, dynamic> json) {
    // Safe parsing helper functions
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Handle empty strings or invalid numbers
        final cleaned = value.trim();
        if (cleaned.isEmpty) return 0.0;
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      return value.toString().trim();
    }

    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.whereType<String>().map((e) => e.trim()).toList();
      }
      return [];
    }

    return PipingItem(
      id: safeString(json['_id']),
      materialName: safeString(json['materialName']),
      image: safeString(json['image']),
      qty: safeDouble(json['qty']),
      uom: safeString(json['uom']),
      length: safeDouble(json['length']),
      rmt: safeDouble(json['rmt']),
      diameter: safeDouble(json['diameter']),
      weight: safeDouble(json['weight']),
      power: safeDouble(json['power']),
      actualRate: safeDouble(json['actualRate']),
      rate: safeDouble(json['rate']),
      moc: safeString(json['moc']),
      size: safeString(json['size']),
      location: safeString(json['location']),
      plant: safeString(json['plant']),
      designation: safeStringList(json['designation']),
      remarks: json['remarks'] != null ? safeString(json['remarks']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
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
    'remarks': remarks,
  };

  // Helper method for empty instance
  factory PipingItem.empty() => PipingItem(
    id: '',
    materialName: '',
    image: '',
    qty: 0.0,
    uom: '',
    length: 0.0,
    rmt: 0.0,
    diameter: 0.0,
    weight: 0.0,
    power: 0.0,
    actualRate: 0.0,
    rate: 0.0,
    moc: '',
    size: '',
    location: '',
    plant: '',
    designation: [],
    remarks: null,
  );
}