// providers/insulation_piping_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/material_setup.dart';
import '../model/piping_insu.dart';


// ==============================================
// MAIN PIPING MATERIALS PROVIDER
// ==============================================

final insulationPipingMaterialsProvider =
StateNotifierProvider<InsulationPipingMaterialsNotifier, List<PipingMaterial>>(
      (ref) => InsulationPipingMaterialsNotifier(),
);

class InsulationPipingMaterialsNotifier extends StateNotifier<List<PipingMaterial>> {
  InsulationPipingMaterialsNotifier() : super(const []);
  List<MaterialSetup> _setups = [];

  void updateSetups(List<MaterialSetup> setups) {
    _setups = setups;
  }

  MaterialSetup? findSetup(String? materialCode) {
    if (materialCode == null || materialCode.isEmpty) return null;
    try {
      return _setups.firstWhere((s) => s.materialCode == materialCode);
    } catch (_) {
      return null;
    }
  }

  void updateAllSizes({
    required String size,
    required String unit,
  }) {
    state = [
      for (final material in state)
        material.copyWith(
          size: size,
          sizeUom: unit,
        ),
    ];
  }
  void addMaterials(List<PipingMaterial> newMaterials) {
    state = [...state, ...newMaterials];
  }

  // PRIMARY METHOD: Set materials from external source
  void setMaterials(List<PipingMaterial> materials) {
    state = List<PipingMaterial>.unmodifiable(materials);
  }

  // Alternative name for clarity
  void setFromServer(List<PipingMaterial> serverMaterials) {
    state = List.unmodifiable(serverMaterials);
  }

  // Clear all materials
  void clear() => state = const [];

  // Add new piping material
  void addPipingMaterial(PipingMaterial material) {
    final updatedList = [...state, material];
    state = updatedList;
  }

  // Add new piping material after specific material
  void addPipingMaterialAfter(PipingMaterial material, String afterId) {
    final currentList = List<PipingMaterial>.from(state);
    final index = currentList.indexWhere((m) => m.id == afterId);

    if (index != -1) {
      currentList.insert(index + 1, material);
    } else {
      currentList.add(material);
    }

    state = currentList;
  }

  // Edit existing piping material
  void editPipingMaterial(String id, PipingMaterial updatedMaterial) {
    final newState = state.map((material) {
      if (material.id == id) {
        return updatedMaterial;
      }
      return material;
    }).toList();

    state = newState;
  }

  // Delete piping material
  void deletePipingMaterial(String id) {
    state = state.where((material) => material.id != id).toList();
  }

  // Update specific fields of a material
  void updatePipingMaterialField(
      String id,
      Map<String, dynamic> updates,
      ) {
    final updatedMaterials = state.map((material) {
      if (material.id == id) {
        return material.copyWith(
          name: updates['name'] ?? material.name,
          qty: updates['qty'] ?? material.qty,
          length: updates['length'] ?? material.length,
          circumference: updates['circumference'] ?? material.circumference,
          circumference1: updates['circumference1'] ?? material.circumference1,
          circumference2: updates['circumference2'] ?? material.circumference2,
          zHeight: updates['zHeight'] ?? material.zHeight,
          gSlantHeight: updates['gSlantHeight'] ?? material.gSlantHeight,
          constant: updates['constant'] ?? material.constant,
          totalArea: updates['totalArea'] ?? material.totalArea,
          size: updates['size'] ?? material.size,
          uom: updates['uom'] ?? material.uom,
          diameterA3: updates['diameterA3'] ?? material.diameterA3,
          diameterB3: updates['diameterB3'] ?? material.diameterB3,
          diameterA2: updates['diameterA2'] ?? material.diameterA2,
          diameterB2: updates['diameterB2'] ?? material.diameterB2,
          diameterA1: updates['diameterA1'] ?? material.diameterA1,
          diameterB1: updates['diameterB1'] ?? material.diameterB1,
          circumferenceFinal: updates['circumferenceFinal'] ?? material.circumferenceFinal,
          layer1Area: updates['layer1Area'] ?? material.layer1Area,
          layer2Area: updates['layer2Area'] ?? material.layer2Area,
          layer3Area: updates['layer3Area'] ?? material.layer3Area,
          circumference3: updates['circumference3'] ?? material.circumference3,
          circumference2Calc: updates['circumference2Calc'] ?? material.circumference2Calc,
          circumference1Calc: updates['circumference1Calc'] ?? material.circumference1Calc,
          o3: updates['o3'] ?? material.o3,
          o2: updates['o2'] ?? material.o2,
          o1: updates['o1'] ?? material.o1,
          remarks: updates['remarks'] ?? material.remarks,
          image: updates['image'] ?? material.image,
        );
      }
      return material;
    }).toList();

    state = updatedMaterials;
  }

