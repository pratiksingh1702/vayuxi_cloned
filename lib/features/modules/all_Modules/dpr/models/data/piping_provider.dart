// lib/providers/piping_materials_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pipingModel.dart';
import 'piping_material_data.dart';

// Provider for all piping materials with state
final pipingMaterialsProvider = StateNotifierProvider<PipingMaterialsNotifier, List<PipingItem>>((ref) {
  return PipingMaterialsNotifier();
});

class PipingMaterialsNotifier extends StateNotifier<List<PipingItem>> {
  PipingMaterialsNotifier() : super(PipingMaterialsData.materials);

  // Add a new piping material
  void addPipingMaterial(PipingItem material) {
    state = [...state, material];
  }

  // Edit an existing piping material
  void editPipingMaterial(String id, PipingItem updatedMaterial) {
    state = state.map((material) {
      if (material.id == id) {
        return updatedMaterial;
      }
      return material;
    }).toList();
  }

  // Delete a piping material
  void deletePipingMaterial(String id) {
    state = state.where((material) => material.id != id).toList();
  }

  // Update specific fields of a material
  void updatePipingMaterialField(String id, Map<String, dynamic> updates) {
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

// Provider to get a specific piping material by ID
final pipingMaterialByIdProvider = Provider.family<PipingItem?, String>((ref, id) {
  final materials = ref.watch(pipingMaterialsProvider);
  try {
    return materials.firstWhere((material) => material.id == id);
  } catch (e) {
    return null;
  }
});

// Provider to filter piping materials by search query
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

// Provider to get piping materials count
final pipingMaterialsCountProvider = Provider<int>((ref) {
  final materials = ref.watch(pipingMaterialsProvider);
  return materials.length;
});