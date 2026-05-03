import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../../../../../core/local/isar_db.dart';
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/saved_boq_provider.dart';
import '../../dpr_setup/isar/assembly_card_isar.dart';

class DprEntryState {
  final List<AssemblyCardIsar> activeCards;
  final List<String> availableWorkNames;
  final String? selectedWorkName;
  final bool isLoading;
  final String? error;

  DprEntryState({
    this.activeCards = const [],
    this.availableWorkNames = const [],
    this.selectedWorkName,
    this.isLoading = false,
    this.error,
  });

  DprEntryState copyWith({
    List<AssemblyCardIsar>? activeCards,
    List<String>? availableWorkNames,
    String? selectedWorkName,
    bool? isLoading,
    String? error,
  }) {
    return DprEntryState(
      activeCards: activeCards ?? this.activeCards,
      availableWorkNames: availableWorkNames ?? this.availableWorkNames,
      selectedWorkName: selectedWorkName ?? this.selectedWorkName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DprEntryNotifier extends StateNotifier<DprEntryState> {
  final Ref ref;
  DprEntryNotifier(this.ref) : super(DprEntryState());

  final _isar = AppIsarDB.isar;

  /// Load all unique work descriptions from Setup to populate the dropdown
  Future<void> initialize(String siteId) async {
    state = state.copyWith(isLoading: true);
    try {
      final allCards = await _isar.assemblyCardIsars
          .where()
          .filter()
          .siteIdEqualTo(siteId)
          .findAll();

      final workNames = allCards.map((e) => e.description).toSet().toList();

      state = state.copyWith(
        availableWorkNames: workNames,
        selectedWorkName: workNames.isNotEmpty ? workNames.first : null,
        isLoading: false,
      );

      if (state.selectedWorkName != null) {
        loadCardsForWork(siteId, state.selectedWorkName!);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load cards for a specific work description (Setup cards)
  Future<void> loadCardsForWork(String siteId, String workName) async {
    state = state.copyWith(isLoading: true, selectedWorkName: workName);
    try {
      final cards = await _isar.assemblyCardIsars
          .where()
          .filter()
          .siteIdEqualTo(siteId)
          .and()
          .descriptionEqualTo(workName)
          .findAll();

      state = state.copyWith(activeCards: cards, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a card by searching for an Assembly Mark in the BOQ
  Future<String?> addByMark(String siteId, String mark) async {
    // 1. Check if already in active list
    if (state.activeCards
        .any((c) => c.assemblyMark.toLowerCase() == mark.toLowerCase())) {
      return "Card with this mark already exists in the list.";
    }

    // 2. Search in BOQ (via savedBOQProvider which is synced offline)
    final boqState = ref.read(savedBOQProvider);
    BOQStructureItem? foundItem;

    // Search through all loaded BOQs for this site
    for (var boq in boqState.boqs) {
      for (var item in boq.items) {
        if (item.assemblyMark.toLowerCase() == mark.toLowerCase()) {
          foundItem = item;
          break;
        }
      }
      if (foundItem != null) break;
    }

    if (foundItem == null) {
      return "Mark '$mark' not found in any uploaded BOQ.";
    }

    // 3. Create a temporary AssemblyCardIsar object
    final newCard = AssemblyCardIsar()
      ..siteId = siteId
      ..boqItemId = foundItem.id
      ..assemblyMark = foundItem.assemblyMark
      ..description = foundItem.typeDescription
      ..quantity = 0 // Initial progress is 0
      ..availableQty = foundItem.availableQty
      ..usedQty = foundItem.usedQty
      ..remainingQty = foundItem.remainingQty
      ..length = foundItem.length
      ..width = foundItem.width
      ..height = foundItem.height
      ..netWeightPerUnit = foundItem.netWeightPerUnit
      ..totalNetWeight = foundItem.totalNetWeight
      ..progressPercentage = foundItem.progressPercentage
      ..createdAt = DateTime.now()
      ..isSynced = false;

    state = state.copyWith(activeCards: [...state.activeCards, newCard]);
    return null; // Success
  }

  void addEmptyCard(String siteId) {
    final newCard = AssemblyCardIsar()
      ..siteId = siteId
      ..boqItemId = ''
      ..assemblyMark = ''
      ..description = ''
      ..quantity = 0
      ..availableQty = 0
      ..usedQty = 0
      ..remainingQty = 0
      ..length = null
      ..width = null
      ..height = null
      ..netWeightPerUnit = null
      ..totalNetWeight = null
      ..progressPercentage = 0
      ..createdAt = DateTime.now()
      ..isSynced = false;

    state = state.copyWith(activeCards: [...state.activeCards, newCard]);
  }

  void setWorkName(String name) {
    state = state.copyWith(
      selectedWorkName: name,
    );
  }

  void updateCard(int index, String mark, double qty) {
    final newList = List<AssemblyCardIsar>.from(state.activeCards);
    final card = newList[index];

    final lookedUp = _findBoqItemByMark(mark);

    // Create a NEW instance to trigger UI update
    final updatedCard = lookedUp != null
        ? _copyCard(
            card,
            assemblyMark: mark,
            description: lookedUp.typeDescription,
            quantity: qty,
            boqItemId: lookedUp.id,
            availableQty: lookedUp.availableQty,
            usedQty: lookedUp.usedQty,
            remainingQty: lookedUp.remainingQty,
            length: lookedUp.length,
            width: lookedUp.width,
            height: lookedUp.height,
            netWeightPerUnit: lookedUp.netWeightPerUnit,
            totalNetWeight: lookedUp.totalNetWeight,
            progressPercentage: lookedUp.progressPercentage,
          )
        : _copyCard(
            card,
            assemblyMark: mark,
            description: '',
            quantity: qty,
            boqItemId: '',
            availableQty: 0,
            usedQty: 0,
            remainingQty: 0,
            length: null,
            width: null,
            height: null,
            netWeightPerUnit: null,
            totalNetWeight: null,
            progressPercentage: 0,
            resetNullables: true,
          );

    newList[index] = updatedCard;
    state = state.copyWith(activeCards: newList);
  }

  void removeCard(int index) {
    final newList = List<AssemblyCardIsar>.from(state.activeCards);
    newList.removeAt(index);
    state = state.copyWith(activeCards: newList);
  }

  void clearError() => state = state.copyWith(error: null);

  BOQStructureItem? _findBoqItemByMark(String mark) {
    final normalized = mark.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final boqState = ref.read(savedBOQProvider);
    for (final boq in boqState.boqs) {
      for (final item in boq.items) {
        if (item.assemblyMark.trim().toLowerCase() == normalized) {
          return item;
        }
      }
    }
    return null;
  }

  AssemblyCardIsar _copyCard(
    AssemblyCardIsar card, {
    String? siteId,
    String? boqItemId,
    String? assemblyMark,
    String? description,
    double? quantity,
    double? availableQty,
    double? usedQty,
    double? remainingQty,
    double? length,
    double? width,
    double? height,
    double? netWeightPerUnit,
    double? totalNetWeight,
    double? progressPercentage,
    bool resetNullables = false,
  }) {
    final updated = AssemblyCardIsar()
      ..isarId = card.isarId
      ..siteId = siteId ?? card.siteId
      ..boqItemId = boqItemId ?? card.boqItemId
      ..assemblyMark = assemblyMark ?? card.assemblyMark
      ..description = description ?? card.description
      ..quantity = quantity ?? card.quantity
      ..availableQty = availableQty ?? card.availableQty
      ..usedQty = usedQty ?? card.usedQty
      ..remainingQty = remainingQty ?? card.remainingQty
      ..length = resetNullables ? length : (length ?? card.length)
      ..width = resetNullables ? width : (width ?? card.width)
      ..height = resetNullables ? height : (height ?? card.height)
      ..netWeightPerUnit = resetNullables
          ? netWeightPerUnit
          : (netWeightPerUnit ?? card.netWeightPerUnit)
      ..totalNetWeight = resetNullables
          ? totalNetWeight
          : (totalNetWeight ?? card.totalNetWeight)
      ..progressPercentage = progressPercentage ?? card.progressPercentage
      ..createdAt = card.createdAt
      ..isSynced = card.isSynced;

    return updated;
  }
}

final dprEntryProvider =
    StateNotifierProvider<DprEntryNotifier, DprEntryState>((ref) {
  return DprEntryNotifier(ref);
});
