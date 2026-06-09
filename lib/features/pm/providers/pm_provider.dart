import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pm_models.dart';
import '../repository/pm_repository.dart';

String formatPmDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class PmState {
  final DateTime selectedDate;
  final List<PmCategory> categories;
  final List<PmEntry> entries;
  final PmSummary summary;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const PmState({
    required this.selectedDate,
    this.categories = const [],
    this.entries = const [],
    this.summary = PmSummary.empty,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  PmState copyWith({
    DateTime? selectedDate,
    List<PmCategory>? categories,
    List<PmEntry>? entries,
    PmSummary? summary,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return PmState(
      selectedDate: selectedDate ?? this.selectedDate,
      categories: categories ?? this.categories,
      entries: entries ?? this.entries,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PmNotifier extends StateNotifier<PmState> {
  final PmRepository _repo;

  PmNotifier(this._repo) : super(PmState(selectedDate: DateTime.now()));

  Future<void> load(String siteId, String workType) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final date = formatPmDate(state.selectedDate);
      final results = await Future.wait([
        _repo.getSetup(siteId, workType),
        _repo.getEntries(siteId, workType, date: date),
        _repo.getDashboard(siteId, workType, date: date),
      ]);
      state = state.copyWith(
        categories: results[0] as List<PmCategory>,
        entries: results[1] as List<PmEntry>,
        summary: results[2] as PmSummary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
    }
  }

  Future<void> setDate(String siteId, String workType, DateTime date) async {
    state = state.copyWith(selectedDate: date);
    await load(siteId, workType);
  }

  Future<String> uploadImage(String siteId, PlatformFile file) {
    return _repo.uploadImage(siteId, file);
  }

  Future<bool> saveEquipment(
    String siteId, {
    PmEquipment? equipment,
    required String categoryKey,
    required String categoryName,
    required String equipmentName,
    required String capacity,
    required String unit,
    required String image,
    required String workType,
    bool reloadAfterSave = true,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      if (equipment == null) {
        await _repo.addEquipment(
          siteId,
          categoryKey: categoryKey,
          categoryName: categoryName,
          equipmentName: equipmentName,
          capacity: capacity,
          unit: unit,
          image: image,
          workType: workType,
        );
      } else {
        await _repo.updateEquipment(
          siteId,
          equipment,
          equipmentName: equipmentName,
          capacity: capacity,
          unit: unit,
          image: image,
          workType: workType,
        );
      }
      state = state.copyWith(isSaving: false);
      if (reloadAfterSave) {
        await load(siteId, workType);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _message(e));
      return false;
    }
  }

  Future<bool> deleteEquipment(
      String siteId, String workType, PmEquipment equipment) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.deleteEquipment(siteId, workType, equipment);
      state = state.copyWith(isSaving: false);
      await load(siteId, workType);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _message(e));
      return false;
    }
  }

  Future<bool> createEntry(
    String siteId, {
    required PmEquipment equipment,
    required String workType,
    required Map<String, dynamic> data,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repo.createEntry(
        siteId,
        equipment: equipment,
        date: formatPmDate(state.selectedDate),
        workType: workType,
        data: data,
      );
      state = state.copyWith(isSaving: false);
      await load(siteId, workType);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _message(e));
      return false;
    }
  }

  String _message(dynamic error) {
    final text = error.toString();
    if (text.contains('DioException'))
      return 'Server request failed. Please try again.';
    return text;
  }
}

final pmRepositoryProvider = Provider((ref) => PmRepository());

final pmProvider = StateNotifierProvider<PmNotifier, PmState>((ref) {
  return PmNotifier(ref.read(pmRepositoryProvider));
});
