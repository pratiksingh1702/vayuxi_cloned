import 'dart:convert';
import 'dart:math' as math;

import 'package:isar_community/isar.dart';

import '../../../providers/service/rate_upload_material_dpr.dart';
import '../../../models/rate_file_models.dart';
import '../isar/dynamic_fields.dart';
import '../isar/rate_file_isar.dart';
import '../local/rate_local_storage.dart';

class RateRepository {
  final Isar isar;
  final RateLocalStorage local;

  RateRepository(this.isar) : local = RateLocalStorage(isar);

  /// ✅ UI watches isar stream only (for materials list UI if needed)
  Stream<List<RateFileMaterialIsar>> watchMaterials(String siteId) =>
      local.watchMaterials(siteId);
  Stream<RateFileAnalysis?> watchRateAnalysis(String siteId) async* {
    // watch analysis entity
    yield* isar.rateFileAnalysisIsars
        .filter()
        .siteIdEqualTo(siteId)
        .sortBySyncedAtDesc()
        .watch(fireImmediately: true)
        .asyncMap((list) async {
      if (list.isEmpty) return null;
      return await getCachedRateFileAnalysis(siteId);
    });
  }

  // ---------------------------------------------------------------------------
  // ✅ OFFLINE CACHE READERS (IMPORTANT)
  // ---------------------------------------------------------------------------

  /// ✅ Get cached full RateFileAnalysis from Isar.
  /// This is the offline-first core.
  Future<RateFileAnalysis?> getCachedRateFileAnalysis(String siteId) async {
    // latest analysis for site
    final analysisIsar = await isar.rateFileAnalysisIsars
        .filter()
        .siteIdEqualTo(siteId)
        .sortBySyncedAtDesc()
        .findFirst();

    if (analysisIsar == null) return null;

    // materials for this rateFileId
    final mats = await isar.rateFileMaterialIsars
        .filter()
        .siteIdEqualTo(siteId)
        .rateFileIdEqualTo(analysisIsar.rateFileId)
        .findAll();

    final sortedMats = _sortedByDisplayOrder(mats);
    if (!_hasContiguousDisplayOrder(sortedMats)) {
      await _normalizeDisplayOrder(sortedMats);
    }

    // variants for those materials
    final materialIds = sortedMats.map((m) => m.materialId).toList();

    final vars = await isar.rateVariantIsars
        .filter()
        .siteIdEqualTo(siteId)
        .anyOf(materialIds, (q, id) => q.materialIdEqualTo(id))
        .findAll();

    // group variants by materialId
    final variantsByMaterial = <String, List<RateVariant>>{};
    for (final v in vars) {
      final model = _variantFromIsar(v);
      variantsByMaterial.putIfAbsent(v.materialId, () => []);
      variantsByMaterial[v.materialId]!.add(model);
    }

    // build lineItems
    final lineItems = sortedMats.map((m) {
      final variants = variantsByMaterial[m.materialId] ?? [];
      return _materialFromIsar(m, variants);
    }).toList();

    DetectedFields detected;

    final raw = analysisIsar.detectedFieldsJson;

    if (raw == null || raw.isEmpty) {
      // ✅ fallback for old cached rows
      detected = DetectedFields(
        hasFloor: false,
        hasElevation: false,
        hasMoc: false,
        hasSize: false,
        hasHP: false,
        hasThickness: false,
        hasWeight: false,
        hasPower: false,
        hasDiameter: false,
        floors: const [],
        elevations: const [],
        mocs: const [],
        sizes: const [],
        thicknesses: const [],
        uoms: const [],
        mocsWithImages: [],
        floorsWithImages: [],
      );
    } else {
      detected = DetectedFields.fromJson(jsonDecode(raw));
    }
    print("🧠 analysis = ${analysisIsar.rateFileId}");
    print("📦 materials count = ${sortedMats.length}");

    return RateFileAnalysis(
      id: analysisIsar.rateFileId,
      name: '',
      fileName: analysisIsar.fileName,
      status: analysisIsar.status,
      uploadDate: DateTime.tryParse(analysisIsar.uploadDate) ?? DateTime.now(),
      company: {},
      site: {},
      uploadedBy: {},
      lineItems: lineItems,
      detectedFields: detected, // ✅ FIXED
    );
  }

  /// ✅ quick cached variants by material (used by provider `rateVariantsByMaterialProvider`)
  Future<List<RateVariant>> getCachedVariantsByMaterial({
    required String siteId,
    required String materialId,
  }) async {
    final vars = await isar.rateVariantIsars
        .filter()
        .siteIdEqualTo(siteId)
        .materialIdEqualTo(materialId)
        .findAll();

    return vars.map(_variantFromIsar).toList();
  }

  // ---------------------------------------------------------------------------
  // ✅ SYNC FROM API (CACHE UPDATE)
  // ---------------------------------------------------------------------------

