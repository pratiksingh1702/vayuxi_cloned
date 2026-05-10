import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/boq_structure_model.dart';
import '../repository/boq_structure_repository.dart';

// Repository provider
final boqStructureRepositoryProvider =
    Provider((ref) => BOQStructureRepository());

// State class
class BOQStructureState {
  final List<BOQStructure> boqs;
  final BOQStructure? selectedBOQ;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  const BOQStructureState({
    this.boqs = const [],
    this.selectedBOQ,
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  BOQStructureState copyWith({
    List<BOQStructure>? boqs,
    BOQStructure? selectedBOQ,
    bool? isLoading,
    bool? isUploading,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return BOQStructureState(
      boqs: boqs ?? this.boqs,
      selectedBOQ: clearSelected ? null : (selectedBOQ ?? this.selectedBOQ),
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BOQStructureNotifier extends StateNotifier<BOQStructureState> {
  final BOQStructureRepository _repo;
  List<BOQStructure>? _cache;

  BOQStructureNotifier(this._repo) : super(const BOQStructureState());

  Future<void> fetchBOQs(String siteId) async {
    if (_cache != null) {
      state = state.copyWith(boqs: _cache!);
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final boqs = await _repo.getAllBOQs(siteId);
      _cache = boqs;
      state = state.copyWith(boqs: boqs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractError(e),
      );
    }
  }

  Future<void> fetchBOQDetail(String siteId, String boqId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final boq = await _repo.getBOQDetail(siteId, boqId);
      state = state.copyWith(selectedBOQ: boq, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
    }
  }

  Future<bool> uploadBOQ(String siteId, PlatformFile file, {String workType = 'fabrication'}) async {
    state = state.copyWith(isUploading: true, clearError: true);
    try {
      final newBOQ = await _repo.uploadBOQExcel(siteId, file, workType: workType);
      _cache = null;
      final updated = [newBOQ, ...state.boqs];
      state = state.copyWith(boqs: updated, isUploading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: _extractError(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _extractError(Object e) {
    try {
      final msg = e.toString();
      if (msg.contains('message')) {
        final start = msg.indexOf('"message":"') + 11;
        final end = msg.indexOf('"', start);
        if (start > 10 && end > start) return msg.substring(start, end);
      }
      return msg.length > 100 ? msg.substring(0, 100) : msg;
    } catch (_) {
      return 'An unexpected error occurred';
    }
  }
}

final boqStructureProvider =
    StateNotifierProvider<BOQStructureNotifier, BOQStructureState>(
  (ref) => BOQStructureNotifier(ref.read(boqStructureRepositoryProvider)),
);

// Helper: fetch BOQ with items (for DPR create)
final boqItemsProvider = FutureProvider.family<BOQStructure,
    ({String siteId, String boqId})>(
  (ref, args) =>
      ref.read(boqStructureRepositoryProvider).getBOQItems(args.siteId, args.boqId),
);
