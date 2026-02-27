import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../equipmentModel.dart';
import '../hive_storage_service.dart';
import 'equipment_material_data.dart';

// Provider for all equipment materials with state
final equipmentMaterialsProvider = StateNotifierProvider<EquipmentMaterialsNotifier, List<EquipmentItem>>((ref) {
  return EquipmentMaterialsNotifier();
});

class EquipmentMaterialsNotifier extends StateNotifier<List<EquipmentItem>> {
  EquipmentMaterialsNotifier() : super([]) {

  }
  void setMaterials(List<EquipmentItem> materials) {
    state = List<EquipmentItem>.unmodifiable(materials);
  }void addMaterial(EquipmentItem item) {
    state = [...state, item];
  }

  // Load materials from Hive
  Future<void> loadMaterials() async {
    try {
      final materials = await HiveStorageService.getAllEquipmentMaterials();
      if (materials.isEmpty) {
        // If no data in Hive, load from default data
        state = EquipmentMaterialsData.materials;
        // Save default data to Hive
        await HiveStorageService.saveAllEquipmentMaterials(state);
      } else {
        state = materials;
      }
    } catch (e) {
      print('Error loading equipment materials: $e');
      state = EquipmentMaterialsData.materials;
    }
  }
  void clear() => state = const [];

  // Add a new equipment material
  Future<void> addEquipmentMaterial(EquipmentItem material) async {
    state = [...state, material];
    await HiveStorageService.addEquipmentMaterial(material);
  }

  // Edit an existing equipment material
  Future<void> editEquipmentMaterial(String id, EquipmentItem updatedMaterial) async {
    final newState = state.map((material) {
      if (material.id == id) {
        return updatedMaterial;
      }
      return material;
    }).toList();

    state = newState;
    await HiveStorageService.updateEquipmentMaterial(id, updatedMaterial);
  }

  // Delete an equipment material
  Future<void> deleteEquipmentMaterial(String id) async {
    state = state.where((material) => material.id != id).toList();
    await HiveStorageService.deleteEquipmentMaterial(id);
  }

  // Update specific fields of a material
  Future<void> updateEquipmentMaterialField(String id, Map<String, dynamic> updates) async {
    final updatedMaterials = state.map((material) {
      if (material.id == id) {
        final updatedMaterial = material.copyWith(
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

        // Update in Hive
        HiveStorageService.updateEquipmentMaterial(id, updatedMaterial);

        return updatedMaterial;
      }
      return material;
    }).toList();

    state = updatedMaterials;
  }

  // Refresh materials from storage
  Future<void> refreshMaterials() async {
    await loadMaterials();
  }
}

// Other providers remain the same...
final equipmentMaterialByIdProvider = Provider.family<EquipmentItem?, String>((ref, id) {
  final materials = ref.watch(equipmentMaterialsProvider);
  try {
    return materials.firstWhere((material) => material.id == id);
  } catch (e) {
    return null;
  }
});

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

final equipmentMaterialsCountProvider = Provider<int>((ref) {
  final materials = ref.watch(equipmentMaterialsProvider);
  return materials.length;
});