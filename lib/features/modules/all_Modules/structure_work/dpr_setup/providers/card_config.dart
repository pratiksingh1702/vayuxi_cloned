import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../isar/assembly_card_isar.dart';
import '../../boq/models/boq_structure_model.dart';
import 'dpr_setup_providers.dart';

class AssemblyCardConfig {
  final String mark;
  final String description;
  final double quantity;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final String? boqItemId;

  AssemblyCardConfig({
    required this.mark,
    required this.description,
    required this.quantity,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.boqItemId,
  });

  AssemblyCardConfig copyWith({
    String? mark,
    String? description,
    double? quantity,
    double? weight,
    double? length,
    double? width,
    double? height,
    String? boqItemId,
  }) {
    return AssemblyCardConfig(
      mark: mark ?? this.mark,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      boqItemId: boqItemId ?? this.boqItemId,
    );
  }
}

class AssemblyCardNotifier extends StateNotifier<AssemblyCardConfig> {
  final String siteId;
  final Ref ref;

  AssemblyCardNotifier(this.ref, this.siteId, AssemblyCardIsar? initialCard)
      : super(AssemblyCardConfig(
          mark: initialCard?.assemblyMark ?? '',
          description: initialCard?.description ?? '',
          quantity: initialCard?.quantity ?? 0,
          weight: initialCard?.netWeightPerUnit,
          length: initialCard?.length,
          width: initialCard?.width,
          height: initialCard?.height,
          boqItemId: initialCard?.boqItemId,
        ));

  void updateMark(String mark) {
    state = state.copyWith(mark: mark);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateQuantity(double quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void updateWeight(double? weight) {
    state = state.copyWith(weight: weight);
  }

  void updateLength(double? length) {
    state = state.copyWith(length: length);
  }

  void updateWidth(double? width) {
    state = state.copyWith(width: width);
  }

  void updateHeight(double? height) {
    state = state.copyWith(height: height);
  }

  void selectBoqItem(BOQStructureItem item, String boqName) {
    state = state.copyWith(
      boqItemId: item.id,
      mark: item.assemblyMark,
      description: item.typeDescription,
      quantity: item.quantity,
      weight: item.netWeightPerUnit,
      length: item.length,
      width: item.width,
      height: item.height,
    );
  }

  Future<void> saveCard(AssemblyCardIsar? existingCard) async {
    final card = existingCard ?? AssemblyCardIsar();
    card.siteId = siteId;
    card.boqItemId = state.boqItemId ?? "";
    card.assemblyMark = state.mark;
    card.description = state.description;
    card.quantity = state.quantity;

    // Maintain quantities correctly
    card.availableQty =
        existingCard == null ? state.quantity : existingCard.availableQty;
    card.usedQty = existingCard == null ? 0 : existingCard.usedQty;
    card.remainingQty =
        existingCard == null ? state.quantity : existingCard.remainingQty;
    card.progressPercentage =
        existingCard == null ? 0 : existingCard.progressPercentage;

    card.netWeightPerUnit = state.weight;
    card.totalNetWeight = (state.weight ?? 0) * state.quantity;
    card.length = state.length;
    card.width = state.width;
    card.height = state.height;

    card.createdAt =
        existingCard == null ? DateTime.now() : existingCard.createdAt;
    card.isSynced = false;

    if (existingCard != null) {
      await ref.read(assemblyCardsProvider(siteId).notifier).updateCard(card);
    } else {
      await ref.read(assemblyCardsProvider(siteId).notifier).addCard(card);
    }
  }
}

final assemblyCardConfigProvider = StateNotifierProvider.family.autoDispose<
    AssemblyCardNotifier,
    AssemblyCardConfig,
    Map<String, dynamic>>((ref, params) {
  final siteId = params['siteId'] as String;
  final initialCard = params['card'] as AssemblyCardIsar?;
  return AssemblyCardNotifier(ref, siteId, initialCard);
});
