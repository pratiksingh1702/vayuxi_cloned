// lib/providers/equipment_materials_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../equipmentModel.dart';
import 'equipment_material_data.dart';

// Provider for all equipment materials with state
final equipmentMaterialsProvider = StateNotifierProvider<EquipmentMaterialsNotifier, List<EquipmentItem>>((ref) {
  return EquipmentMaterialsNotifier();
});

class EquipmentMaterialsNotifier extends StateNotifier<List<EquipmentItem>> {
  EquipmentMaterialsNotifier() : super(EquipmentMaterialsData.materials);

  // Add a new equipment material
  void addEquipmentMaterial(EquipmentItem material) {
    state = [...state, material];
  }

  // Edit an existing equipment material
  void editEquipmentMaterial(String id, EquipmentItem updatedMaterial) {
    state = state.map((material) {
      if (material.id == id) {
        return updatedMaterial;
      }
      return material;
    }).toList();
  }

  // Delete an equipment material
  void deleteEquipmentMaterial(String id) {
    state = state.where((material) => material.id != id).toList();
  }

  // Update specific fields of a material
  void updateEquipmentMaterialField(String id, Map<String, dynamic> updates) {
    state = state.map((material) {
      if (material.id == id) {
        return material.copyWith(
          materialName: updates['materialName'] ?? material.materialName,
          qty: updates['qty'] ?? material.qty,
          uom: updates['uom'] ?? material.uom,
          length: updates['length'] ?? material.length,
          rmt: updates['rmt'] ?? material.rmt,
          diameter: updates['diameter'] ?? material.diameter,
          weight: updates['weight'] ?? material.weight,
          power: updates['power'] ?? material.power,
          actualRate: updates['actualRate'] ?? material.actualRate,
          rate: updates['rate'] ?? material.rate,
          moc: updates['moc'] ?? material.moc,
          size: updates['size'] ?? material.size,
          location: updates['location'] ?? material.location,
          plant: updates['plant'] ?? material.plant,
          designation: updates['designation'] ?? material.designation,
          image: updates['image'] ?? material.image,
        );
      }
      return material;
    }).toList();
  }
}

// Provider to get a specific equipment material by ID
final equipmentMaterialByIdProvider = Provider.family<EquipmentItem?, String>((ref, id) {
  final materials = ref.watch(equipmentMaterialsProvider);
  try {
    return materials.firstWhere((material) => material.id == id);
  } catch (e) {
    return null;
  }
});

// Provider to filter equipment materials by search query
final filteredEquipmentMaterialsProvider = Provider.family<List<EquipmentItem>, String>((ref, query) {
  final materials = ref.watch(equipmentMaterialsProvider);
  if (query.isEmpty) return materials;

  final lowerQuery = query.toLowerCase();
  return materials.where((material) {
    return material.materialName.toLowerCase().contains(lowerQuery) ||
        material.uom.toLowerCase().contains(lowerQuery) ||
        material.moc.toLowerCase().contains(lowerQuery);
  }).toList();
});

// Provider to get equipment materials count
final equipmentMaterialsCountProvider = Provider<int>((ref) {
  final materials = ref.watch(equipmentMaterialsProvider);
  return materials.length;
});