class DPRStructureItem {
  final String id;
  final String assemblyMark;
  final double qtyUsed;
  final double? netWeightPerUnit;
  final double? totalNetWeight;
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
    this.length,
    this.width,
    this.height,
    this.availableQty,
    this.remainingQty,
  });

  factory DPRStructureItem.fromJson(Map<String, dynamic> json) {
    final actualQty = (json['actualQty'] as num?)?.toDouble();
    final estimatedWeightPerUnitKg =
        (json['estimatedWeightPerUnitKg'] as num?)?.toDouble();
    final parsedTotalWeight = _readWeightKg(json);
    return DPRStructureItem(
      id: json['_id']?.toString() ?? '',
      assemblyMark: json['assemblyMark']?.toString() ?? '',
      qtyUsed: (json['qtyUsed'] as num?)?.toDouble() ?? actualQty ?? 0,
      netWeightPerUnit: (json['netWeightPerUnit'] as num?)?.toDouble() ??
          estimatedWeightPerUnitKg,
      totalNetWeight: parsedTotalWeight,
      length: (json['length'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      availableQty: (json['availableQty'] as num?)?.toDouble(),
      remainingQty: (json['remainingQty'] as num?)?.toDouble(),
    );
  }
}

double? _readWeightKg(Map<String, dynamic> json) {
  for (final key in [
    'totalNetWeight',
    'totalWeightKg',
    'manualWeightKg',
    'totalWeight',
    'weightKg',
    'weight',
  ]) {
    final value = json[key];
    if (value is num && value > 0) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null && parsed > 0) return parsed;
  }

  final qty = (json['actualQty'] as num?)?.toDouble() ??
      (json['qtyUsed'] as num?)?.toDouble() ??
      0;
  final perUnit = (json['estimatedWeightPerUnitKg'] as num?)?.toDouble() ??
      (json['netWeightPerUnit'] as num?)?.toDouble() ??
      0;
  final calculated = qty * perUnit;
  return calculated > 0 ? calculated : null;
}

class DPRStructure {
  final String id;
  final String dprName;
  final String dprNumber;
  final String? siteId;
  final String? siteName;
  final String? company;
  final String? type;
  final List<DPRStructureItem> items;
  final double totalQtyUsed;
  final double totalNetWeight;
  final DateTime? date;
  final String status;
  final String? remarks;
  final String? createdByName;
  final DateTime? createdAt;
  final String? teamId;
  final String? teamName;
  final String? plant;
  final String? location;
  final String? moc;
  final double? size;
  final String? unit;
  final DateTime? updatedAt;

  DPRStructure({
    required this.id,
    required this.dprName,
    required this.dprNumber,
    this.siteId,
    this.siteName,
    this.company,
    this.type,
    required this.items,
    required this.totalQtyUsed,
    required this.totalNetWeight,
    this.date,
    required this.status,
    this.remarks,
    this.createdByName,
    this.createdAt,
    this.teamId,
    this.teamName,
    this.plant,
    this.location,
    this.moc,
    this.size,
    this.unit,
    this.updatedAt,
  });

  factory DPRStructure.fromJson(Map<String, dynamic> json) {
    // Site Handling
    final siteData = json['siteId'];
    String? sId, sName;
    if (siteData is Map) {
      sId = siteData['_id']?.toString();
      sName = siteData['siteName']?.toString();
    } else {
      sId = siteData?.toString();
    }

    // Team Handling
    final teamData = json['teamId'];
    String? tId, tName;
    if (teamData is Map) {
      tId = teamData['_id']?.toString();
      tName = teamData['teamName']?.toString();
    } else {
      tId = teamData?.toString();
    }

    // CreatedBy Handling
    final createdByData = json['createdBy'];
    String? cByName;
    if (createdByData is Map) {
      cByName = createdByData['fullName']?.toString();
    }

    final rawItems = json['items'];
    final itemsList = rawItems is List
        ? rawItems
            .map((e) => DPRStructureItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DPRStructureItem>[];

    DateTime? dprDate;
    if (json['date'] != null) {
      try {
        dprDate = DateTime.parse(json['date'].toString());
      } catch (_) {}
    }

    DateTime? createdDate;
    if (json['createdAt'] != null) {
      try {
        createdDate = DateTime.parse(json['createdAt'].toString());
      } catch (_) {}
    }

    DateTime? updatedDate;
    if (json['updatedAt'] != null) {
      try {
        updatedDate = DateTime.parse(json['updatedAt'].toString());
      } catch (_) {}
    }

    return DPRStructure(
      id: json['_id']?.toString() ?? '',
      dprName: json['dprName']?.toString() ?? '',
      dprNumber: json['dprNumber']?.toString() ?? '',
      siteId: sId,
      siteName: sName,
      company: json['company']?.toString(),
      type: json['type']?.toString(),
      items: itemsList,
      totalQtyUsed: (json['totalQtyUsed'] as num?)?.toDouble() ?? 0,
      totalNetWeight: (json['totalNetWeight'] as num?)?.toDouble() ?? 0,
      date: dprDate,
      status: json['status']?.toString() ?? 'submitted',
      remarks: json['remarks']?.toString(),
      createdByName: cByName,
      createdAt: createdDate,
      teamId: tId,
      teamName: tName,
      plant: json['plant']?.toString(),
      location: json['location']?.toString(),
      moc: json['moc']?.toString(),
      size: (json['size'] as num?)?.toDouble(),
      unit: json['unit']?.toString(),
      updatedAt: updatedDate,
    );
  }
}
