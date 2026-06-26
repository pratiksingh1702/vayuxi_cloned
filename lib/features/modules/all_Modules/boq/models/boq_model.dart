// ─────────────────────────────────────────────────────────────────────────────
// BOQ MODELS
// Matches backend API responses exactly.
// ─────────────────────────────────────────────────────────────────────────────

// ── BOQ List Item (from GET /api/v1/site/:site/boq) ────────────────────────

class BoqListItem {
  final String id;
  final String boqNumber;
  final String boqName;
  final String type; // "mechanical_work" | "insulation_piping"
  final double totalQuantity;
  final double? totalInchDia;
  final double? totalInchMtr;
  final double? totalRMT;
  final double? totalArea;
  final int? totalItems;
  final String status; // "draft" | "active" | "completed"
  final double progressPercentage;
  final String createdAt;

  const BoqListItem({
    required this.id,
    required this.boqNumber,
    required this.boqName,
    required this.type,
    required this.totalQuantity,
    this.totalInchDia,
    this.totalInchMtr,
    this.totalRMT,
    this.totalArea,
    this.totalItems,
    required this.status,
    required this.progressPercentage,
    required this.createdAt,
  });

  factory BoqListItem.fromJson(Map<String, dynamic> json) {
    return BoqListItem(
      id: json['_id'] as String,
      boqNumber: json['boqNumber'] as String? ?? '',
      boqName: json['boqName'] as String? ?? '',
      type: json['type'] as String? ?? 'mechanical_work',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      totalInchDia: (json['totalInchDia'] as num?)?.toDouble(),
      totalInchMtr: (json['totalInchMtr'] as num?)?.toDouble(),
      totalRMT: (json['totalRMT'] as num?)?.toDouble(),
      totalArea: (json['totalArea'] as num?)?.toDouble(),
      totalItems: json['totalItems'] as int?,
      status: json['status'] as String? ?? 'active',
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  bool get isMechanical => type == 'mechanical_work';
  bool get isInsulation => type == 'insulation_piping';
}

// ── BOQ Pagination ──────────────────────────────────────────────────────────

class BoqPagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  const BoqPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory BoqPagination.fromJson(Map<String, dynamic> json) {
    return BoqPagination(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
      pages: json['pages'] as int? ?? 1,
    );
  }
}

// ── BOQ Detail Item (mechanical) ────────────────────────────────────────────

class MechanicalBoqItem {
  final String id;
  final int srNo;
  final String inputMaterialName;
  final String matchedMaterialName;
  final double size;
  final double? quantity;
  final double? length;
  final String? calculationCategory; // "A" (qty) or "B" (length)
  final String? uom; // "INCH_DIA" | "INCH_MTR"
  final double totalQuantityCalculated;
  final double completedQuantity;
  final double remainingQuantity;
  final double progressPercentage;
  final String? remarks;
  final String? drawingNo;
  final String? workDescription;
  final String? itemType;
  final String? itemSize;
  final String? parentHeader;
  final int? sourceRowNo;
  final int? sourceColumnNo;
  final String? sourceHeader;
  final String? boqGroupKey;
  final String? boqItemKey;
  final String? moc;
  final String? sch;
  final String? spec;

  const MechanicalBoqItem({
    required this.id,
    required this.srNo,
    required this.inputMaterialName,
    required this.matchedMaterialName,
    required this.size,
    this.quantity,
    this.length,
    this.calculationCategory,
    this.uom,
    required this.totalQuantityCalculated,
    required this.completedQuantity,
    required this.remainingQuantity,
    required this.progressPercentage,
    this.remarks,
    this.drawingNo,
    this.workDescription,
    this.itemType,
    this.itemSize,
    this.parentHeader,
    this.sourceRowNo,
    this.sourceColumnNo,
    this.sourceHeader,
    this.boqGroupKey,
    this.boqItemKey,
    this.moc,
    this.sch,
    this.spec,
  });