  /// Background sync: updates Isar only
  Future<void> syncRateFile(String siteId) async {
    final analysis = await RateUploadApi.fetchRateFileAnalysis(siteId: siteId);

    final existingMaterials = await isar.rateFileMaterialIsars
        .filter()
        .siteIdEqualTo(siteId)
        .findAll();
    final existingOrderByMaterialId = <String, int>{
      for (final m in existingMaterials) m.materialId: m.displayOrder,
    };
    var nextDisplayOrder = existingMaterials.isEmpty
        ? 0
        : existingMaterials.map((m) => m.displayOrder).reduce(math.max) + 1;

    await local.saveRateFile(
      siteId: siteId,
      rateFileId: analysis.id,
      fileName: analysis.fileName,
      status: analysis.status,
      uploadDate: analysis.uploadDate.toString(),
      detectedFields: analysis.detectedFields, // ✅ critical
    );

    final materials = <RateFileMaterialIsar>[];
    final variants = <RateVariantIsar>[];
//     for (final m in analysis.lineItems) {
//
//       print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
//       print("📦 MATERIAL: ${m.MaterialName}");
//       print("🆔 ID: ${m.id}");
//       print("🧠 Raw: ${m.rawMaterialName}");
//       print("🧠 Normalized: ${m.normalizedMaterialName}");
//       print("🔢 Dynamic Fields Count: ${m.dynamicFields.length}");
//
//       if (m.dynamicFields.isEmpty) {
//         print("⚠️ NO DYNAMIC FIELDS");
//       } else {
//         for (final f in m.dynamicFields) {
//           print("""
//   🔸 FIELD
//      key: ${f.key}
//      label: ${f.label}
//      unit: ${f.unit}
//      displayText: ${f.displayText}
//      value: ${f.value}
// """);
//         }
//       }}

    for (var index = 0; index < analysis.lineItems.length; index++) {
      final m = analysis.lineItems[index];
      final existingOrder = existingOrderByMaterialId[m.id];
      final resolvedDisplayOrder = m.displayOrder >= 0
          ? m.displayOrder
          : (existingOrder ?? nextDisplayOrder++);

      final material = RateFileMaterialIsar()
        ..siteId = siteId
        ..rawMaterialName = m.rawMaterialName
        ..normalizedMaterialName = m.normalizedMaterialName
        ..uom = m.uom
        ..rateFileId = analysis.id
        ..materialId = m.id
        ..materialName = m.MaterialName
        ..displayOrder = resolvedDisplayOrder
        ..image = m.image
        ..calculationCategory = m.calculationCategory
        ..designationJoined = m.designation.join(',')
        ..approvalStatus = m.approvalStatus
        ..normalizedMoc = m.normalizedMoc
        ..dynamicFields = m.dynamicFields.map((f) {
          return DynamicFieldIsar()
            ..key = f.key
            ..label = f.label
            ..unit = f.unit
            ..displayText = f.displayText
            ..valueJson = f.value == null ? null : jsonEncode(f.value);
        }).toList();

      materials.add(material);

      for (final v in m.availableVariants) {
        // ✅ stable unique key
        final key = "${m.id}|${v.moc}|${v.floor}|${v.uom}|${v.rate}";

        final variant = RateVariantIsar()
          ..siteId = siteId
          ..materialId = m.id
          ..variantKey = key
          ..moc = v.moc
          ..floor = v.floor
          ..uom = v.uom
          ..rate = v.rate
          ..remarks = v.remarks;

        variants.add(variant);
      }
    }

    // ✅ ensure unique variants/materials in input before saving
    final uniqueMaterials = _uniqueMaterials(materials);
    final uniqueVariants = _uniqueVariants(variants);

    await local.saveMaterialsAndVariants(
      siteId: siteId,
      rateFileId: analysis.id,
      materials: uniqueMaterials,
      variants: uniqueVariants,
    );
    await isar.writeTxn(() async {
      final analysis = await isar.rateFileAnalysisIsars
          .filter()
          .siteIdEqualTo(siteId)
          .sortBySyncedAtDesc()
          .findFirst();

      if (analysis != null) {
        analysis.syncedAt = DateTime.now(); // bump
        await isar.rateFileAnalysisIsars.put(analysis);
      }
    });

    // ✅ cleanup stale materials/variants for this site + rateFileId
    await _cleanupStaleRateFile(siteId: siteId, rateFileId: analysis.id);
  }


  // ---------------------------------------------------------------------------
  // ✅ HELPERS: CLEANUP + UNIQUE
  // ---------------------------------------------------------------------------

  List<RateFileMaterialIsar> _uniqueMaterials(List<RateFileMaterialIsar> list) {
    final map = <String, RateFileMaterialIsar>{};
    for (final m in list) {
      map[m.materialId] = m; // last wins
    }
    return map.values.toList();
  }

  List<RateVariantIsar> _uniqueVariants(List<RateVariantIsar> list) {
    final map = <String, RateVariantIsar>{};
    for (final v in list) {
      map[v.variantKey] = v;
    }
    return map.values.toList();
  }

