// providers/insulation_equipment_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../model/eqip_insu.dart';

// ==============================================
// MAIN EQUIPMENT MATERIALS PROVIDER
// ==============================================

final insulationEquipmentMaterialsProvider =
StateNotifierProvider<InsulationEquipmentMaterialsNotifier, List<EquipmentMaterial>>(
      (ref) => InsulationEquipmentMaterialsNotifier(),
);

class InsulationEquipmentMaterialsNotifier extends StateNotifier<List<EquipmentMaterial>> {
  InsulationEquipmentMaterialsNotifier() : super(const []);

  // PRIMARY METHOD: Set materials from external source
  void setMaterials(List<EquipmentMaterial> materials) {
    state = List<EquipmentMaterial>.unmodifiable(materials);
  }

  // Alternative name for clarity
  void setFromServer(List<EquipmentMaterial> serverMaterials) {
    state = List.unmodifiable(serverMaterials);
  }

  // Clear all materials
  void clear() => state = const [];

  // Add new equipment material
  void addEquipmentMaterial(EquipmentMaterial material) {
    final updatedList = [...state, material];
    state = updatedList;
  }

  // Add new equipment material after specific material
  void addEquipmentMaterialAfter(EquipmentMaterial material, String afterId) {
    final currentList = List<EquipmentMaterial>.from(state);
    final index = currentList.indexWhere((m) => m.id == afterId);

    if (index != -1) {
      currentList.insert(index + 1, material);
    } else {
      currentList.add(material);
    }

    state = currentList;
  }

  // Edit existing equipment material
  void editEquipmentMaterial(String id, EquipmentMaterial updatedMaterial) {
    final newState = state.map((material) {
      if (material.id == id) {
        return updatedMaterial;
      }
      return material;
    }).toList();

    state = newState;
  }

  // Delete equipment material
  void deleteEquipmentMaterial(String id) {
    state = state.where((material) => material.id != id).toList();
  }

  // Update specific fields of a material
  void updateEquipmentMaterialField(
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
  void bulkUpdateMaterials(List<EquipmentMaterial> updatedMaterials) {
    state = updatedMaterials;
  }

  // Replace material by ID
  void replaceMaterial(String id, EquipmentMaterial newMaterial) {
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
    final sortedList = List<EquipmentMaterial>.from(state);
    sortedList.sort((a, b) {
      final comparison = a.name.compareTo(b.name);
      return ascending ? comparison : -comparison;
    });
    state = sortedList;
  }

  // Sort materials by quantity
  void sortByQuantity({bool ascending = true}) {
    final sortedList = List<EquipmentMaterial>.from(state);
    sortedList.sort((a, b) {
      final comparison = a.qty.compareTo(b.qty);
      return ascending ? comparison : -comparison;
    });
    state = sortedList;
  }

  // Filter materials and return filtered list (doesn't change state)
  List<EquipmentMaterial> filterMaterials(String query) {
    if (query.isEmpty) return state;

    final lowerQuery = query.toLowerCase();
    return state.where((material) {
      return material.name.toLowerCase().contains(lowerQuery) ||
          material.remarks.toLowerCase().contains(lowerQuery) ||
          material.uom.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get material by ID
  EquipmentMaterial? getMaterialById(String id) {
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

  // Get materials by category
  List<EquipmentMaterial> getMaterialsByCategory(String category) {
    return state.where((material) => material.name.contains(category)).toList();
  }
}

// ==============================================
// DERIVED EQUIPMENT PROVIDERS
// ==============================================

// Get equipment material by ID
final insulationEquipmentMaterialByIdProvider =
Provider.family<EquipmentMaterial?, String>((ref, id) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);
  try {
    return materials.firstWhere((material) => material.id == id);
  } catch (e) {
    return null;
  }
});

// Filtered equipment materials
final filteredInsulationEquipmentMaterialsProvider =
Provider.family<List<EquipmentMaterial>, String>((ref, query) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);

  if (query.isEmpty) return materials;

  final lowerQuery = query.toLowerCase();
  return materials.where((material) {
    return material.name.toLowerCase().contains(lowerQuery) ||
        material.remarks.toLowerCase().contains(lowerQuery) ||
        material.uom.toLowerCase().contains(lowerQuery);
  }).toList();
});

// Equipment materials count
final insulationEquipmentMaterialsCountProvider = Provider<int>((ref) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);
  return materials.length;
});

// Total quantity of all equipment materials
final insulationEquipmentTotalQuantityProvider = Provider<int>((ref) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);
  return materials.fold(0, (sum, material) => sum + material.qty);
});

// Total area of all equipment materials
final insulationEquipmentTotalAreaProvider = Provider<double>((ref) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);
  return materials.fold(0.0, (sum, material) => sum + material.totalArea);
});

// Equipment materials grouped by type
final insulationEquipmentMaterialsByTypeProvider = Provider<Map<String, List<EquipmentMaterial>>>((ref) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);
  final Map<String, List<EquipmentMaterial>> grouped = {};

  for (final material in materials) {
    final type = material.name.split(' ').first; // Get first word as type
    grouped.putIfAbsent(type, () => []).add(material);
  }

  return grouped;
});

// Equipment materials statistics
final insulationEquipmentMaterialsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);

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

// Equipment materials by component type
final insulationEquipmentByComponentProvider = Provider<Map<String, List<EquipmentMaterial>>>((ref) {
  final materials = ref.watch(insulationEquipmentMaterialsProvider);
  final Map<String, List<EquipmentMaterial>> components = {
    'SHELL': [],
    'DOME': [],
    'FLAT END': [],
    'CONE END': [],
    'REDUCER': [],
    'FLANGE BOX': [],
    'NOZZLE': [],
    'PATCH': [],
    'OTHER': [],
  };

  for (final material in materials) {
    final name = material.name.toUpperCase();

    if (name.contains('SHELL')) {
      components['SHELL']!.add(material);
    } else if (name.contains('DOME')) {
      components['DOME']!.add(material);
    } else if (name.contains('FLAT END')) {
      components['FLAT END']!.add(material);
    } else if (name.contains('CONE END')) {
      components['CONE END']!.add(material);
    } else if (name.contains('REDUCER')) {
      components['REDUCER']!.add(material);
    } else if (name.contains('FLANGE BOX')) {
      components['FLANGE BOX']!.add(material);
    } else if (name.contains('NOZZLE')) {
      components['NOZZLE']!.add(material);
    } else if (name.contains('PATCH')) {
      components['PATCH']!.add(material);
    } else {
      components['OTHER']!.add(material);
    }
  }

  // Remove empty categories
  components.removeWhere((key, value) => value.isEmpty);

  return components;
});