  factory MechanicalBoqItem.fromJson(Map<String, dynamic> json) {
    return MechanicalBoqItem(
      id: (json['_id'] ??
              json['id'] ??
              json['boqItemKey'] ??
              '${json['sourceRowNo'] ?? ''}-${json['sourceColumnNo'] ?? ''}-${json['srNo'] ?? ''}')
          .toString(),
      srNo: (json['srNo'] as num?)?.toInt() ?? 0,
      inputMaterialName: json['inputMaterialName'] as String? ?? '',
      matchedMaterialName: json['matchedMaterialName'] as String? ?? '',
      size: (json['size'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble(),
      length: (json['length'] as num?)?.toDouble(),
      calculationCategory: json['calculationCategory'] as String?,
      uom: json['uom'] as String?,
      totalQuantityCalculated:
          (json['totalQuantityCalculated'] as num?)?.toDouble() ?? 0.0,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] as String?,
      drawingNo: json['drawingNo'] as String?,
      workDescription: json['workDescription'] as String?,
      itemType: json['itemType'] as String?,
      itemSize: json['itemSize']?.toString(),
      parentHeader: json['parentHeader'] as String?,
      sourceRowNo: (json['sourceRowNo'] as num?)?.toInt(),
      sourceColumnNo: (json['sourceColumnNo'] as num?)?.toInt(),
      sourceHeader: json['sourceHeader'] as String?,
      boqGroupKey: json['boqGroupKey'] as String?,
      boqItemKey: json['boqItemKey'] as String?,
      moc: json['moc'] as String?,
      sch: json['sch'] as String?,
      spec: json['spec'] as String?,
    );
  }

  bool get isPipeItem => displayUom == 'MTR';

  String get displayUom =>
      (uom ?? (length != null ? 'MTR' : 'NOS')).toUpperCase();

  String get displaySize {
    final value = itemSize?.trim();
    if (value != null && value.isNotEmpty) return value;
    return size % 1 == 0 ? size.toStringAsFixed(0) : size.toString();
  }

  String get displayDescription {
    final value = itemType?.trim();
    if (value != null && value.isNotEmpty) return value;
    if (matchedMaterialName.trim().isNotEmpty) return matchedMaterialName;
    if (inputMaterialName.trim().isNotEmpty) return inputMaterialName;
    return workDescription?.trim().isNotEmpty == true
        ? workDescription!.trim()
        : 'BOQ Item';
  }

  Map<String, dynamic> toJson() => {
        'materialName': matchedMaterialName,
        'size': size,
        if (quantity != null) 'quantity': quantity,
        if (length != null) 'length': length,
        if (remarks != null) 'remarks': remarks,
      };
}

class MechanicalBoqGroup {
  final String drawingNo;
  final String workDescription;
  final List<MechanicalBoqItem> items;

  const MechanicalBoqGroup({
    required this.drawingNo,
    required this.workDescription,
    required this.items,
  });