  Future<void> _cleanupStaleRateFile({
    required String siteId,
    required String rateFileId,
  }) async {
    // keep only latest file's materials/variants
    final materials = await isar.rateFileMaterialIsars
        .filter()
        .siteIdEqualTo(siteId)
        .rateFileIdEqualTo(rateFileId)
        .findAll();

    final keepMaterialIds = materials.map((e) => e.materialId).toSet();

    // delete variants not belonging to materials
    final variants =
        await isar.rateVariantIsars.filter().siteIdEqualTo(siteId).findAll();

    final staleVariantIds = <Id>[];
    for (final v in variants) {
      if (!keepMaterialIds.contains(v.materialId)) {
        staleVariantIds.add(v.isarId);
      }
    }

    if (staleVariantIds.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.rateVariantIsars.deleteAll(staleVariantIds);
      });
    }
  }

  Future<void> persistDisplayOrderForSubset({
    required String siteId,
    required List<String> orderedSubsetMaterialIds,
  }) async {
    if (orderedSubsetMaterialIds.length < 2) return;

    final activeAnalysis = await isar.rateFileAnalysisIsars
        .filter()
        .siteIdEqualTo(siteId)
        .sortBySyncedAtDesc()
        .findFirst();
    if (activeAnalysis == null) return;

    final allMaterials = await isar.rateFileMaterialIsars
        .filter()
        .siteIdEqualTo(siteId)
        .rateFileIdEqualTo(activeAnalysis.rateFileId)
        .findAll();

    if (allMaterials.isEmpty) return;

    final sortedAll = _sortedByDisplayOrder(allMaterials);
    final idToMaterial = <String, RateFileMaterialIsar>{
      for (final m in sortedAll) m.materialId: m,
    };

    final subsetSet = orderedSubsetMaterialIds.toSet();
    final subsetIndexes = <int>[];
    for (var i = 0; i < sortedAll.length; i++) {
      if (subsetSet.contains(sortedAll[i].materialId)) {
        subsetIndexes.add(i);
      }
    }

    if (subsetIndexes.length != orderedSubsetMaterialIds.length) {
      return;
    }

    final reorderedSubset = orderedSubsetMaterialIds
        .map((id) => idToMaterial[id])
        .whereType<RateFileMaterialIsar>()
        .toList(growable: false);

    if (reorderedSubset.length != subsetIndexes.length) return;

    for (var i = 0; i < subsetIndexes.length; i++) {
      sortedAll[subsetIndexes[i]] = reorderedSubset[i];
    }

    await _normalizeDisplayOrder(sortedAll);

    await isar.writeTxn(() async {
      activeAnalysis.syncedAt = DateTime.now();
      await isar.rateFileAnalysisIsars.put(activeAnalysis);
    });
  }

  // ---------------------------------------------------------------------------
  // ✅ CONVERTERS: ISAR -> YOUR MODELS
  // ---------------------------------------------------------------------------

  List<RateFileMaterialIsar> _sortedByDisplayOrder(
      List<RateFileMaterialIsar> list) {
    final sorted = List<RateFileMaterialIsar>.from(list);
    sorted.sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      if (byOrder != 0) return byOrder;
      return a.materialId.compareTo(b.materialId);
    });
    return sorted;
  }

  bool _hasContiguousDisplayOrder(List<RateFileMaterialIsar> list) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].displayOrder != i) {
        return false;
      }
    }
    return true;
  }

  Future<void> _normalizeDisplayOrder(List<RateFileMaterialIsar> list) async {
    for (var i = 0; i < list.length; i++) {
      list[i].displayOrder = i;
    }

    await isar.writeTxn(() async {
      await isar.rateFileMaterialIsars.putAll(list);
    });
  }

  RateVariant _variantFromIsar(RateVariantIsar v) {
    return RateVariant(
      moc: v.moc,
      floor: v.floor,
      uom: v.uom,
      rate: v.rate,
      remarks: v.remarks,
      sizeRange: null,
      materialMasterId: v.materialId,
      mocId: v.moc,
      sizeRangeId: '',
      thicknessRangeId: '',
      floorId: '',
      elevationId: '',
      elevation: '',
    );
  }

  RateFileMaterial _materialFromIsar(
    RateFileMaterialIsar m,
    List<RateVariant> variants,
  ) {
    final designation = (m.designationJoined.isEmpty)
        ? <String>[]
        : m.designationJoined
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    List<DynamicField> dynamicFields = m.dynamicFields.map((f) {
      return DynamicField(
        key: f.key,
        label: f.label,
        unit: f.unit,
        displayText: f.displayText,
        value: f.valueJson != null ? jsonDecode(f.valueJson!) : null,
      );
    }).toList();

    return RateFileMaterial(
      id: m.materialId,
      displayOrder: m.displayOrder,
      MaterialName: m.materialName,
      rawMaterialName:
          m.rawMaterialName.isNotEmpty ? m.rawMaterialName : m.materialName,

      normalizedMaterialName: m.normalizedMaterialName.isNotEmpty
          ? m.normalizedMaterialName
          : m.materialName.toLowerCase().trim(),
      image: m.image,
      designation: designation,
      calculationCategory: m.calculationCategory,
      approvalStatus: m.approvalStatus,
      normalizedMoc: m.normalizedMoc,
      availableVariants: variants,

      uom: m.uom,
      materialMasterId: '',
      isDefaultMaterial: false,
      dynamicFields: dynamicFields, // 🔥
    );
  }
}
