class PmEquipment {
  final String id;
  final String source;
  final String categoryKey;
  final String categoryName;
  final String equipmentName;
  final String image;
  final String capacity;
  final String unit;
  final bool isCustom;
  final List<PmOptionalField> optionalFields;

  const PmEquipment({
    required this.id,
    required this.source,
    required this.categoryKey,
    required this.categoryName,
    required this.equipmentName,
    required this.image,
    required this.capacity,
    required this.unit,
    required this.isCustom,
    required this.optionalFields,
  });

  factory PmEquipment.fromJson(Map<String, dynamic> json) {
    return PmEquipment(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      source: (json['source'] ?? 'master').toString(),
      categoryKey: (json['categoryKey'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? 'P&M').toString(),
      equipmentName: (json['equipmentName'] ?? '').toString(),
      image: (json['image'] ?? json['defaultImage'] ?? '').toString(),
      capacity: (json['capacity'] ?? '').toString(),
      unit: (json['unit'] ?? 'Nos').toString(),
      isCustom: json['isCustom'] == true,
      optionalFields: ((json['optionalFields'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => PmOptionalField.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class PmCategory {
  final String categoryKey;
  final String categoryName;
  final List<PmEquipment> equipment;

  const PmCategory({
    required this.categoryKey,
    required this.categoryName,
    required this.equipment,
  });

  factory PmCategory.fromJson(Map<String, dynamic> json) {
    return PmCategory(
      categoryKey: (json['categoryKey'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? 'P&M').toString(),
      equipment: ((json['equipment'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => PmEquipment.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class PmOptionalField {
  final String key;
  final String label;
  final String fieldType;
  final String unit;

  const PmOptionalField({
    required this.key,
    required this.label,
    required this.fieldType,
    required this.unit,
  });

  factory PmOptionalField.fromJson(Map<String, dynamic> json) {
    return PmOptionalField(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      fieldType: (json['fieldType'] ?? 'text').toString(),
      unit: (json['unit'] ?? '').toString(),
    );
  }
}

class PmEntry {
  final String id;
  final String equipmentId;
  final DateTime entryDate;
  final String categoryName;
  final String equipmentName;
  final String equipmentImage;
  final String equipmentNumber;
  final String equipmentCapacity;
  final String ownerType;
  final String vendorName;
  final String startTime;
  final String endTime;
  final double breakdownHours;
  final double idleHours;
  final String operatorName;
  final String driverName;
  final String fuelType;
  final String status;
  final double totalWorkingHours;
  final double fuelConsumed;
  final double quantityExecuted;
  final String unit;
  final String location;
  final String activityPerformed;
  final String workDescription;
  final bool maintenanceRequired;

  const PmEntry({
    required this.id,
    required this.equipmentId,
    required this.entryDate,
    required this.categoryName,
    required this.equipmentName,
    required this.equipmentImage,
    required this.equipmentNumber,
    required this.equipmentCapacity,
    required this.ownerType,
    required this.vendorName,
    required this.startTime,
    required this.endTime,
    required this.breakdownHours,
    required this.idleHours,
    required this.operatorName,
    required this.driverName,
    required this.fuelType,
    required this.status,
    required this.totalWorkingHours,
    required this.fuelConsumed,
    required this.quantityExecuted,
    required this.unit,
    required this.location,
    required this.activityPerformed,
    required this.workDescription,
    required this.maintenanceRequired,
  });

  factory PmEntry.fromJson(Map<String, dynamic> json) {
    return PmEntry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      equipmentId: (json['equipmentId'] ??
              json['resourceId'] ??
              json['equipmentOverrideId'] ??
              json['masterEquipmentId'] ??
              '')
          .toString(),
      entryDate: DateTime.tryParse(
              (json['entryDate'] ?? json['date'] ?? '').toString()) ??
          DateTime.now(),
      categoryName: (json['categoryName'] ?? '').toString(),
      equipmentName: (json['equipmentName'] ?? '').toString(),
      equipmentImage: (json['equipmentImage'] ?? '').toString(),
      equipmentNumber: (json['equipmentNumber'] ?? '').toString(),
      equipmentCapacity: (json['equipmentCapacity'] ?? '').toString(),
      ownerType: (json['ownerType'] ?? '').toString(),
      vendorName: (json['vendorName'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      breakdownHours: _toDouble(json['breakdownHours']),
      idleHours: _toDouble(json['idleHours']),
      operatorName: (json['operatorName'] ?? '').toString(),
      driverName: (json['driverName'] ?? '').toString(),
      fuelType: (json['fuelType'] ?? '').toString(),
      status: (json['status'] ?? 'working').toString(),
      totalWorkingHours: _toDouble(json['totalWorkingHours']),
      fuelConsumed: _toDouble(json['fuelConsumed']),
      quantityExecuted: _toDouble(json['quantityExecuted']),
      unit: (json['unit'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      activityPerformed: (json['activityPerformed'] ?? '').toString(),
      workDescription: (json['workDescription'] ?? '').toString(),
      maintenanceRequired: json['maintenanceRequired'] == true,
    );
  }
}

class PmSummary {
  final int totalEquipment;
  final int totalEntries;
  final int runningEquipment;
  final int idleEquipment;
  final int breakdownEquipment;
  final int maintenanceEquipment;
  final double totalFuelConsumption;
  final double totalWorkingHours;
  final double totalProductivity;

  const PmSummary({
    required this.totalEquipment,
    required this.totalEntries,
    required this.runningEquipment,
    required this.idleEquipment,
    required this.breakdownEquipment,
    required this.maintenanceEquipment,
    required this.totalFuelConsumption,
    required this.totalWorkingHours,
    required this.totalProductivity,
  });

  factory PmSummary.fromJson(Map<String, dynamic> json) {
    return PmSummary(
      totalEquipment: _toInt(json['totalEquipment']),
      totalEntries: _toInt(json['totalEntries']),
      runningEquipment: _toInt(json['runningEquipment']),
      idleEquipment: _toInt(json['idleEquipment']),
      breakdownEquipment: _toInt(json['breakdownEquipment']),
      maintenanceEquipment: _toInt(json['maintenanceEquipment']),
      totalFuelConsumption: _toDouble(json['totalFuelConsumption']),
      totalWorkingHours: _toDouble(json['totalWorkingHours']),
      totalProductivity: _toDouble(json['totalProductivity']),
    );
  }

  static const empty = PmSummary(
    totalEquipment: 0,
    totalEntries: 0,
    runningEquipment: 0,
    idleEquipment: 0,
    breakdownEquipment: 0,
    maintenanceEquipment: 0,
    totalFuelConsumption: 0,
    totalWorkingHours: 0,
    totalProductivity: 0,
  );
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
