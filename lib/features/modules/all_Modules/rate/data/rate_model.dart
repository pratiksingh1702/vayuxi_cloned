class RateUploadModel {
  final String? id;
  final String workType;
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final String fileType;
  final List<RateItem> items;
  final DateTime? createdAt;

  RateUploadModel({
    this.id,
    required this.workType,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    required this.items,
    this.createdAt,
  });

  factory RateUploadModel.fromJson(Map<String, dynamic> json) {
    return RateUploadModel(
      id: json['_id'],
      workType: json['workType'] ?? '',
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      fileType: json['fileType'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => RateItem.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workType': workType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'fileType': fileType,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

class RateItem {
  final String itemCode;
  final String itemName;
  final String specification;
  final String unit;
  final double rate;
  final String? moc;
  final String? size;
  final String? thickness;
  final String? floor;

  RateItem({
    required this.itemCode,
    required this.itemName,
    required this.specification,
    required this.unit,
    required this.rate,
    this.moc,
    this.size,
    this.thickness,
    this.floor,
  });

  factory RateItem.fromJson(Map<String, dynamic> json) {
    return RateItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      specification: json['specification'] ?? '',
      unit: json['unit'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      moc: json['moc'],
      size: json['size'],
      thickness: json['thickness'],
      floor: json['floor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'specification': specification,
      'unit': unit,
      'rate': rate,
      'moc': moc,
      'size': size,
      'thickness': thickness,
      'floor': floor,
    };
  }
}
