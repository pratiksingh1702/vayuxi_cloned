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

class PebSetupItem {
  final String id;
  final String name;
  final String uom;
  final double targetQty;
  final String remarks;
  final List<String> images;

  const PebSetupItem({
    required this.id,
    required this.name,
    required this.uom,
    required this.targetQty,
    this.remarks = '',
    this.images = const [],
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
    return PebSetup(
      id: json['_id']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      allowUnassignedDprFallback: json['allowUnassignedDprFallback'] != false,
      items: (json['items'] as List? ?? [])
          .whereType<Map>()
          .map((item) => PebSetupItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
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
  final List<PebBoqMark> items;

  const PebBoq({
    required this.id,
    required this.name,
    required this.number,
    required this.items,
  });

  factory PebBoq.fromJson(Map<String, dynamic> json) {
    return PebBoq(
      id: json['_id']?.toString() ?? '',
      name: json['boqName']?.toString() ??
          json['projectName']?.toString() ??
          'BOQ',
      number: json['boqNumber']?.toString() ?? '',
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
  final List<String> assemblyMarks;
  final double assignedQty;
  final String uom;
  final String remarks;

  const PebAssignmentItem({
    required this.setupItemId,
    required this.stageName,
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
