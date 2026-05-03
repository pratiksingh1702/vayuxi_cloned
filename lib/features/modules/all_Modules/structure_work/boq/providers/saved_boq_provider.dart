import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:untitled2/core/local/isar_db.dart';
import '../isar/boq_structure_isar.dart';
import '../models/boq_structure_model.dart';
import '../repository/boq_structure_repository.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/providers/boq_structure_provider.dart';

class SavedBOQState {
  final List<BOQStructure> boqs;
  final bool isLoading;
  final String? error;

  SavedBOQState({
    this.boqs = const [],
    this.isLoading = false,
    this.error,
  });

  SavedBOQState copyWith({
    List<BOQStructure>? boqs,
    bool? isLoading,
    String? error,
  }) {
    return SavedBOQState(
      boqs: boqs ?? this.boqs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SavedBOQNotifier extends StateNotifier<SavedBOQState> {
  final BOQStructureRepository _repo;
  SavedBOQNotifier(this._repo) : super(SavedBOQState());

  final _isar = AppIsarDB.isar;
  final Map<String, String> _typeDescByItemId = {};

  /// Fetch from Isar first, then sync with online
  Future<void> fetchAndSync(String siteId) async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Load from Isar
      await _loadFromLocal(siteId);

      // 2. Sync Metadata with Online
      final remoteBOQs = await _repo.getAllBOQs(siteId);

      // 3. Update Isar Metadata
      await _isar.writeTxn(() async {
        for (var boq in remoteBOQs) {
          final isarBOQ = _mapModelToIsar(boq, siteId);
          await _isar.bOQStructureIsars.putByServerId(isarBOQ);
        }
      });

      // 4. Optionally Sync Items for each BOQ (in background or if needed)
      // For now, let's just sync the first one or when requested.
      if (remoteBOQs.isNotEmpty) {
        await syncItems(siteId, remoteBOQs.first.id);
      }

      await _loadFromLocal(siteId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> syncItems(String siteId, String boqId) async {
    try {
      final detail = await _repo.getBOQItems(siteId, boqId);

      for (final item in detail.items) {
        if (item.id.isNotEmpty) {
          _typeDescByItemId[item.id] = item.typeDescription;
        }
      }

      await _isar.writeTxn(() async {
        final isarBOQ = await _isar.bOQStructureIsars
            .filter()
            .serverIdEqualTo(boqId)
            .findFirst();
        if (isarBOQ == null) return;

        // Clear existing items for this BOQ to avoid duplicates
        await _isar.bOQItemIsars.filter().boqServerIdEqualTo(boqId).deleteAll();

        final isarItems =
            detail.items.map((item) => _mapItemToIsar(item, boqId)).toList();
        await _isar.bOQItemIsars.putAll(isarItems);

        isarBOQ.items.addAll(isarItems);
        await isarBOQ.items.save();
      });
    } catch (e) {
      print("Error syncing BOQ items: $e");
    }
  }

  Future<void> _loadFromLocal(String siteId) async {
    final localBOQs = await _isar.bOQStructureIsars
        .where()
        .filter()
        .siteIdEqualTo(siteId)
        .findAll();

    final List<BOQStructure> models = [];
    for (var isar in localBOQs) {
      await isar.items.load();
      models.add(_mapIsarToModel(isar));
    }

    state = state.copyWith(boqs: models, isLoading: false);
  }

  BOQStructure _mapIsarToModel(BOQStructureIsar isar) {
    return BOQStructure(
      id: isar.serverId,
      boqName: isar.boqName,
      boqNumber: isar.boqNumber,
      siteId: isar.siteId,
      items: isar.items.map((e) => _mapIsarItemToModel(e)).toList(),
      totalQuantity: isar.totalQuantity,
      totalNetWeight: isar.totalNetWeight,
      totalItems: isar.totalItems,
      usedQuantity: isar.usedQuantity,
      remainingQuantity: isar.remainingQuantity,
      progressPercentage: isar.progressPercentage,
      status: isar.status,
      uploadedAt: isar.uploadedAt?.toIso8601String(),
    );
  }

  BOQStructureItem _mapIsarItemToModel(BOQItemIsar isar) {
    return BOQStructureItem(
      id: isar.serverId,
      assemblyMark: isar.assemblyMark,
      typeDescription: _typeDescByItemId[isar.serverId] ?? '',
      quantity: isar.quantity,
      availableQty: isar.availableQty,
      usedQty: isar.usedQty,
      remainingQty: isar.remainingQty,
      length: isar.length,
      width: isar.width,
      height: isar.height,
      netWeightPerUnit: isar.netWeightPerUnit,
      totalNetWeight: isar.totalNetWeight,
      progressPercentage: isar.progressPercentage,
    );
  }

  BOQStructureIsar _mapModelToIsar(BOQStructure boq, String siteId) {
    return BOQStructureIsar()
      ..serverId = boq.id
      ..siteId = siteId
      ..boqName = boq.boqName
      ..boqNumber = boq.boqNumber
      ..totalQuantity = boq.totalQuantity
      ..totalNetWeight = boq.totalNetWeight
      ..totalItems = boq.totalItems
      ..usedQuantity = boq.usedQuantity
      ..remainingQuantity = boq.remainingQuantity
      ..progressPercentage = boq.progressPercentage
      ..status = boq.status
      ..uploadedAt =
          boq.uploadedAt != null ? DateTime.tryParse(boq.uploadedAt!) : null;
  }

  BOQItemIsar _mapItemToIsar(BOQStructureItem item, String boqId) {
    return BOQItemIsar()
      ..serverId = item.id
      ..boqServerId = boqId
      ..assemblyMark = item.assemblyMark
      ..quantity = item.quantity
      ..availableQty = item.availableQty
      ..usedQty = item.usedQty
      ..remainingQty = item.remainingQty
      ..length = item.length
      ..width = item.width
      ..height = item.height
      ..netWeightPerUnit = item.netWeightPerUnit
      ..totalNetWeight = item.totalNetWeight
      ..progressPercentage = item.progressPercentage;
  }
}

final savedBOQProvider =
    StateNotifierProvider<SavedBOQNotifier, SavedBOQState>((ref) {
  return SavedBOQNotifier(ref.read(boqStructureRepositoryProvider));
});
