class StructurePmResourceRow {
  final String id;
  final String unitCode;
  final String unitName;
  final String categoryName;
  final String resourceName;
  final String uom;
  final double requiredQty;
  final double actualQty;
  final double gap;
  final String remarks;
  final int templateRowNo;
  final int sortOrder;

  const StructurePmResourceRow({
    required this.id,
    required this.unitCode,
    required this.unitName,
    required this.categoryName,
    required this.resourceName,
    required this.uom,
    required this.requiredQty,
    required this.actualQty,
    required this.gap,
    required this.remarks,
    required this.templateRowNo,
    required this.sortOrder,
  });

  factory StructurePmResourceRow.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StructurePmResourceRow(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      unitCode: (json['unitCode'] ?? '').toString(),
      unitName: (json['unitName'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      resourceName: (json['resourceName'] ?? '').toString(),
      uom: (json['uom'] ?? '').toString(),
      requiredQty: toDouble(json['requiredQty']),
      actualQty: toDouble(json['actualQty']),
      gap: toDouble(json['gap']),
      remarks: (json['remarks'] ?? '').toString(),
      templateRowNo:
          int.tryParse((json['templateRowNo'] ?? 0).toString()) ?? 0,
      sortOrder: int.tryParse((json['sortOrder'] ?? 0).toString()) ?? 0,
    );
  }

  StructurePmResourceRow copyWith({
    double? actualQty,
    String? remarks,
  }) {
    final nextActual = actualQty ?? this.actualQty;
    return StructurePmResourceRow(
      id: id,
      unitCode: unitCode,
      unitName: unitName,
      categoryName: categoryName,
      resourceName: resourceName,
      uom: uom,
      requiredQty: requiredQty,
      actualQty: nextActual,
      gap: requiredQty - nextActual,
      remarks: remarks ?? this.remarks,
      templateRowNo: templateRowNo,
      sortOrder: sortOrder,
    );
  }
}

class StructurePmUnitSummary {
  final String unitCode;
  final String unitName;
  final double requiredQty;
  final double actualQty;
  final double gap;

  const StructurePmUnitSummary({
    required this.unitCode,
    required this.unitName,
    required this.requiredQty,
    required this.actualQty,
    required this.gap,
  });

  factory StructurePmUnitSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StructurePmUnitSummary(
      unitCode: (json['unitCode'] ?? '').toString(),
      unitName: (json['unitName'] ?? '').toString(),
      requiredQty: toDouble(json['required']),
      actualQty: toDouble(json['actual']),
      gap: toDouble(json['gap']),
    );
  }
}

class StructurePmSummary {
  final double totalRequired;
  final double totalActual;
  final double totalGap;
  final int totalCategories;
  final int totalResources;
  final int filledResources;
  final int pendingResources;
  final List<StructurePmUnitSummary> unitSummary;

  const StructurePmSummary({
    required this.totalRequired,
    required this.totalActual,
    required this.totalGap,
    required this.totalCategories,
    required this.totalResources,
    required this.filledResources,
    required this.pendingResources,
    required this.unitSummary,
  });

  factory StructurePmSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StructurePmSummary(
      totalRequired: toDouble(json['totalRequired']),
      totalActual: toDouble(json['totalActual']),
      totalGap: toDouble(json['totalGap']),
      totalCategories:
          int.tryParse((json['totalCategories'] ?? 0).toString()) ?? 0,
      totalResources:
          int.tryParse((json['totalResources'] ?? 0).toString()) ?? 0,
      filledResources:
          int.tryParse((json['filledResources'] ?? 0).toString()) ?? 0,
      pendingResources:
          int.tryParse((json['pendingResources'] ?? 0).toString()) ?? 0,
      unitSummary: ((json['unitSummary'] as List?) ?? [])
          .map((e) =>
              StructurePmUnitSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static const empty = StructurePmSummary(
    totalRequired: 0,
    totalActual: 0,
    totalGap: 0,
    totalCategories: 0,
    totalResources: 0,
    filledResources: 0,
    pendingResources: 0,
    unitSummary: [],
  );
}

class StructurePmEntryData {
  final String date;
  final List<StructurePmResourceRow> rows;
  final StructurePmSummary summary;

  const StructurePmEntryData({
    required this.date,
    required this.rows,
    required this.summary,
  });

  factory StructurePmEntryData.fromJson(Map<String, dynamic> json) {
    return StructurePmEntryData(
      date: (json['date'] ?? '').toString(),
      rows: ((json['rows'] as List?) ?? [])
          .map((e) =>
              StructurePmResourceRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: StructurePmSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}
