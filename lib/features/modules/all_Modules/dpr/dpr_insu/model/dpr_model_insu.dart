import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/piping_insu.dart';

import 'eqip_insu.dart';

class InsulationDprModel {
  String id;
  String? teamId;

  // Basic Info
  String workDescription;
  List<String> designation;
  String plant;
  String location;
  int size;

  // Layer Info
  String layer; // single | double | triple

  String? leggingMaterial1;
  int? leggingThickness1;

  String? leggingMaterial2;
  int? leggingThickness2;

  String? leggingMaterial3;
  int? leggingThickness3;

  // Cladding
  String? claddingMaterial;
  int? claddingSwg;

  // Materials
  List<PipingMaterial> pipingMaterials;
  List<EquipmentMaterial> equipmentMaterials;

  // Calculations
  double layer1Rate;
  double layer2Rate;
  double layer3Rate;
  double totalMaterialCost;
  double totalPipingArea;
  double totalEquipmentArea;
  double grandTotalArea;
  double totalAmount;

  // Meta
  String status;
  DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  InsulationDprModel({
    required this.id,
    required this.workDescription,
    required this.designation,
    required this.plant,
    required this.location,
    required this.size,
    required this.layer,

    this.leggingMaterial1,
    this.leggingThickness1,
    this.leggingMaterial2,
    this.leggingThickness2,
    this.leggingMaterial3,
    this.leggingThickness3,

    this.claddingMaterial,
    this.claddingSwg,

    required this.pipingMaterials,
    required this.equipmentMaterials,

    required this.layer1Rate,
    required this.layer2Rate,
    required this.layer3Rate,
    required this.totalMaterialCost,
    required this.totalPipingArea,
    required this.totalEquipmentArea,
    required this.grandTotalArea,
    required this.totalAmount,
    this.teamId,

    required this.status,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InsulationDprModel.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      if (value is Map && value.containsKey('_id')) {
        return safeString(value['_id']);
      }
      return value.toString().trim();
    }
    // Helper function to safely parse dates
    DateTime parseDate(dynamic value) {
      if (value == null || value == "") return DateTime.now();
      try {
        return DateTime.parse(safeString(value));
      } catch (e) {
        print("❌ Insulation Date parsing error: $e for value: $value");
        return DateTime.now();
      }
    }

    return InsulationDprModel(
      id: json['_id'] ?? '',
      teamId: safeString(json['teamId']),
      workDescription: json['work_description'] ?? '',
      designation: List<String>.from(json['designation'] ?? []),
      plant: json['plant'] ?? '',
      location: json['location'] ?? '',
      size: json['size'] ?? 0,
      layer: json['layer'] ?? 'single',

      leggingMaterial1: json['legging_material_1'],
      leggingThickness1: json['legging_thickness_1'],
      leggingMaterial2: json['legging_material_2'],
      leggingThickness2: json['legging_thickness_2'],
      leggingMaterial3: json['legging_material_3'],
      leggingThickness3: json['legging_thickness_3'],

      claddingMaterial: json['cladding_material'],
      claddingSwg: json['cladding_swg'],

      pipingMaterials: List<PipingMaterial>.from(
        (json['piping_materials'] ?? []).map((x) => PipingMaterial.fromJson(x)),
      ),

      equipmentMaterials: List<EquipmentMaterial>.from(
        (json['equipment_materials'] ?? []).map(
          (x) => EquipmentMaterial.fromJson(x),
        ),
      ),

      layer1Rate: (json['layer_1_rate'] ?? 0).toDouble(),
      layer2Rate: (json['layer_2_rate'] ?? 0).toDouble(),
      layer3Rate: (json['layer_3_rate'] ?? 0).toDouble(),
      totalMaterialCost: (json['totalMaterialCost'] ?? 0).toDouble(),
      totalPipingArea: (json['total_piping_area'] ?? 0).toDouble(),
      totalEquipmentArea: (json['total_equipment_area'] ?? 0).toDouble(),
      grandTotalArea: (json['grand_total_area'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),

      status: json['status'] ?? 'draft',
      date: parseDate(json['date']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teamId': teamId,
      'work_description': workDescription,
      'designation': designation,
      'plant': plant,
      'location': location,
      'size': size,
      'layer': layer,

      'legging_material_1': leggingMaterial1,
      'legging_thickness_1': leggingThickness1,
      'legging_material_2': leggingMaterial2,
      'legging_thickness_2': leggingThickness2,
      'legging_material_3': leggingMaterial3,
      'legging_thickness_3': leggingThickness3,

      'cladding_material': claddingMaterial,
      'cladding_swg': claddingSwg,

      'piping_materials': pipingMaterials.map((e) => e.toJson()).toList(),
      'equipment_materials': equipmentMaterials.map((e) => e.toJson()).toList(),

      'layer_1_rate': layer1Rate,
      'layer_2_rate': layer2Rate,
      'layer_3_rate': layer3Rate,
      'totalMaterialCost': totalMaterialCost,
      'total_piping_area': totalPipingArea,
      'total_equipment_area': totalEquipmentArea,
      'grand_total_area': grandTotalArea,
      'totalAmount': totalAmount,

      'status': status,
      'date': date.toIso8601String(),
    };
  }
  factory InsulationDprModel.empty() {
    final now = DateTime.now();

    return InsulationDprModel(
      id: '',
      teamId: null,

      workDescription: '',
      designation: [],
      plant: '',
      location: '',
      size: 0,
      layer: 'single',

      leggingMaterial1: null,
      leggingThickness1: null,
      leggingMaterial2: null,
      leggingThickness2: null,
      leggingMaterial3: null,
      leggingThickness3: null,

      claddingMaterial: null,
      claddingSwg: null,

      pipingMaterials: [],
      equipmentMaterials: [],

      layer1Rate: 0,
      layer2Rate: 0,
      layer3Rate: 0,
      totalMaterialCost: 0,
      totalPipingArea: 0,
      totalEquipmentArea: 0,
      grandTotalArea: 0,
      totalAmount: 0,

      status: 'draft',
      date: now,
      createdAt: now,
      updatedAt: now,
    );
  }

}
