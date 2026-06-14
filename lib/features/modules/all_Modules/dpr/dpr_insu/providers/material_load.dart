// providers/insulation_materials_api_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../providers/selectedSize_provider.dart';
import '../model/eqip_insu.dart';
import '../model/piping_insu.dart';
import '../service/material_service.dart';
import 'insu_equipment.dart';
import 'insu_piping.dart';
import 'material_util.dart';

// API Loading State
class InsulationMaterialsApiState {
  final bool isLoading;
  final String? error;
  final List<PipingMaterial> pipingMaterials;
  final List<EquipmentMaterial> equipmentMaterials;
  final int totalCount;

  InsulationMaterialsApiState({
    this.isLoading = false,
    this.error,
    this.pipingMaterials = const [],
    this.equipmentMaterials = const [],
    this.totalCount = 0,
  });

  InsulationMaterialsApiState copyWith({
    bool? isLoading,
    String? error,
    List<PipingMaterial>? pipingMaterials,
    List<EquipmentMaterial>? equipmentMaterials,
    int? totalCount,
  }) {
    return InsulationMaterialsApiState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pipingMaterials: pipingMaterials ?? this.pipingMaterials,
      equipmentMaterials: equipmentMaterials ?? this.equipmentMaterials,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// API State Provider
final insulationMaterialsApiProvider = StateNotifierProvider<
    InsulationMaterialsApiNotifier, InsulationMaterialsApiState>(
      (ref) => InsulationMaterialsApiNotifier(ref),
);

class InsulationMaterialsApiNotifier
    extends StateNotifier<InsulationMaterialsApiState> {
  final Ref ref;
  final InsulationMaterialSetupService _service = InsulationMaterialSetupService();

  InsulationMaterialsApiNotifier(this.ref) : super(InsulationMaterialsApiState());

  // Fetch materials from API and update both providers
  Future<void> fetchAndSetMaterials({
    required String siteId,
    String? designation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _service.getMaterials(
        siteId: siteId,
        designation: designation,
      );

      final pipingMaterials =
      result['pipingMaterials'] as List<PipingMaterial>;
      final equipmentMaterials =
      result['equipmentMaterials'] as List<EquipmentMaterial>;
      final totalCount = result['totalCount'] as int;

      final selectedSize = ref.read(selectedSizeProvider);

      final normalizedPiping = pipingMaterials.map((m) {
        if (m.size != 0) return m;
        if (selectedSize != 0) return m.copyWith(size: selectedSize);
        return m;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        pipingMaterials: normalizedPiping,
        equipmentMaterials: equipmentMaterials,
        totalCount: totalCount,
      );

      ref.read(insulationPipingMaterialsProvider.notifier)
          .setMaterials(normalizedPiping);

      ref.read(insulationEquipmentMaterialsProvider.notifier)
          .setMaterials(equipmentMaterials);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }


  // Clear all materials
  void clearMaterials() {
    state = InsulationMaterialsApiState();

    // Also clear main providers
    ref.read(insulationPipingMaterialsProvider.notifier).clear();
    ref.read(insulationEquipmentMaterialsProvider.notifier).clear();
  }
}