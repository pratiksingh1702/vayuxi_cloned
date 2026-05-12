import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/structure_pm_entry_model.dart';
import '../repository/structure_pm_repository.dart';

String _formatApiDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class StructurePmState {
  final DateTime selectedDate;
  final List<StructurePmResourceRow> rows;
  final StructurePmSummary summary;
  final String? selectedUnitCode;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const StructurePmState({
    required this.selectedDate,
    this.rows = const [],
    this.summary = StructurePmSummary.empty,
    this.selectedUnitCode,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  StructurePmState copyWith({
    DateTime? selectedDate,
    List<StructurePmResourceRow>? rows,
    StructurePmSummary? summary,
    String? selectedUnitCode,
    bool clearUnitCode = false,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return StructurePmState(
      selectedDate: selectedDate ?? this.selectedDate,
      rows: rows ?? this.rows,
      summary: summary ?? this.summary,
      selectedUnitCode:
          clearUnitCode ? null : (selectedUnitCode ?? this.selectedUnitCode),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StructurePmNotifier extends StateNotifier<StructurePmState> {
  final StructurePmRepository _repo;

  StructurePmNotifier(this._repo)
      : super(StructurePmState(selectedDate: DateTime.now()));

  Future<void> load(String siteId, DateTime date) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedDate: date,
    );
    try {
      final data = await _repo.getEntry(
        siteId,
        date: _formatApiDate(date),
      );
      state = state.copyWith(
        rows: data.rows,
        summary: data.summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  void setSelectedUnit(String? unitCode) {
    if (unitCode == null) {
      state = state.copyWith(clearUnitCode: true);
    } else {
      state = state.copyWith(selectedUnitCode: unitCode);
    }
  }

  void updateActualQty(String resourceId, double actualQty) {
    final updatedRows = state.rows.map((row) {
      if (row.id == resourceId) {
        return row.copyWith(actualQty: actualQty);
      }
      return row;
    }).toList();

    // Recalculate local summary
    double totalRequired = 0;
    double totalActual = 0;
    int filled = 0;

    for (final r in updatedRows) {
      totalRequired += r.requiredQty;
      totalActual += r.actualQty;
      if (r.actualQty > 0) filled++;
    }

    final localSummary = StructurePmSummary(
      totalRequired: totalRequired,
      totalActual: totalActual,
      totalGap: totalRequired - totalActual,
      totalCategories: state.summary.totalCategories,
      totalResources: updatedRows.length,
      filledResources: filled,
      pendingResources: updatedRows.length - filled,
      unitSummary: state.summary.unitSummary,
    );

    state = state.copyWith(rows: updatedRows, summary: localSummary);
  }

  void updateRemarks(String resourceId, String remarks) {
    final updatedRows = state.rows.map((row) {
      if (row.id == resourceId) {
        return row.copyWith(remarks: remarks);
      }
      return row;
    }).toList();
    state = state.copyWith(rows: updatedRows);
  }

  Future<bool> save(String siteId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final success = await _repo.saveEntry(
        siteId,
        date: _formatApiDate(state.selectedDate),
        rows: state.rows,
      );
      if (success) {
        // Reload from backend to get fresh data
        await load(siteId, state.selectedDate);
      }
      state = state.copyWith(isSaving: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractError(e),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('DioException')) {
      final match = RegExp(r'message:\s*(.+?)(?:,|\])').firstMatch(msg);
      return match?.group(1) ?? 'Network error. Please try again.';
    }
    return msg;
  }
}

final structurePmRepositoryProvider = Provider<StructurePmRepository>((ref) {
  return StructurePmRepository();
});

final structurePmProvider =
    StateNotifierProvider<StructurePmNotifier, StructurePmState>((ref) {
  return StructurePmNotifier(ref.read(structurePmRepositoryProvider));
});
