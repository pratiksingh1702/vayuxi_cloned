enum PebExecutionType {
  erection,
  fabrication;

  String get apiType {
    switch (this) {
      case PebExecutionType.erection:
        return 'erection_work';
      case PebExecutionType.fabrication:
        return 'fabrication_work';
    }
  }

  String get section {
    switch (this) {
      case PebExecutionType.erection:
        return 'erection';
      case PebExecutionType.fabrication:
        return 'fabrication';
    }
  }

  String get title {
    switch (this) {
      case PebExecutionType.erection:
        return 'Structure Erection';
      case PebExecutionType.fabrication:
        return 'Structure Fabrication';
    }
  }

  List<String> get defaultStages {
    switch (this) {
      case PebExecutionType.erection:
        return const [
          'Unloading',
          'Shifting',
          'Erection',
          'Alignment',
          'Bolt Tightening',
          'Patch-up & Finishing',
          'QC Clearance',
        ];
      case PebExecutionType.fabrication:
        return const [
          'Unloading',
          'Shifting',
          'Cutting',
          'Chamfering',
          'Fitup',
          'Saw',
          'Grinding',
          'Weld Visual',
          'Loading',
          'Dispatch',
        ];
    }
  }
}

class PebTeam {
  final String id;
  final String name;

  const PebTeam({required this.id, required this.name});

  factory PebTeam.fromJson(Map<String, dynamic> json) {
    return PebTeam(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['teamName']?.toString() ?? json['name']?.toString() ?? 'Team',
    );
  }
}

class PebManpower {
  final String id;
  final String name;
  final String designation;
  final String manpowerType;

  const PebManpower({
    required this.id,
    required this.name,
    this.designation = '',
    this.manpowerType = '',
  });

  factory PebManpower.fromJson(Map<String, dynamic> json) {
    return PebManpower(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['fullName']?.toString() ??
          json['name']?.toString() ??
          'Manpower',
      designation: json['designation']?.toString() ?? '',
      manpowerType: json['manpowerType']?.toString() ?? '',
    );
  }
}

class PebAssignmentPlanDetail {
  final String id;
  final DateTime? plannedDate;
  final double plannedQuantity;
  final double actualQuantity;
  final double balanceQuantity;
  final String status;
  final String uom;

  const PebAssignmentPlanDetail({
    required this.id,
    required this.plannedDate,
    required this.plannedQuantity,
    required this.actualQuantity,
    required this.balanceQuantity,
    required this.status,
    required this.uom,
  });

  factory PebAssignmentPlanDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    double parseNum(dynamic value) =>
        (value as num?)?.toDouble() ??
        double.tryParse(value?.toString() ?? '') ??
        0;

    return PebAssignmentPlanDetail(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      plannedDate: parseDate(json['plannedDate']),
      plannedQuantity: parseNum(json['plannedQuantity']),
      actualQuantity: parseNum(json['actualQuantity']),
      balanceQuantity: parseNum(json['balanceQuantity']),
      status: json['status']?.toString() ?? 'planned',
      uom: json['uom']?.toString() ?? '',
    );
  }
}

class PebAssignmentPlan {
  final String id;
  final String type;
  final String section;
  final String setupItemId;
  final String stageName;
  final String targetType;
  final PebTeam? team;
  final PebManpower? manpower;
  final String planningType;
  final DateTime? startDate;
  final DateTime? tcd;
  final int? weekOffDay;
  final double totalQuantity;
  final String uom;
  final String status;
  final String remarks;
  final List<PebAssignmentPlanDetail> details;

  const PebAssignmentPlan({
    required this.id,
    required this.type,
    required this.section,
    required this.setupItemId,
    required this.stageName,
    required this.targetType,
    required this.team,
    required this.manpower,
    required this.planningType,
    required this.startDate,
    required this.tcd,
    required this.weekOffDay,
    required this.totalQuantity,
    required this.uom,
    required this.status,
    required this.remarks,
    this.details = const [],
  });

  factory PebAssignmentPlan.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    double parseNum(dynamic value) =>
        (value as num?)?.toDouble() ??
        double.tryParse(value?.toString() ?? '') ??
        0;

    final rawTeam = json['teamId'];
    final rawManpower = json['manpowerId'];

