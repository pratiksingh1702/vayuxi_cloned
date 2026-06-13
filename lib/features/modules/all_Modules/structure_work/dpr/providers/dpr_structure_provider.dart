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

  const DPRStructureState({
    this.dprs = const [],
    this.selectedDPR,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.filterStartDate,
    this.filterEndDate,
  });

  DPRStructureState copyWith({
    List<DPRStructure>? dprs,
    DPRStructure? selectedDPR,
    bool? isLoading,
    bool? isSaving,
    String? error,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    bool clearError = false,
    bool clearSelected = false,
    bool clearFilter = false,
  }) {
    return DPRStructureState(
      dprs: dprs ?? this.dprs,
      selectedDPR: clearSelected ? null : (selectedDPR ?? this.selectedDPR),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      filterStartDate:
          clearFilter ? null : (filterStartDate ?? this.filterStartDate),
      filterEndDate: clearFilter ? null : (filterEndDate ?? this.filterEndDate),
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
      );
      state = state.copyWith(dprs: dprs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<void> fetchPebDPRList(String siteId, {String? type}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dprs = await _repo.getPebDPRList(
        siteId,
        startDate: state.filterStartDate,
        endDate: state.filterEndDate,
        type: type,
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
    required List<Map<String, dynamic>> items,
    String? dprName,
    DateTime? date,
    String? remarks,
    String? teamId,
    String? plant,
    String? location,
    String? moc,
    double? size,
    String? unit,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final dpr = await _repo.createDPR(
        siteId,
        items: items,
        dprName: dprName,
        date: date,
        remarks: remarks,
        teamId: teamId,
        plant: plant,
        location: location,
        moc: moc,
        size: size,
        unit: unit,
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

  Future<bool> updateDPR(
    String siteId,
    String dprId, {
    List<Map<String, dynamic>>? items,
    String? dprName,
    String? remarks,
    String? status,
    bool replaceMode = false,
    String? plant,
    String? location,
    String? moc,
    double? size,
    String? unit,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updatedDpr = await _repo.updateDPR(
        siteId,
        dprId,
        items: items,
        dprName: dprName,
        remarks: remarks,
        status: status,
        replaceMode: replaceMode,
        plant: plant,
        location: location,
        moc: moc,
        size: size,
        unit: unit,
      );
      final List<DPRStructure> updatedList = state.dprs
          .map<DPRStructure>((d) => d.id == dprId ? updatedDpr : d)
          .toList();
      state = state.copyWith(
        dprs: updatedList,
        selectedDPR: updatedDpr,
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
      final updated = state.dprs.where((d) => d.id != dprId).toList();
      state = state.copyWith(dprs: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> deletePebDPR(String siteId, String dprId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.deletePebDPR(siteId, dprId);
      final updated = state.dprs.where((d) => d.id != dprId).toList();
      state = state.copyWith(dprs: updated, isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _extractError(e));
      return false;
    }
  }

  Future<List<DPRStructure>> fetchDPRsForDate(
      String siteId, DateTime date) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dprs = await _repo.getDPRList(
        siteId,
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );
      state = state.copyWith(isLoading: false);
      return dprs;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return [];
    }
  }

  void setFilters({
    DateTime? startDate,
    DateTime? endDate,
    bool clear = false,
  }) {
    if (clear) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(
        filterStartDate: startDate,
        filterEndDate: endDate,
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
