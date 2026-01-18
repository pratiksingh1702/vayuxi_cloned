// providers/floor_provider.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/floorModel.dart';
import 'floor_api.dart';

class FloorState {
  final List<Floor> floors;
  final bool isLoading;
  final String? error;
  final Floor? selected;

  const FloorState({
    this.floors = const [],
    this.isLoading = false,
    this.error,
    this.selected
  });

  FloorState copyWith({
    List<Floor>? floors,
    bool? isLoading,
    String? error,
    Floor? selected

  }) {
    return FloorState(
      floors: floors ?? this.floors,
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FloorNotifier extends StateNotifier<FloorState> {
  final FloorApi api;

  FloorNotifier(this.api) : super(const FloorState());

  /// FETCH
  Future<void> fetchBySite(String siteId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await api.getFloorsBySite(siteId: siteId);

      if (res.data is! List) {
        throw Exception('Expected list from floor API');
      }

      final floors = (res.data as List)
          .map((e) => Floor.fromJson(e))
          .where((f) => !f.isDeleted)
          .toList();

      state = state.copyWith(floors: floors, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
  void select(Floor? floor) {
    state = state.copyWith(selected: floor);
  }

  /// CREATE
  Future<void> create({
    required String name,
    required String siteId,
    bool isApplied=false,
    File? image,
  }) async {
    final res = await api.createFloor(
      name: name,
      siteId: siteId,
      image: image,
      isApplied: isApplied,
    );

    final floor = Floor.fromJson(res.data);
    state = state.copyWith(floors: [...state.floors, floor]);
  }

  /// UPDATE
  Future<void> update({
    required String floorId,
    String? name,
    File? image,
    bool isApplied=false,
  }) async {
    final res = await api.updateFloor(
      floorId: floorId,
      name: name,
      image: image,
      isApplied: isApplied,
    );

    final updated = Floor.fromJson(res.data);

    state = state.copyWith(
      floors: state.floors
          .map((f) => f.id == updated.id ? updated : f)
          .toList(),
    );
  }

  /// DELETE
  Future<void> delete(String floorId) async {
    await api.deleteFloor(floorId: floorId);
    state = state.copyWith(
      floors: state.floors.where((f) => f?.id != floorId).toList(),
    );
  }
}
final floorApiProvider = Provider<FloorApi>((ref) => FloorApi());

final floorProvider =
StateNotifierProvider<FloorNotifier, FloorState>(
      (ref) => FloorNotifier(ref.read(floorApiProvider)),
);

final floorListProvider = Provider<List<Floor>>(
      (ref) => ref.watch(floorProvider).floors,
);
final selectedFloorProvider = Provider<Floor?>(
      (ref) => ref.watch(floorProvider).selected,
);

