class BOQStructureItem {
  final String id;
  final String assemblyMark;
  final double quantity;
  final double availableQty;
  final double? length;
  final double? width;
  final double? height;
  final double? netWeightPerUnit;
  final double? totalNetWeight;
  final double usedQty;
  final double remainingQty;
  final double progressPercentage;

  BOQStructureItem({
    required this.id,
    required this.assemblyMark,
    required this.quantity,
    required this.availableQty,
    this.length,
    this.width,
    this.height,
    this.netWeightPerUnit,
    this.totalNetWeight,
    required this.usedQty,
    required this.remainingQty,
    required this.progressPercentage,
  });

  factory BOQStructureItem.fromJson(Map<String, dynamic> json) {
    return BOQStructureItem(
      id: json['_id']?.toString() ?? '',
      assemblyMark: json['assemblyMark']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      availableQty: (json['availableQty'] as num?)?.toDouble() ?? 0,
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      netWeightPerUnit: (json['netWeightPerUnit'] as num?)?.toDouble(),
      totalNetWeight: (json['totalNetWeight'] as num?)?.toDouble(),
      usedQty: (json['usedQty'] as num?)?.toDouble() ?? 0,
      remainingQty: (json['remainingQty'] as num?)?.toDouble() ?? 0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BOQStructure {
  final String id;
  final String boqName;
  final String boqNumber;
  final String? siteId;
  final String? siteName;
  final List<BOQStructureItem> items;
  final double totalQuantity;
  final double totalNetWeight;
  final int totalItems;
  final double usedQuantity;
  final double remainingQuantity;
  final double progressPercentage;
  final String status;
  final String? uploadedAt;

  BOQStructure({
    required this.id,
    required this.boqName,
    required this.boqNumber,
    this.siteId,
    this.siteName,
    required this.items,
    required this.totalQuantity,
    required this.totalNetWeight,
    required this.totalItems,
    required this.usedQuantity,
    required this.remainingQuantity,
    required this.progressPercentage,
    required this.status,
    this.uploadedAt,
  });

  factory BOQStructure.fromJson(Map<String, dynamic> json) {
    final siteData = json['siteId'];
    String? siteId;
    String? siteName;
    if (siteData is Map) {
      siteId = siteData['_id']?.toString();
      siteName = siteData['siteName']?.toString();
    } else {
      siteId = siteData?.toString();
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => BOQStructureItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <BOQStructureItem>[];

    return BOQStructure(
      id: json['_id']?.toString() ?? '',
      boqName: json['boqName']?.toString() ?? '',
      boqNumber: json['boqNumber']?.toString() ?? '',
      siteId: siteId,
      siteName: siteName,
      items: items,
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0,
      totalNetWeight: (json['totalNetWeight'] as num?)?.toDouble() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      usedQuantity: (json['usedQuantity'] as num?)?.toDouble() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'active',
      uploadedAt: json['uploadedAt']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  BOQStructure copyWith({
    List<BOQStructureItem>? items,
    double? usedQuantity,
    double? remainingQuantity,
    double? progressPercentage,
  }) {
    return BOQStructure(
      id: id,
      boqName: boqName,
      boqNumber: boqNumber,
      siteId: siteId,
      siteName: siteName,
      items: items ?? this.items,
      totalQuantity: totalQuantity,
      totalNetWeight: totalNetWeight,
      totalItems: totalItems,
      usedQuantity: usedQuantity ?? this.usedQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status,
      uploadedAt: uploadedAt,
    );
  }
}
