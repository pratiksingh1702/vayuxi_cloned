class DPRStructureItem {
  final String id;
  final String assemblyMark;
  final double qtyUsed;
  final double? netWeightPerUnit;
  final double? totalNetWeight;
  final String? boqItemId;
  final double? length;
  final double? width;
  final double? height;
  final double? availableQty;
  final double? remainingQty;

  DPRStructureItem({
    required this.id,
    required this.assemblyMark,
    required this.qtyUsed,
    this.netWeightPerUnit,
    this.totalNetWeight,
    this.boqItemId,
    this.length,
    this.width,
    this.height,
    this.availableQty,
    this.remainingQty,
  });

  factory DPRStructureItem.fromJson(Map<String, dynamic> json) {
    return DPRStructureItem(
      id: json['_id']?.toString() ?? '',
      assemblyMark: json['assemblyMark']?.toString() ?? '',
      qtyUsed: (json['qtyUsed'] as num?)?.toDouble() ?? 0,
      netWeightPerUnit: (json['netWeightPerUnit'] as num?)?.toDouble(),
      totalNetWeight: (json['totalNetWeight'] as num?)?.toDouble(),
      boqItemId: json['boqItemId']?.toString(),
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      availableQty: (json['availableQty'] as num?)?.toDouble(),
      remainingQty: (json['remainingQty'] as num?)?.toDouble(),
    );
  }
}

class _BOQRef {
  final String id;
  final String boqName;
  final String? boqNumber;
  _BOQRef({required this.id, required this.boqName, this.boqNumber});
}

class DPRStructure {
  final String id;
  final String dprName;
  final String dprNumber;
  final String? siteId;
  final String? siteName;
  final String? boqId;
  final String? boqName;
  final String? boqNumber;
  final String? teamId;
  final String? teamName;
  final List<DPRStructureItem> items;
  final double totalQtyUsed;
  final double totalNetWeight;
  final DateTime? date;
  final String status;
  final String? remarks;
  final String? createdByName;

  DPRStructure({
    required this.id,
    required this.dprName,
    required this.dprNumber,
    this.siteId,
    this.siteName,
    this.boqId,
    this.boqName,
    this.boqNumber,
    this.teamId,
    this.teamName,
    required this.items,
    required this.totalQtyUsed,
    required this.totalNetWeight,
    this.date,
    required this.status,
    this.remarks,
    this.createdByName,
  });

  factory DPRStructure.fromJson(Map<String, dynamic> json) {
    // BOQ
    final boqData = json['boqId'];
    String? boqId, boqName, boqNumber;
    if (boqData is Map) {
      boqId = boqData['_id']?.toString();
      boqName = boqData['boqName']?.toString();
      boqNumber = boqData['boqNumber']?.toString();
    } else {
      boqId = boqData?.toString();
    }

    // Site
    final siteData = json['siteId'];
    String? siteId, siteName;
    if (siteData is Map) {
      siteId = siteData['_id']?.toString();
      siteName = siteData['siteName']?.toString();
    } else {
      siteId = siteData?.toString();
    }

    // Team
    final teamData = json['teamId'];
    String? teamId, teamName;
    if (teamData is Map) {
      teamId = teamData['_id']?.toString();
      teamName = teamData['teamName']?.toString();
    } else {
      teamId = teamData?.toString();
    }

    // createdBy
    final createdByData = json['createdBy'];
    String? createdByName;
    if (createdByData is Map) {
      createdByName = createdByData['fullName']?.toString();
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => DPRStructureItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DPRStructureItem>[];

    DateTime? date;
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date'].toString());
      } catch (_) {}
    }

    return DPRStructure(
      id: json['_id']?.toString() ?? '',
      dprName: json['dprName']?.toString() ?? '',
      dprNumber: json['dprNumber']?.toString() ?? '',
      siteId: siteId,
      siteName: siteName,
      boqId: boqId,
      boqName: boqName,
      boqNumber: boqNumber,
      teamId: teamId,
      teamName: teamName,
      items: items,
      totalQtyUsed: (json['totalQtyUsed'] as num?)?.toDouble() ?? 0,
      totalNetWeight: (json['totalNetWeight'] as num?)?.toDouble() ?? 0,
      date: date,
      status: json['status']?.toString() ?? 'submitted',
      remarks: json['remarks']?.toString(),
      createdByName: createdByName,
    );
  }
}
