import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dprModel.dart';
import 'dprService.dart';

// DPR State
class DprState<T> {
  final bool isLoading;
  final T? data;
  final String? error;

  DprState({this.isLoading = false, this.data, this.error});

  DprState<T> copyWith({bool? isLoading, T? data, String? error}) {
    return DprState<T>(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

// DPR Notifier
class DprNotifier extends StateNotifier<DprState> {
  DprNotifier() : super(DprState());

  // Fetch all DPR work
  Future<void> fetchDprWork({required String siteId, required String teamId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final List<DprModel> dprList = await DprApi.fetchDprWork(siteId: siteId, teamId: teamId);
      state = state.copyWith(isLoading: false, data: dprList);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Fetch DPR by ID
  Future<void> fetchDprById({required String siteId, required String teamId, required String workId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final DprModel dpr = await DprApi.fetchDprWorkById(siteId: siteId, teamId: teamId, workId: workId);
      state = state.copyWith(isLoading: false, data: dpr);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Post DPR work
  Future<void> postDprWork({required Map<String, dynamic> data, required String siteId, required String teamId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final DprModel dpr = await DprApi.postDprWork(data: data, siteId: siteId, teamId: teamId);
      // Optionally update state.data if needed
      state = state.copyWith(isLoading: false, data: dpr);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update DPR work
  Future<void> updateDprWork({required Map<String, dynamic> data, required String mechanicalId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await DprApi.updateDprWork(data: data, mechanicalId: mechanicalId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Update DPR material qty
  Future<void> updateMaterialQty({required Map<String, dynamic> data, required String siteId, required String materialId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await DprApi.updateDprMaterialQty(data: data, siteId: siteId, materialId: materialId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Copy DPR material
  Future<void> copyMaterial({required String siteId, required String materialId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await DprApi.copyDprMaterial(siteId: siteId, materialId: materialId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Post DPR material
  // Future<void> postMaterial({required FormData data, required String mechanicalId}) async {
  //   try {
  //     state = state.copyWith(isLoading: true, error: null);
  //     await DprApi.postDprMaterial(data: data, mechanicalId: mechanicalId);
  //     state = state.copyWith(isLoading: false);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //   }
  // }

  // Delete DPR material
  // Future<void> deleteMaterial({required FormData data, required String mechanicalId}) async {
  //   try {
  //     state = state.copyWith(isLoading: true, error: null);
  //     await DprApi.deleteDprMaterial(data: data, mechanicalId: mechanicalId);
  //     state = state.copyWith(isLoading: false);
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //   }
  // }

  // Fetch sheets (measurement, calculation, summary, invoice)
  Future<void> fetchMeasurementSheet({required String siteId, required String fromDate, required String toDate}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await DprApi.fetchMeasurementSheet(siteId: siteId, fromDate: fromDate, toDate: toDate);
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchSummarySheet({required String siteId, required String fromDate, required String toDate}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await DprApi.fetchSummarySheet(siteId: siteId, fromDate: fromDate, toDate: toDate);
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchInvoiceSheet({required String siteId, required String fromDate, required String toDate}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await DprApi.fetchInvoiceSheet(siteId: siteId, fromDate: fromDate, toDate: toDate);
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final dprProvider = StateNotifierProvider<DprNotifier, DprState>(
      (ref) => DprNotifier(),
);
