import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

/// ----------------------------
/// ENUMS
/// ----------------------------

enum LayerType { single, double, triple }

extension LayerTypeX on LayerType {
  int get count {
    switch (this) {
      case LayerType.single:
        return 1;
      case LayerType.double:
        return 2;
      case LayerType.triple:
        return 3;
    }
  }

  String get name => toString().split('.').last;

  static LayerType fromString(String value) {
    return LayerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LayerType.single,
    );
  }
}

final laggingMaterialProvider =
    StateNotifierProvider<LaggingNotifier, List<LaggingMaterial>>(
  (ref) => LaggingNotifier(),
);

class LaggingNotifier extends StateNotifier<List<LaggingMaterial>> {
  LaggingNotifier() : super([]);

  void add(LaggingMaterial m) => state = [...state, m];

  void update({
    required String id,
    String? name,
    double? thickness,
    String? uom,
  }) {
    state = state.map((m) {
      if (m.id != id) return m;
      return LaggingMaterial(
        id: m.id,
        name: name ?? m.name,
        thickness: thickness ?? m.thickness,
        uom: uom ?? m.uom,
      );
    }).toList();
  }

  void delete(String id) {
    state = state.where((m) => m.id != id).toList();
  }

  void clear() => state = [];
}

/// ----------------------------
/// MODELS
/// ----------------------------
class LaggingMaterial extends Equatable {
  final String id;
  final String name;
  final double thickness;
  final String uom;

  const LaggingMaterial({
    required this.id,
    required this.name,
    required this.thickness,
    required this.uom,
  });

  @override
  List<Object?> get props => [id, name, thickness, uom];
}

class LayerData extends Equatable {
  final String name;
  final double thickness;

  const LayerData({
    required this.name,
    required this.thickness,
  });

  factory LayerData.empty() {
    return const LayerData(name: '', thickness: 0);
  }

  LayerData copyWith({
    String? name,
    double? thickness,
  }) {
    return LayerData(
      name: name ?? this.name,
      thickness: thickness ?? this.thickness,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'thickness': thickness,
    };
  }

  factory LayerData.fromJson(Map<String, dynamic> json) {
    return LayerData(
      name: json['name'] ?? '',
      thickness: (json['thickness'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [name, thickness];
}

class InsulationState extends Equatable {
  final String floor;
  final LayerType? layerType;
  final List<LayerData> layers;
  final LayerData cladding;

  const InsulationState({
    this.floor = '',
    this.layerType,
    this.layers = const [],
    this.cladding = const LayerData(name: '', thickness: 0),
  });

  InsulationState copyWith({
    String? floor,
    LayerType? layerType,
    List<LayerData>? layers,
    LayerData? cladding,
  }) {
    return InsulationState(
      floor: floor ?? this.floor,
      layerType: layerType ?? this.layerType,
      layers: layers ?? this.layers,
      cladding: cladding ?? this.cladding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'floor': floor,
      'layerType': layerType?.name,
      'layers': layers.map((e) => e.toJson()).toList(),
      'cladding': cladding.toJson(),
    };
  }

  factory InsulationState.fromJson(Map<String, dynamic> json) {
    return InsulationState(
      floor: json['floor'] ?? '',
      layerType: json['layerType'] != null
          ? LayerTypeX.fromString(json['layerType'])
          : null,
      layers: (json['layers'] as List<dynamic>? ?? [])
          .map((e) => LayerData.fromJson(e))
          .toList(),
      cladding: json['cladding'] != null
          ? LayerData.fromJson(json['cladding'])
          : LayerData.empty(),
    );
  }

  @override
  List<Object?> get props => [floor, layerType, layers, cladding];
}

/// ----------------------------
/// PROVIDERS
/// ----------------------------

final insulationStateProvider =
    StateNotifierProvider<InsulationNotifier, InsulationState>(
  (ref) => InsulationNotifier(ref),
);

final currentStepProvider = StateProvider<int>((ref) => 0);

final totalStepsProvider = Provider<int>((ref) {
  final state = ref.watch(insulationStateProvider);
  final layerSteps = state.layers.length;
  return 2 + layerSteps + 1; // floor + layerType + layers + cladding
});

/// ----------------------------
/// NOTIFIER
/// ----------------------------

class InsulationNotifier extends StateNotifier<InsulationState> {
  final Ref ref;

  InsulationNotifier(this.ref) : super(const InsulationState());

  void hydrate({
    required LayerType layerType,
    required List<LayerData> layers,
    required LayerData cladding,
    required String floor,
  }) {
    state = state.copyWith(
      layerType: layerType,
      layers: List.from(layers),
      cladding: cladding,
      floor: floor,
    );
  }

  void setFloor(String floor) {
    state = state.copyWith(floor: floor);
  }

  void setLayerType(LayerType type) {
    final requiredCount = type.count;

    List<LayerData> updatedLayers = state.layers;

    if (state.layers.length != requiredCount) {
      updatedLayers = List.generate(
        requiredCount,
        (index) => index < state.layers.length
            ? state.layers[index]
            : LayerData.empty(),
      );
    }

    state = state.copyWith(
      layerType: type,
      layers: updatedLayers,
    );
  }

  void clearLayerSelection() {
    state = state.copyWith(
      layerType: null,
      layers: const [],
    );
  }

  void updateLayer({
    required int index,
    String? name,
    double? thickness,
  }) {
    if (index < 0 || index >= state.layers.length) return;

    final updated = List<LayerData>.from(state.layers);
    updated[index] = updated[index].copyWith(
      name: name,
      thickness: thickness,
    );

    state = state.copyWith(layers: updated);
  }

  void setCladding({
    String? name,
    double? thickness,
  }) {
    state = state.copyWith(
      cladding: state.cladding.copyWith(
        name: name,
        thickness: thickness,
      ),
    );
  }

  void resetAll() {
    state = const InsulationState();
    ref.read(currentStepProvider.notifier).state = 0;
  }
}