    return PebAssignmentPlan(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      setupItemId: json['setupItemId']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? 'Work Stage',
      targetType: json['targetType']?.toString() ?? 'unassigned',
      team: rawTeam is Map
          ? PebTeam.fromJson(Map<String, dynamic>.from(rawTeam))
          : null,
      manpower: rawManpower is Map
          ? PebManpower.fromJson(Map<String, dynamic>.from(rawManpower))
          : null,
      planningType: json['planningType']?.toString() ?? 'daily',
      startDate: parseDate(json['startDate']),
      tcd: parseDate(json['tcd']),
      weekOffDay: (json['weekOffDay'] as num?)?.toInt(),
      totalQuantity: parseNum(json['totalQuantity']),
      uom: json['uom']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      remarks: json['remarks']?.toString() ?? '',
      details: (json['details'] as List? ?? [])
          .whereType<Map>()
          .map((item) =>
              PebAssignmentPlanDetail.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class PebSetupItem {
  final String id;
  final String name;
  final String uom;
  final double targetQty;
  final String remarks;
  final List<String> images;
  final int displayOrder;

  const PebSetupItem({
    required this.id,
    required this.name,
    required this.uom,
    required this.targetQty,
    this.remarks = '',
    this.images = const [],
    this.displayOrder = 0,
  });

  factory PebSetupItem.fromJson(Map<String, dynamic> json) {
    return PebSetupItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['itemName']?.toString() ??
          json['stageName']?.toString() ??
          '',
      uom: json['uom']?.toString() ?? json['unit']?.toString() ?? 'MT',
      targetQty: (json['targetQty'] as num?)?.toDouble() ??
          (json['targetQuantity'] as num?)?.toDouble() ??
          0,
      remarks: json['remarks']?.toString() ?? '',
      images: ((json['image'] as List?) ?? (json['images'] as List?) ?? [])
          .map((image) => image.toString())
          .where((image) => image.trim().isNotEmpty)
          .toList(),
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class PebSetup {
  final String id;
  final String section;
  final bool allowUnassignedDprFallback;
  final List<PebSetupItem> items;

  const PebSetup({
    required this.id,
    required this.section,
    required this.allowUnassignedDprFallback,
    required this.items,
  });

  factory PebSetup.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List? ?? [])
        .whereType<Map>()
        .map((item) => PebSetupItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final indexedItems = rawItems.asMap().entries.toList()
      ..sort((a, b) {
        final aOrder =
            a.value.displayOrder > 0 ? a.value.displayOrder : a.key + 1;
        final bOrder =
            b.value.displayOrder > 0 ? b.value.displayOrder : b.key + 1;
        final orderCompare = aOrder.compareTo(bOrder);
        if (orderCompare != 0) return orderCompare;
        return a.key.compareTo(b.key);
      });

    return PebSetup(
      id: json['_id']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      allowUnassignedDprFallback: json['allowUnassignedDprFallback'] != false,
      items: indexedItems.map((entry) => entry.value).toList(),
    );
  }
}

class PebBoqMark {
  final String id;
  final String assemblyMark;
  final String detailedMark;
  final String typeDescription;
  final double quantity;
  final double remainingQty;
  final double length;
  final double width;
  final double height;
  final double netWeightPerUnit;
  final double totalNetWeight;
  final String status;

  const PebBoqMark({
    required this.id,
    required this.assemblyMark,
    required this.detailedMark,
    required this.typeDescription,
    required this.quantity,
    required this.remainingQty,
    required this.length,
    required this.width,
    required this.height,
    required this.netWeightPerUnit,
    required this.totalNetWeight,
    required this.status,
  });

  factory PebBoqMark.fromJson(Map<String, dynamic> json) {
    final quantity = (json['quantity'] as num?)?.toDouble() ?? 0;
    final netWeightPerUnit =
        (json['netWeightPerUnit'] as num?)?.toDouble() ?? 0;
    return PebBoqMark(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      assemblyMark: json['assemblyMark']?.toString() ?? '',
      detailedMark: json['detailedMark']?.toString() ?? '',
      typeDescription: json['typeDescription']?.toString() ?? '',
      quantity: quantity,
      remainingQty: (json['remainingQty'] as num?)?.toDouble() ?? quantity,
      length: (json['length'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      netWeightPerUnit: netWeightPerUnit,
      totalNetWeight: (json['totalNetWeight'] as num?)?.toDouble() ??
          quantity * netWeightPerUnit,
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) '_id': id,
        'assemblyMark': assemblyMark,
        'detailedMark': detailedMark,
        'typeDescription': typeDescription,
        'quantity': quantity,
        'length': length,
        'width': width,
        'height': height,
        'netWeightPerUnit': netWeightPerUnit,
      };
}

class PebBoq {
  final String id;
  final String name;
  final String number;
  final String quantityType;
  final List<PebBoqMark> items;

  const PebBoq({
    required this.id,
    required this.name,
    required this.number,
    required this.quantityType,
    required this.items,
  });

  factory PebBoq.fromJson(Map<String, dynamic> json) {
    return PebBoq(
      id: json['_id']?.toString() ?? '',
      name: json['boqName']?.toString() ??
          json['projectName']?.toString() ??
          'BOQ',
      number: json['boqNumber']?.toString() ?? '',
      quantityType: json['quantityType']?.toString() ?? 'exact',
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => PebBoqMark.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.assemblyMark.isNotEmpty)
          .toList(),
    );
  }
}

class PebAssignmentItem {
  final String setupItemId;
  final String stageName;
  final String workDescription;
  final List<String> assemblyMarks;
  final double assignedQty;
  final String uom;
  final String remarks;

  const PebAssignmentItem({
    required this.setupItemId,
    required this.stageName,
    this.workDescription = '',
    required this.assemblyMarks,
    required this.assignedQty,
    required this.uom,
    required this.remarks,
  });

  factory PebAssignmentItem.fromJson(Map<String, dynamic> json) {
    return PebAssignmentItem(
      setupItemId: json['setupItemId'] is Map
          ? json['setupItemId']['_id']?.toString() ?? ''
          : json['setupItemId']?.toString() ?? '',
      stageName: json['stageName']?.toString() ?? '',
      workDescription: json['workDescription']?.toString() ?? '',
      assemblyMarks: (json['assemblyMarks'] as List? ?? [])
          .map((mark) => mark.toString())
          .where((mark) => mark.trim().isNotEmpty)
          .toList(),
      assignedQty: (json['assignedQty'] as num?)?.toDouble() ?? 0,
      uom: json['uom']?.toString() ?? 'MT',
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'setupItemId': setupItemId,
        'stageName': stageName,
        'workDescription': workDescription,
        'assemblyMarks': assemblyMarks,
        'assignedQty': assignedQty,
        'uom': uom,
        'remarks': remarks,
      };
}

class PebWorkAssignment {
  final String id;
  final String type;
  final String section;
  final String status;
  final String sourceType;
  final PebTeam? team;
  final String teamId;
  final DateTime? assignmentDate;
  final DateTime? expectedCompletionDate;
  final List<PebAssignmentItem> assignments;

  const PebWorkAssignment({
    required this.id,
    required this.type,
    required this.section,
    required this.status,
    required this.sourceType,
    required this.team,
    required this.teamId,
    required this.assignmentDate,
    required this.expectedCompletionDate,
    required this.assignments,
  });

  factory PebWorkAssignment.fromJson(Map<String, dynamic> json) {
    final rawTeam = json['teamId'];
    final team = rawTeam is Map
        ? PebTeam.fromJson(Map<String, dynamic>.from(rawTeam))
        : null;
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return PebWorkAssignment(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      sourceType: json['sourceType']?.toString() ?? 'boq_upload',
      team: team,
      teamId: team?.id ?? rawTeam?.toString() ?? '',
      assignmentDate: parseDate(json['assignmentDate']),
      expectedCompletionDate: parseDate(json['expectedCompletionDate']),
      assignments: (json['assignments'] as List? ?? [])
          .whereType<Map>()
          .map((item) =>
              PebAssignmentItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class PebMarkStatus {
  final Map<String, Set<String>> completedByKey;
  final Map<String, Set<String>> inProgressByKey;
  final Map<String, Map<String, DateTime>> completedDateByKey;

  const PebMarkStatus({
    required this.completedByKey,
    required this.inProgressByKey,
    this.completedDateByKey = const {},
  });
}

class PebLevel1DprEntry {
  final String dprId;
  final String setupItemId;
  final String teamId;
  final double actualQty;
  final double targetQty;
  final int progressPercentage;
  final String uom;
  final String remarks;
  final double manualWeightKg;
  final double totalWeightKg;
  final bool isCompleted;

  const PebLevel1DprEntry({
    required this.dprId,
    required this.setupItemId,
    required this.teamId,
    required this.actualQty,
    required this.targetQty,
    required this.progressPercentage,
    required this.uom,
    required this.remarks,
    required this.manualWeightKg,
    required this.totalWeightKg,
    required this.isCompleted,
  });
}