  factory MechanicalBoqGroup.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return MechanicalBoqGroup(
      drawingNo: json['drawingNo'] as String? ?? '',
      workDescription: json['workDescription'] as String? ?? '',
      items: rawItems
          .map((e) => MechanicalBoqItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── BOQ Detail Item (insulation) ────────────────────────────────────────────

class InsulationBoqItem {
  final int srNo;
  final String materialName;
  final double size;
  final String sizeUom;
  final double qty;
  final String layer; // "single" | "double" | "triple"
  final String leggingMaterial1;
  final double leggingThickness1;
  final String? leggingMaterial2;
  final double? leggingThickness2;
  final String? leggingMaterial3;
  final double? leggingThickness3;
  final String claddingMaterial;
  final int claddingSwg;
  final double? userProvidedRMT;
  final double? userProvidedArea;
  final double calculatedRMT;
  final double calculatedArea;
  final double completedQuantity;
  final double progressPercentage;
  final String? remarks;

  const InsulationBoqItem({
    required this.srNo,
    required this.materialName,
    required this.size,
    required this.sizeUom,
    required this.qty,
    required this.layer,
    required this.leggingMaterial1,
    required this.leggingThickness1,
    this.leggingMaterial2,
    this.leggingThickness2,
    this.leggingMaterial3,
    this.leggingThickness3,
    required this.claddingMaterial,
    required this.claddingSwg,
    this.userProvidedRMT,
    this.userProvidedArea,
    required this.calculatedRMT,
    required this.calculatedArea,
    required this.completedQuantity,
    required this.progressPercentage,
    this.remarks,
  });

  factory InsulationBoqItem.fromJson(Map<String, dynamic> json) {
    return InsulationBoqItem(
      srNo: json['srNo'] as int? ?? 0,
      materialName:
          (json['materialName'] ?? json['inputMaterialName'] ?? '') as String,
      size: (json['size'] as num?)?.toDouble() ?? 0.0,
      sizeUom: json['sizeUom'] as String? ?? 'inch',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      layer: json['layer'] as String? ?? 'single',
      leggingMaterial1: json['legging_material_1'] as String? ?? '',
      leggingThickness1:
          (json['legging_thickness_1'] as num?)?.toDouble() ?? 0.0,
      leggingMaterial2: json['legging_material_2'] as String?,
      leggingThickness2: (json['legging_thickness_2'] as num?)?.toDouble(),
      leggingMaterial3: json['legging_material_3'] as String?,
      leggingThickness3: (json['legging_thickness_3'] as num?)?.toDouble(),
      claddingMaterial: json['cladding_material'] as String? ?? '',
      claddingSwg: json['cladding_swg'] as int? ?? 24,
      userProvidedRMT: (json['userProvidedRMT'] as num?)?.toDouble(),
      userProvidedArea: (json['userProvidedArea'] as num?)?.toDouble(),
      calculatedRMT:
          (json['calculatedRMT'] ?? json['rmt'] as num?)?.toDouble() ?? 0.0,
      calculatedArea:
          (json['calculatedArea'] ?? json['area'] as num?)?.toDouble() ?? 0.0,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'materialName': materialName,
        'size': size,
        'sizeUom': sizeUom,
        'qty': qty,
        'layer': layer,
        'legging_material_1': leggingMaterial1,
        'legging_thickness_1': leggingThickness1,
        if (leggingMaterial2 != null) 'legging_material_2': leggingMaterial2,
        if (leggingThickness2 != null) 'legging_thickness_2': leggingThickness2,
        if (leggingMaterial3 != null) 'legging_material_3': leggingMaterial3,
        if (leggingThickness3 != null) 'legging_thickness_3': leggingThickness3,
        'cladding_material': claddingMaterial,
        'cladding_swg': claddingSwg,
        if (userProvidedRMT != null) 'userProvidedRMT': userProvidedRMT,
        if (userProvidedArea != null) 'userProvidedArea': userProvidedArea,
        if (remarks != null) 'remarks': remarks,
      };
}

// ── BOQ Full Detail ─────────────────────────────────────────────────────────

class BoqDetail {
  final String id;
  final String boqNumber;
  final String boqName;
  final String type;
  final String status;
  final double totalQuantity;
  final double? totalInchDia;
  final double? totalInchMtr;
  final double? totalRMT;
  final double? totalArea;
  final int? totalItems;
  final double completedQuantity;
  final double remainingQuantity;
  final double progressPercentage;
  final String? varianceStatus;
  final List<MechanicalBoqItem> mechanicalItems;
  final List<MechanicalBoqGroup> mechanicalGroups;
  final List<InsulationBoqItem> insulationItems;
  final String? uploadMethod;
  final String? lastSyncedAt;

  const BoqDetail({
    required this.id,
    required this.boqNumber,
    required this.boqName,
    required this.type,
    required this.status,
    required this.totalQuantity,
    this.totalInchDia,
    this.totalInchMtr,
    this.totalRMT,
    this.totalArea,
    this.totalItems,
    required this.completedQuantity,
    required this.remainingQuantity,
    required this.progressPercentage,
    this.varianceStatus,
    required this.mechanicalItems,
    this.mechanicalGroups = const [],
    required this.insulationItems,
    this.uploadMethod,
    this.lastSyncedAt,
  });

  factory BoqDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final rawGroups = json['mechanicalGroups'] as List<dynamic>? ?? [];
    final isMech = (json['type'] as String?) == 'mechanical_work';
    final mechanicalItems = isMech
        ? rawItems
            .map((e) => MechanicalBoqItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <MechanicalBoqItem>[];
    final groups = rawGroups
        .map((e) => MechanicalBoqGroup.fromJson(e as Map<String, dynamic>))
        .toList();

    return BoqDetail(
      id: json['_id'] as String,
      boqNumber: json['boqNumber'] as String? ?? '',
      boqName: json['boqName'] as String? ?? '',
      type: json['type'] as String? ?? 'mechanical_work',
      status: json['status'] as String? ?? 'active',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      totalInchDia: (json['totalInchDia'] as num?)?.toDouble(),
      totalInchMtr: (json['totalInchMtr'] as num?)?.toDouble(),
      totalRMT: (json['totalRMT'] as num?)?.toDouble(),
      totalArea: (json['totalArea'] as num?)?.toDouble(),
      totalItems: json['totalItems'] as int?,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      varianceStatus: json['varianceStatus'] as String?,
      mechanicalItems: mechanicalItems,
      mechanicalGroups: groups.isNotEmpty
          ? groups
          : mechanicalItems
              .map((item) => MechanicalBoqGroup(
                    drawingNo: item.drawingNo ?? '',
                    workDescription: item.workDescription ?? '',
                    items: [item],
                  ))
              .toList(),
      insulationItems: !isMech
          ? rawItems
              .map((e) => InsulationBoqItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      uploadMethod: json['uploadMethod'] as String?,
      lastSyncedAt: json['lastSyncedAt'] as String?,
    );
  }

  bool get isMechanical => type == 'mechanical_work';
  bool get isInsulation => type == 'insulation_piping';
}

// ── BOQ Progress ────────────────────────────────────────────────────────────

class BoqTopMaterial {
  final String materialName;
  final double totalQuantity;
  final double completedQuantity;
  final double progressPercentage;

  const BoqTopMaterial({
    required this.materialName,
    required this.totalQuantity,
    required this.completedQuantity,
    required this.progressPercentage,
  });

  factory BoqTopMaterial.fromJson(Map<String, dynamic> json) {
    return BoqTopMaterial(
      materialName: json['materialName'] as String? ?? '',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BoqDailyTarget {
  final String date;
  final double targetQuantity;
  final double completedQuantity;
  final double remainingQuantity;
  final double progressPercentage;
  final String status; // "pending" | "in_progress" | "completed"

  const BoqDailyTarget({
    required this.date,
    required this.targetQuantity,
    required this.completedQuantity,
    required this.remainingQuantity,
    required this.progressPercentage,
    required this.status,
  });

  factory BoqDailyTarget.fromJson(Map<String, dynamic> json) {
    return BoqDailyTarget(
      date: json['date'] as String? ?? '',
      targetQuantity: (json['targetQuantity'] as num?)?.toDouble() ?? 0.0,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class BoqTimeline {
  final String startDate;
  final String endDate;
  final String distributionMethod;
  final List<BoqDailyTarget> dailyTargets;

  const BoqTimeline({
    required this.startDate,
    required this.endDate,
    required this.distributionMethod,
    required this.dailyTargets,
  });

  factory BoqTimeline.fromJson(Map<String, dynamic> json) {
    final rawDaily = json['dailyTargets'] as List<dynamic>? ?? [];
    return BoqTimeline(
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      distributionMethod: json['distributionMethod'] as String? ?? 'equal',
      dailyTargets: rawDaily
          .map((e) => BoqDailyTarget.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BoqProgress {
  final String boqNumber;
  final String boqName;
  final String status;
  final double totalQuantity;
  final double completedQuantity;
  final double remainingQuantity;
  final double progressPercentage;
  final String? varianceStatus;
  final double? varianceQuantity;
  final Map<String, dynamic>? breakdown;
  final List<BoqTopMaterial> topMaterials;
  final BoqTimeline? timeline;
  final String? lastSyncedAt;

  const BoqProgress({
    required this.boqNumber,
    required this.boqName,
    required this.status,
    required this.totalQuantity,
    required this.completedQuantity,
    required this.remainingQuantity,
    required this.progressPercentage,
    this.varianceStatus,
    this.varianceQuantity,
    this.breakdown,
    required this.topMaterials,
    this.timeline,
    this.lastSyncedAt,
  });

  factory BoqProgress.fromJson(Map<String, dynamic> json) {
    final rawMaterials = json['topMaterials'] as List<dynamic>? ?? [];
    final timelineJson = json['timeline'] as Map<String, dynamic>?;
    return BoqProgress(
      boqNumber: json['boqNumber'] as String? ?? '',
      boqName: json['boqName'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      varianceStatus: json['varianceStatus'] as String?,
      varianceQuantity: (json['varianceQuantity'] as num?)?.toDouble(),
      breakdown: json['breakdown'] as Map<String, dynamic>?,
      topMaterials: rawMaterials
          .map((e) => BoqTopMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline:
          timelineJson != null ? BoqTimeline.fromJson(timelineJson) : null,
      lastSyncedAt: json['lastSyncedAt'] as String?,
    );
  }
}

// ── Upload Summary ──────────────────────────────────────────────────────────

class BoqUploadSummary {
  final int totalRows;
  final int validRows;
  final int invalidRows;
  final int customMaterials;
  final int matchedMaterials;

  const BoqUploadSummary({
    required this.totalRows,
    required this.validRows,
    required this.invalidRows,
    required this.customMaterials,
    required this.matchedMaterials,
  });

  factory BoqUploadSummary.fromJson(Map<String, dynamic> json) {
    return BoqUploadSummary(
      totalRows: json['totalRows'] as int? ?? 0,
      validRows: json['validRows'] as int? ?? 0,
      invalidRows: json['invalidRows'] as int? ?? 0,
      customMaterials: json['customMaterials'] as int? ?? 0,
      matchedMaterials: json['matchedMaterials'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION MODELS
// ─────────────────────────────────────────────────────────────────────────────

class NotificationSchedule {
  final String frequency; // "daily" | "weekly" | "monthly"
  final String time; // "20:30"
  final String timezone;
  final List<String>? weeklyDays;
  final int? monthlyDate;

  const NotificationSchedule({
    required this.frequency,
    required this.time,
    required this.timezone,
    this.weeklyDays,
    this.monthlyDate,
  });

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    final rawDays = json['weeklyDays'] as List<dynamic>?;
    return NotificationSchedule(
      frequency: json['frequency'] as String? ?? 'daily',
      time: json['time'] as String? ?? '20:30',
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      weeklyDays: rawDays?.map((e) => e as String).toList(),
      monthlyDate: json['monthlyDate'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'frequency': frequency,
        'time': time,
        'timezone': timezone,
        if (weeklyDays != null) 'weeklyDays': weeklyDays,
        if (monthlyDate != null) 'monthlyDate': monthlyDate,
      };
}

class NotificationThresholds {
  final double onTrackMin;
  final double onTrackMax;
  final double behindThreshold;
  final double criticalBehindThreshold;
  final double aheadThreshold;
  final double excellentAheadThreshold;

  const NotificationThresholds({
    required this.onTrackMin,
    required this.onTrackMax,
    required this.behindThreshold,
    required this.criticalBehindThreshold,
    required this.aheadThreshold,
    required this.excellentAheadThreshold,
  });

  factory NotificationThresholds.fromJson(Map<String, dynamic> json) {
    return NotificationThresholds(
      onTrackMin: (json['onTrackMin'] as num?)?.toDouble() ?? -5.0,
      onTrackMax: (json['onTrackMax'] as num?)?.toDouble() ?? 5.0,
      behindThreshold: (json['behindThreshold'] as num?)?.toDouble() ?? -10.0,
      criticalBehindThreshold:
          (json['criticalBehindThreshold'] as num?)?.toDouble() ?? -20.0,
      aheadThreshold: (json['aheadThreshold'] as num?)?.toDouble() ?? 10.0,
      excellentAheadThreshold:
          (json['excellentAheadThreshold'] as num?)?.toDouble() ?? 20.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'onTrackMin': onTrackMin,
        'onTrackMax': onTrackMax,
        'behindThreshold': behindThreshold,
        'criticalBehindThreshold': criticalBehindThreshold,
        'aheadThreshold': aheadThreshold,
        'excellentAheadThreshold': excellentAheadThreshold,
      };
}

class NotificationSendConditions {
  final bool sendOnlyIfChanged;
  final bool sendOnlyIfBehind;
  final bool sendOnlyIfCritical;
  final double minimumVarianceToSend;
  final bool sendOnWeekends;
  final bool sendOnHolidays;

  const NotificationSendConditions({
    required this.sendOnlyIfChanged,
    required this.sendOnlyIfBehind,
    required this.sendOnlyIfCritical,
    required this.minimumVarianceToSend,
    required this.sendOnWeekends,
    required this.sendOnHolidays,
  });

  factory NotificationSendConditions.fromJson(Map<String, dynamic> json) {
    return NotificationSendConditions(
      sendOnlyIfChanged: json['sendOnlyIfChanged'] as bool? ?? false,
      sendOnlyIfBehind: json['sendOnlyIfBehind'] as bool? ?? false,
      sendOnlyIfCritical: json['sendOnlyIfCritical'] as bool? ?? false,
      minimumVarianceToSend:
          (json['minimumVarianceToSend'] as num?)?.toDouble() ?? 0.0,
      sendOnWeekends: json['sendOnWeekends'] as bool? ?? false,
      sendOnHolidays: json['sendOnHolidays'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'sendOnlyIfChanged': sendOnlyIfChanged,
        'sendOnlyIfBehind': sendOnlyIfBehind,
        'sendOnlyIfCritical': sendOnlyIfCritical,
        'minimumVarianceToSend': minimumVarianceToSend,
        'sendOnWeekends': sendOnWeekends,
        'sendOnHolidays': sendOnHolidays,
      };
}

class NotificationTemplateSelection {
  final String mode; // "auto" | "single_site" | "multi_site"
  final bool allowAutoSwitch;
  final String? singleSiteTemplate;
  final String? multiSiteTemplate;

  const NotificationTemplateSelection({
    required this.mode,
    required this.allowAutoSwitch,
    this.singleSiteTemplate,
    this.multiSiteTemplate,
  });

  factory NotificationTemplateSelection.fromJson(Map<String, dynamic> json) {
    return NotificationTemplateSelection(
      mode: json['mode'] as String? ?? 'auto',
      allowAutoSwitch: json['allowAutoSwitch'] as bool? ?? true,
      singleSiteTemplate: json['singleSiteTemplate'] as String?,
      multiSiteTemplate: json['multiSiteTemplate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'allowAutoSwitch': allowAutoSwitch,
        if (singleSiteTemplate != null)
          'singleSiteTemplate': singleSiteTemplate,
        if (multiSiteTemplate != null) 'multiSiteTemplate': multiSiteTemplate,
      };
}

class GlobalNotificationSettings {
  final bool enabled;
  final NotificationTemplateSelection templateSelection;
  final NotificationSchedule schedule;
  final NotificationThresholds customThresholds;
  final NotificationSendConditions sendConditions;

  const GlobalNotificationSettings({
    required this.enabled,
    required this.templateSelection,
    required this.schedule,
    required this.customThresholds,
    required this.sendConditions,
  });

  factory GlobalNotificationSettings.fromJson(Map<String, dynamic> json) {
    return GlobalNotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      templateSelection: NotificationTemplateSelection.fromJson(
          json['templateSelection'] as Map<String, dynamic>? ?? {}),
      schedule: NotificationSchedule.fromJson(
          json['schedule'] as Map<String, dynamic>? ?? {}),
      customThresholds: NotificationThresholds.fromJson(
          json['customThresholds'] as Map<String, dynamic>? ?? {}),
      sendConditions: NotificationSendConditions.fromJson(
          json['sendConditions'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'templateSelection': templateSelection.toJson(),
        'schedule': schedule.toJson(),
        'customThresholds': customThresholds.toJson(),
        'sendConditions': sendConditions.toJson(),
      };
}

class SiteNotificationPreference {
  final String siteId;
  final String? siteName;
  final bool enabled;
  final bool includeInMultiSite;
  final String? templateOverride;
  final Map<String, dynamic>? thresholdsOverride;
  final Map<String, dynamic>? scheduleOverride;

  const SiteNotificationPreference({
    required this.siteId,
    this.siteName,
    required this.enabled,
    required this.includeInMultiSite,
    this.templateOverride,
    this.thresholdsOverride,
    this.scheduleOverride,
  });

  factory SiteNotificationPreference.fromJson(Map<String, dynamic> json) {
    return SiteNotificationPreference(
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      includeInMultiSite: json['includeInMultiSite'] as bool? ?? true,
      templateOverride: json['templateOverride'] as String?,
      thresholdsOverride: json['thresholdsOverride'] as Map<String, dynamic>?,
      scheduleOverride: json['scheduleOverride'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'enabled': enabled,
        'includeInMultiSite': includeInMultiSite,
        if (templateOverride != null) 'templateOverride': templateOverride,
        if (thresholdsOverride != null)
          'thresholdsOverride': thresholdsOverride,
        if (scheduleOverride != null) 'scheduleOverride': scheduleOverride,
      };
}

class NotificationPreferences {
  final String id;
  final String userId;
  final GlobalNotificationSettings globalSettings;
  final List<SiteNotificationPreference> sitePreferences;
  final String updatedAt;

  const NotificationPreferences({
    required this.id,
    required this.userId,
    required this.globalSettings,
    required this.sitePreferences,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final rawSites = json['sitePreferences'] as List<dynamic>? ?? [];
    return NotificationPreferences(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      globalSettings: GlobalNotificationSettings.fromJson(
          json['globalSettings'] as Map<String, dynamic>? ?? {}),
      sitePreferences: rawSites
          .map((e) =>
              SiteNotificationPreference.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

// ── Notification History ────────────────────────────────────────────────────

class NotificationHistorySnapshot {
  final double targetQuantity;
  final double completedQuantity;
  final double progressPercent;
  final double variance;

  const NotificationHistorySnapshot({
    required this.targetQuantity,
    required this.completedQuantity,
    required this.progressPercent,
    required this.variance,
  });

  factory NotificationHistorySnapshot.fromJson(Map<String, dynamic> json) {
    return NotificationHistorySnapshot(
      targetQuantity: (json['targetQuantity'] as num?)?.toDouble() ?? 0.0,
      completedQuantity: (json['completedQuantity'] as num?)?.toDouble() ?? 0.0,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      variance: (json['variance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NotificationHistoryItem {
  final String id;
  final String? siteId;
  final String? boqId;
  final String date;
  final NotificationHistorySnapshot? snapshot;
  final String? templateUsed;
  final String status; // "sent" | "delivered" | "read" | "failed"
  final String? sentAt;

  const NotificationHistoryItem({
    required this.id,
    this.siteId,
    this.boqId,
    required this.date,
    this.snapshot,
    this.templateUsed,
    required this.status,
    this.sentAt,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    final snapshotJson = json['snapshot'] as Map<String, dynamic>?;
    return NotificationHistoryItem(
      id: json['_id'] as String? ?? '',
      siteId: json['siteId'] as String?,
      boqId: json['boqId'] as String?,
      date: json['date'] as String? ?? '',
      snapshot: snapshotJson != null
          ? NotificationHistorySnapshot.fromJson(snapshotJson)
          : null,
      templateUsed: json['templateUsed'] as String?,
      status: json['status'] as String? ?? 'sent',
      sentAt: json['sentAt'] as String?,
    );
  }
}

class NotificationStats {
  final int totalSent;
  final int delivered;
  final int failed;
  final Map<String, int> byStatus;

  const NotificationStats({
    required this.totalSent,
    required this.delivered,
    required this.failed,
    required this.byStatus,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['byStatus'] as Map<String, dynamic>? ?? {};
    return NotificationStats(
      totalSent: json['totalSent'] as int? ?? 0,
      delivered: json['delivered'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      byStatus: rawStatus.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}
