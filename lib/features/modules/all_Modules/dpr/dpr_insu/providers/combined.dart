// providers/insulation_combined_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/base_material.dart';
import 'insu_equipment.dart';
import 'insu_piping.dart';
import 'material_util.dart';

// Combined list of all materials (piping + equipment)
final allInsulationMaterialsProvider = Provider<List<BaseMaterial>>((ref) {
  final piping = ref.watch(insulationPipingMaterialsProvider);
  final equipment = ref.watch(insulationEquipmentMaterialsProvider);

  return [...piping, ...equipment];
});

// Total count of all materials
final totalInsulationMaterialsCountProvider = Provider<int>((ref) {
  final pipingCount = ref.watch(insulationPipingMaterialsCountProvider);
  final equipmentCount = ref.watch(insulationEquipmentMaterialsCountProvider);
  return pipingCount + equipmentCount;
});

// Total quantity of all materials
final totalInsulationQuantityProvider = Provider<int>((ref) {
  final pipingQty = ref.watch(insulationPipingTotalQuantityProvider);
  final equipmentQty = ref.watch(insulationEquipmentTotalQuantityProvider);
  return pipingQty + equipmentQty;
});

// Total area of all materials
final totalInsulationAreaProvider = Provider<double>((ref) {
  final pipingArea = ref.watch(insulationPipingTotalAreaProvider);
  final equipmentArea = ref.watch(insulationEquipmentTotalAreaProvider);
  return pipingArea + equipmentArea;
});

// Material by ID (works for both piping and equipment)
final insulationMaterialByIdProvider = Provider.family<BaseMaterial?, String>((ref, id) {
  // First check piping materials
  final pipingMaterial = ref.watch(insulationPipingMaterialByIdProvider(id));
  if (pipingMaterial != null) return pipingMaterial;

  // Then check equipment materials
  final equipmentMaterial = ref.watch(insulationEquipmentMaterialByIdProvider(id));
  return equipmentMaterial;
});

// Filter all materials (piping + equipment)
final filteredAllInsulationMaterialsProvider =
Provider.family<List<BaseMaterial>, String>((ref, query) {
  final allMaterials = ref.watch(allInsulationMaterialsProvider);

  if (query.isEmpty) return allMaterials;

  final lowerQuery = query.toLowerCase();
  return allMaterials.where((material) {
    return material.name.toLowerCase().contains(lowerQuery) ||
        material.remarks.toLowerCase().contains(lowerQuery) ||
        material.uom.toLowerCase().contains(lowerQuery);
  }).toList();
});

// Statistics for all materials
final allInsulationMaterialsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final pipingStats = ref.watch(insulationPipingMaterialsStatsProvider);
  final equipmentStats = ref.watch(insulationEquipmentMaterialsStatsProvider);

  return {
    'piping': pipingStats,
    'equipment': equipmentStats,
    'totalCount': pipingStats['totalCount'] + equipmentStats['totalCount'],
    'totalQty': pipingStats['totalQty'] + equipmentStats['totalQty'],
    'totalArea': pipingStats['totalArea'] + equipmentStats['totalArea'],
  };
});

// Type checker provider
final insulationMaterialTypeProvider = Provider.family<String, String>((ref, materialName) {
  if (MaterialTypes.isPipingMaterial(materialName)) {
    return 'PIPING';
  } else if (MaterialTypes.isEquipmentMaterial(materialName)) {
    return 'EQUIPMENT';
  }
  return 'UNKNOWN';
});