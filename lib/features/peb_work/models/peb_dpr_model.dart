class PebDprSetup {
  final String? id;
  final String workType;
  final String setupName;
  final String section;
  final List<PebSetupItem> items;
  final DateTime? createdAt;

  PebDprSetup({
    this.id,
    required this.workType,
    required this.setupName,
    required this.section,
    required this.items,
    this.createdAt,
  });

  factory PebDprSetup.fromJson(Map<String, dynamic> json) {
    return PebDprSetup(
      id: json['_id'],
      workType: json['workType'] ?? '',
      setupName: json['setupName'] ?? '',
      section: json['section'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => PebSetupItem.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workType': workType,
      'setupName': setupName,
      'section': section,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class PebSetupItem {
  final String itemCode;
  final String itemName;
  final String description;
  final String unit;
  final double targetQuantity;
  final String uom;
  final String? moc;
  final String? floor;
  final String? size;
  final String? thickness;
  final String? remarks;
  final List<String> images;

  PebSetupItem({
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.unit,
    required this.targetQuantity,
    required this.uom,
    this.moc,
    this.floor,
    this.size,
    this.thickness,
    this.remarks,
    this.images = const [],
  });

  factory PebSetupItem.fromJson(Map<String, dynamic> json) {
    return PebSetupItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      description: json['description'] ?? '',
      unit: json['unit'] ?? '',
      targetQuantity: (json['targetQuantity'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      moc: json['moc'],
      floor: json['floor'],
      size: json['size'],
      thickness: json['thickness'],
      remarks: json['remarks'],
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'description': description,
      'unit': unit,
      'targetQuantity': targetQuantity,
      'uom': uom,
      'moc': moc,
      'floor': floor,
      'size': size,
      'thickness': thickness,
      'remarks': remarks,
      'images': images,
    };
  }
}

class PebDprEntry {
  final String? id;
  final String workType;
  final String date;
  final String section;
  final List<PebDprItem> items;
  final DateTime? createdAt;

  PebDprEntry({
    this.id,
    required this.workType,
    required this.date,
    required this.section,
    required this.items,
    this.createdAt,
  });

  factory PebDprEntry.fromJson(Map<String, dynamic> json) {
    return PebDprEntry(
      id: json['_id'],
      workType: json['workType'] ?? '',
      date: json['date'] ?? '',
      section: json['section'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => PebDprItem.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workType': workType,
      'date': date,
      'section': section,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class PebDprItem {
  final String itemCode;
  final String itemName;
  final double actualQty;
  final String uom;
  final String? remarks;
  final List<String> progressPhotos;
  final String? assemblyMark;

  PebDprItem({
    required this.itemCode,
    required this.itemName,
    required this.actualQty,
    required this.uom,
    this.remarks,
    this.progressPhotos = const [],
    this.assemblyMark,
  });

  factory PebDprItem.fromJson(Map<String, dynamic> json) {
    return PebDprItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      actualQty: (json['actualQty'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      remarks: json['remarks'],
      progressPhotos: List<String>.from(json['progressPhotos'] ?? []),
      assemblyMark: json['assemblyMark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'actualQty': actualQty,
      'uom': uom,
      'remarks': remarks,
      'progressPhotos': progressPhotos,
      'assemblyMark': assemblyMark,
    };
  }
}
