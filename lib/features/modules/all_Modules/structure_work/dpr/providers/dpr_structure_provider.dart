import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dpr_structure_model.dart';
import '../repository/dpr_structure_repository.dart';

final dprStructureRepositoryProvider =
    Provider((ref) => DPRStructureRepository());

class DPRStructureState {
  final List<DPRStructure> dprs;
  final DPRStructure? selectedDPR;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterBoqId;

  const DPRStructureState({
    this.dprs = const [],
    this.selectedDPR,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.filterStartDate,
    this.filterEndDate,
    this.filterBoqId,
  });

  DPRStructureState copyWith({
    List<DPRStructure>? dprs,
    DPRStructure? selectedDPR,
    bool? isLoading,
    bool? isSaving,
    String? error,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? filterBoqId,
    bool clearError = false,
    bool clearSelected = false,
    bool clearFilter = false,
  }) {
    return DPRStructureState(
      dprs: dprs ?? this.dprs,
      selectedDPR:
          clearSelected ? null : (selectedDPR ?? this.selectedDPR),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      filterStartDate:
          clearFilter ? null : (filterStartDate ?? this.filterStartDate),
      filterEndDate:
          clearFilter ? null : (filterEndDate ?? this.filterEndDate),
      filterBoqId:
          clearFilter ? null : (filterBoqId ?? this.filterBoqId),
    );
  }
}

class DPRStructureNotifier extends StateNotifier<DPRStructureState> {
  final DPRStructureRepository _repo;

  DPRStructureNotifier(this._repo) : super(const DPRStructureState());

  Future<void> fetchDPRList(String siteId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dprs = await _repo.getDPRList(
        siteId,
        startDate: state.filterStartDate,
        endDate: state.filterEndDate,
        boqId: state.filterBoqId,
      );
      state = state.copyWith(dprs: dprs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchDPRDetail(String siteId, String dprId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dpr = await _repo.getDPRDetail(siteId, dprId);
      state = state.copyWith(selectedDPR: dpr, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<bool> createDPR(
    String siteId, {
    required String boqId,
    required List<Map<String, dynamic>> items,
    DateTime? date,
    String? remarks,
    String? teamId,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final dpr = await _repo.createDPR(
        siteId,
        boqId: boqId,
        items: items,
        date: date,
        remarks: remarks,
        teamId: teamId,
      );
      state = state.copyWith(
        dprs: [dpr, ...state.dprs],
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> deleteDPR(String siteId, String dprId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.deleteDPR(siteId, dprId);
      final updated =
          state.dprs.where((d) => d.id != dprId).toList();
      state = state.copyWith(dprs: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _extractError(e));
      return false;
    }
  }

  void setFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? boqId,
    bool clear = false,
  }) {
    if (clear) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(
        filterStartDate: startDate,
        filterEndDate: endDate,
        filterBoqId: boqId,
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _extractError(Object e) {
    try {
      final msg = e.toString();
      if (msg.contains('"message"')) {
        final start = msg.indexOf('"message":"') + 11;
        final end = msg.indexOf('"', start);
        if (start > 10 && end > start) return msg.substring(start, end);
      }
      return msg.length > 120 ? '${msg.substring(0, 120)}...' : msg;
    } catch (_) {
      return 'An unexpected error occurred';
    }
  }
}

final dprStructureProvider =
    StateNotifierProvider<DPRStructureNotifier, DPRStructureState>(
  (ref) => DPRStructureNotifier(ref.read(dprStructureRepositoryProvider)),
);
