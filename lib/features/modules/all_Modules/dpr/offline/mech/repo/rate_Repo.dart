import 'dart:convert';

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

    // variants for those materials
    final materialIds = mats.map((m) => m.materialId).toList();

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
    final lineItems = mats.map((m) {
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
        uoms: const [], mocsWithImages: [], floorsWithImages: [],
      );
    } else {
      detected = DetectedFields.fromJson(jsonDecode(raw));
    }
    print("🧠 analysis = ${analysisIsar.rateFileId}");
    print("📦 materials count = ${mats.length}");


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

    for (final m in analysis.lineItems) {
      final material = RateFileMaterialIsar()
        ..siteId = siteId
        ..rawMaterialName=m.rawMaterialName
        ..normalizedMaterialName=m.normalizedMaterialName
        ..uom = m.uom
        ..rateFileId = analysis.id
        ..materialId = m.id
        ..materialName = m.MaterialName
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
    final variants = await isar.rateVariantIsars
        .filter()
        .siteIdEqualTo(siteId)
        .findAll();

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

  // ---------------------------------------------------------------------------
  // ✅ CONVERTERS: ISAR -> YOUR MODELS
  // ---------------------------------------------------------------------------

  RateVariant _variantFromIsar(RateVariantIsar v) {
    return RateVariant(
      moc: v.moc,
      floor: v.floor,
      uom: v.uom,
      rate: v.rate,
      remarks: v.remarks,
      sizeRange: null, materialMasterId: v.materialId, mocId: v.moc, sizeRangeId: '', thicknessRangeId: '', floorId: '', elevationId: '', elevation: '',
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
      MaterialName: m.materialName,
      rawMaterialName: m.rawMaterialName.isNotEmpty
          ? m.rawMaterialName
          : m.materialName,

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
      dynamicFields: dynamicFields,   // 🔥
    );

  }
}
