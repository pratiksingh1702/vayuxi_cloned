// providers/moc_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/moc.dart';

import 'moc_service.dart';

/// STATE
class MOCState {
  final List<MOC> mocs;
  final MOC? selected;
  final bool isLoading;
  final String? error;

  const MOCState({
    this.mocs = const [],
    this.selected,
    this.isLoading = false,
    this.error,
  });

  MOCState copyWith({
    List<MOC>? mocs,
    MOC? selected,
    bool? isLoading,
    String? error,
  }) {
    return MOCState(
      mocs: mocs ?? this.mocs,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// NOTIFIER
class MOCNotifier extends StateNotifier<MOCState> {
  final MocApi api;

  MOCNotifier(this.api) : super(const MOCState());

  /// FETCH
  Future<void> fetchBySite(String siteId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await api.getMocBySite(siteId: siteId);

      if (res.data is! List) {
        throw Exception("Expected List from MOC API");
      }

      final List list = res.data;

      final mocs = list
          .where((e) => e is Map<String, dynamic>)
          .map((e) => MOC.fromJson(e))
          .toList();

      state = state.copyWith(
        mocs: mocs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// CREATE
  Future<void> create({
    required String name,
    required String siteId,
    bool? isApplied,
    File? image,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final res = await api.createMoc(
        name: name,
        siteId: siteId,
        isApplied: isApplied,
        image: image,
      );

      final moc = MOC.fromJson(res.data['data'] ?? res.data);

      state = state.copyWith(
        mocs: [...state.mocs, moc],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// UPDATE
  Future<void> update({
    required String mocId,
    String? name,
    bool? isApplied,
    File? image,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final res = await api.updateMoc(
        mocId: mocId,
        name: name,
        isApplied: isApplied,
        image: image,
      );

      final updated = MOC.fromJson(res.data['data'] ?? res.data);

      state = state.copyWith(
        mocs: state.mocs
            .map((m) => m.id == updated.id ? updated : m)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// DELETE
  Future<void> delete(String mocId) async {
    state = state.copyWith(isLoading: true);

    try {
      await api.deleteMoc(mocId: mocId);

      state = state.copyWith(
        mocs: state.mocs.where((m) => m.id != mocId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// SELECT
  void select(MOC? moc) {
    state = state.copyWith(selected: moc);
  }

  /// GET BY ID
  MOC? getById(String id) {
    try {
      return state.mocs.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}

final mocApiProvider = Provider<MocApi>((ref) => MocApi());

final mocProvider =
StateNotifierProvider<MOCNotifier, MOCState>(
      (ref) => MOCNotifier(ref.read(mocApiProvider)),
);

final mocListProvider = Provider<List<MOC>>(
      (ref) => ref.watch(mocProvider).mocs,
);

final selectedMOCProvider = Provider<MOC?>(
      (ref) => ref.watch(mocProvider).selected,
);
