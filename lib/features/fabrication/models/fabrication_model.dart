import 'dart:convert';

enum FabStage {
  boq,
  dispatch,
  unload,
  shift,
  erect,
  align,
  inspect;

  String get displayName {
    switch (this) {
      case FabStage.boq: return 'BOQ';
      case FabStage.dispatch: return 'Dispatch';
      case FabStage.unload: return 'Unload';
      case FabStage.shift: return 'Shift';
      case FabStage.erect: return 'Erect';
      case FabStage.align: return 'Align';
      case FabStage.inspect: return 'Inspect';
    }
  }

  FabStage get previous {
    if (this == FabStage.boq) return FabStage.boq;
    return FabStage.values[index - 1];
  }
}

class FabricationProgress {
  final String id;
  final String boqItemId;
  final FabStage stage;
  final double quantity;
  final String assemblyMark;
  final String updatedBy;
  final DateTime updatedAt;

  FabricationProgress({
    required this.id,
    required this.boqItemId,
    required this.stage,
    required this.quantity,
    this.assemblyMark = '',
    required this.updatedBy,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'boqItemId': boqItemId,
      'stage': stage.index,
      'quantity': quantity,
      'assemblyMark': assemblyMark,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory FabricationProgress.fromMap(Map<String, dynamic> map) {
    return FabricationProgress(
      id: map['id'] ?? '',
      boqItemId: map['boqItemId'] ?? '',
      stage: FabStage.values[map['stage'] ?? 0],
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      assemblyMark: map['assemblyMark'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}

// Logic for quantity validation
class FabValidationEngine {
  static bool validateQuantity({
    required double newQuantity,
    required double previousStageQuantity,
    required double boqTotal,
  }) {
    if (newQuantity > previousStageQuantity) return false;
    if (newQuantity > boqTotal) return false;
    return true;
  }
}
