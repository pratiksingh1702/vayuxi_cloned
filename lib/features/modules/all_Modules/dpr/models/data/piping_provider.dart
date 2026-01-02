import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/piping_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dpr.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
import '../../screens/material_sync_util.dart';
import '../hive_storage_service.dart';
import '../pipingModel.dart';


// Provider for all piping materials with state
final pipingMaterialsProvider =
StateNotifierProvider<PipingMaterialsNotifier, List<PipingItem>>(
      (ref) => PipingMaterialsNotifier(),
);
class PipingMaterialsNotifier extends StateNotifier<List<PipingItem>> {
  PipingMaterialsNotifier()
      : super(List<PipingItem>.from(PipingMaterialsData.materials));

  void setMaterials(List<PipingItem> materials) {
    state = List<PipingItem>.unmodifiable(materials);
  }

  // Load materials from Hive
  Future<void> _loadMaterials() async {
    try {
      final materials = await HiveStorageService.getAllPipingMaterials();
      if (materials.isEmpty) {
        // If no data in Hive, load from default data
        state = PipingMaterialsData.materials;
        // Save default data to Hive
        await HiveStorageService.saveAllPipingMaterials(state);
      } else {
        state = materials;
      }
    } catch (e) {
      print('Error loading piping materials: $e');
      state = PipingMaterialsData.materials;
    }
  }

  // Add a new piping material
  Future<void> addPipingMaterial(PipingItem material) async {
    state = [...state, material];
    await HiveStorageService.addPipingMaterial(material);
  }
  // Add a new piping material after a specific material
  Future<void> addPipingMaterialAfter(PipingItem material, String afterId) async {
    final currentList = List<PipingItem>.from(state);
    final index = currentList.indexWhere((m) => m.id == afterId);

    if (index != -1) {
      // Insert after the found index
      currentList.insert(index + 1, material);
    } else {
      // If not found, add at the end
      currentList.add(material);
    }

    state = currentList;
    await HiveStorageService.addPipingMaterial(material);
  }

  // Edit an existing piping material
  Future<void> editPipingMaterial(String id, PipingItem updatedMaterial) async {
    final newState = state.map((material) {
      if (material.id == id) {
        return updatedMaterial;
      }
      return material;
    }).toList();

    state = newState;
    await HiveStorageService.updatePipingMaterial(id, updatedMaterial);
  }

  // Delete a piping material
  Future<void> deletePipingMaterialFromServer({
    required String materialId,
    required String mechanicalId,
    // if backend really needs it
  }) async {
    try {
      final formData = FormData.fromMap({
        "_id": materialId,
      });
      // 1️⃣ Call server
      await DprApi().deleteMaterial(
        mechanicalId: mechanicalId,
        data: formData,
      );

      // 2️⃣ Remove from state (UI)
      state = state.where((m) => m.id != materialId).toList();

      // 3️⃣ Remove from Hive (cache)
      await HiveStorageService.deletePipingMaterial(materialId);
    } catch (e) {
      // DO NOT mutate state if server delete fails
      print("❌ Failed to delete material from server: $e");
      rethrow;
    }
  }


  // Update specific fields of a material
  Future<void> updatePipingMaterialField(String id, Map<String, dynamic> updates) async {
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
        HiveStorageService.updatePipingMaterial(id, updatedMaterial);

        return updatedMaterial;
      }
      return material;
    }).toList();

    state = updatedMaterials;
  }

  // Refresh materials from storage
  Future<void> refreshMaterials() async {
    await _loadMaterials();
  }
}

// Other providers remain the same...
final pipingMaterialByIdProvider = Provider.family<PipingItem?, String>((ref, id) {
  final materials = ref.watch(pipingMaterialsProvider);
  try {
    return materials.firstWhere((material) => material.id == id);
  } catch (e) {
    return null;
  }
});

final filteredPipingMaterialsProvider = Provider.family<List<PipingItem>, String>((ref, query) {
  final materials = ref.watch(pipingMaterialsProvider);
  if (query.isEmpty) return materials;

  final lowerQuery = query.toLowerCase();
  return materials.where((material) {
    return material.materialName.toLowerCase().contains(lowerQuery) ||
        material.uom.toLowerCase().contains(lowerQuery) ||
        material.moc.toLowerCase().contains(lowerQuery);
  }).toList();
});

final pipingMaterialsCountProvider = Provider<int>((ref) {
  final materials = ref.watch(pipingMaterialsProvider);
  return materials.length;
});

