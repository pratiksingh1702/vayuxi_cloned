// lib/providers/dpr_material_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dpr_material_service.dart';

class DprMaterialState {
  final bool isLoading;
  final Map<String, dynamic>? materialData;
  final List<dynamic>? rateList;
  final String? error;

  DprMaterialState({
    this.isLoading = false,
    this.materialData,
    this.rateList,
    this.error,
  });

  DprMaterialState copyWith({
    bool? isLoading,
    Map<String, dynamic>? materialData,
    List<dynamic>? rateList,
    String? error,
  }) {
    return DprMaterialState(
      isLoading: isLoading ?? this.isLoading,
      materialData: materialData ?? this.materialData,
      rateList: rateList ?? this.rateList,
      error: error ?? this.error,
    );
  }
}

class DprMaterialNotifier extends StateNotifier<DprMaterialState> {
  DprMaterialNotifier() : super(DprMaterialState());

  // Fetch material by ID
  Future<void> fetchMaterialById({
    required String mechanicalId,
    required String editDprId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final materialData = await DprMaterialService.fetchMaterialById(
        mechanicalId: mechanicalId,
        editDprId: editDprId,
      );
      state = state.copyWith(isLoading: false, materialData: materialData);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fetch rates
  Future<void> fetchRates() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final rateList = await DprMaterialService.fetchRates();
      state = state.copyWith(isLoading: false, rateList: rateList);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Post material
  Future<void> postMaterial({
    required FormData data,
    required String mechanicalId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await DprMaterialService.postMaterial(
        data: data,
        mechanicalId: mechanicalId,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update material
  Future<void> updateMaterial({
    required FormData data,
    required String mechanicalId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await DprMaterialService.updateMaterial(
        data: data,
        mechanicalId: mechanicalId,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final dprMaterialProvider = StateNotifierProvider<DprMaterialNotifier, DprMaterialState>(
      (ref) => DprMaterialNotifier(),
);