  // Bulk update multiple materials
  void bulkUpdateMaterials(List<PipingMaterial> updatedMaterials) {
    state = updatedMaterials;
  }

  // Replace material by ID
  void replaceMaterial(String id, PipingMaterial newMaterial) {
    final newState = state.map((material) {
      if (material.id == id) {
        return newMaterial;
      }
      return material;
    }).toList();

    state = newState;
  }

  // Sort materials by name
  void sortByName({bool ascending = true}) {
    final sortedList = List<PipingMaterial>.from(state);
    sortedList.sort((a, b) {
      final comparison = a.name.compareTo(b.name);
      return ascending ? comparison : -comparison;
    });
    state = sortedList;
  }

  // Sort materials by quantity
  void sortByQuantity({bool ascending = true}) {
    final sortedList = List<PipingMaterial>.from(state);
    sortedList.sort((a, b) {
      final comparison = a.qty.compareTo(b.qty);
      return ascending ? comparison : -comparison;
    });
    state = sortedList;
  }

  // Filter materials and return filtered list (doesn't change state)
  List<PipingMaterial> filterMaterials(String query) {
    if (query.isEmpty) return state;

    final lowerQuery = query.toLowerCase();
    return state.where((material) {
      return material.name.toLowerCase().contains(lowerQuery) ||
          material.remarks.toLowerCase().contains(lowerQuery) ||
          material.uom.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get material by ID
  PipingMaterial? getMaterialById(String id) {
    try {
      return state.firstWhere((material) => material.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total quantity of all materials
  int getTotalQuantity() {
    return state.fold(0, (sum, material) => sum + material.qty);
  }

  // Get total area of all materials
  double getTotalArea() {
    return state.fold(0.0, (sum, material) => sum + material.totalArea);
  }
}

// ==============================================
// DERIVED PIPING PROVIDERS
// ==============================================

// Get piping material by ID
final insulationPipingMaterialByIdProvider =
Provider.family<PipingMaterial?, String>((ref, id) {
  final materials = ref.watch(insulationPipingMaterialsProvider);
  try {
    return materials.firstWhere((material) => material.id == id);
  } catch (e) {
    return null;
  }
});

// Filtered piping materials
final filteredInsulationPipingMaterialsProvider =
Provider.family<List<PipingMaterial>, String>((ref, query) {
  final materials = ref.watch(insulationPipingMaterialsProvider);

  if (query.isEmpty) return materials;

  final lowerQuery = query.toLowerCase();
  return materials.where((material) {
    return material.name.toLowerCase().contains(lowerQuery) ||
        material.remarks.toLowerCase().contains(lowerQuery) ||
        material.uom.toLowerCase().contains(lowerQuery);
  }).toList();
});

// Piping materials count
final insulationPipingMaterialsCountProvider = Provider<int>((ref) {
  final materials = ref.watch(insulationPipingMaterialsProvider);
  return materials.length;
});

// Total quantity of all piping materials
final insulationPipingTotalQuantityProvider = Provider<int>((ref) {
  final materials = ref.watch(insulationPipingMaterialsProvider);
  return materials.fold(0, (sum, material) => sum + material.qty);
});

// Total area of all piping materials
final insulationPipingTotalAreaProvider = Provider<double>((ref) {
  final materials = ref.watch(insulationPipingMaterialsProvider);
  return materials.fold(0.0, (sum, material) => sum + material.totalArea);
});

// Piping materials grouped by type
final insulationPipingMaterialsByTypeProvider = Provider<Map<String, List<PipingMaterial>>>((ref) {
  final materials = ref.watch(insulationPipingMaterialsProvider);
  final Map<String, List<PipingMaterial>> grouped = {};

  for (final material in materials) {
    final type = material.name.split(' ').first; // Get first word as type
    grouped.putIfAbsent(type, () => []).add(material);
  }

  return grouped;
});

// Piping materials statistics
final insulationPipingMaterialsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final materials = ref.watch(insulationPipingMaterialsProvider);

  if (materials.isEmpty) {
    return {
      'totalCount': 0,
      'totalQty': 0,
      'totalArea': 0.0,
      'avgQty': 0,
      'avgArea': 0.0,
    };
  }

  final totalQty = materials.fold(0, (sum, m) => sum + m.qty);
  final totalArea = materials.fold(0.0, (sum, m) => sum + m.totalArea);

  return {
    'totalCount': materials.length,
    'totalQty': totalQty,
    'totalArea': totalArea,
    'avgQty': totalQty / materials.length,
    'avgArea': totalArea / materials.length,
  };
});