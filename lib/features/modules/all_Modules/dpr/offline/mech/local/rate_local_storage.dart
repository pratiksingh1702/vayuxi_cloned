import 'dart:convert';
import 'package:isar_community/isar.dart';

import '../../../models/rate_file_models.dart';
import '../isar/rate_file_isar.dart';

class RateLocalStorage {
  final Isar isar;
  RateLocalStorage(this.isar);

  Stream<List<RateFileMaterialIsar>> watchMaterials(String siteId) {
    return isar.rateFileMaterialIsars
        .filter()
        .siteIdEqualTo(siteId)
        .watch(fireImmediately: true);
  }

  Future<void> saveRateFile({
    required String siteId,
    required String rateFileId,
    required String fileName,
    required String status,
    required String uploadDate,
    required DetectedFields detectedFields, // ✅ NEW
  }) async {
    final entity = RateFileAnalysisIsar()
      ..siteId = siteId
      ..rateFileId = rateFileId
      ..fileName = fileName
      ..status = status
      ..uploadDate = uploadDate
      ..syncedAt = DateTime.now()
      ..detectedFieldsJson = jsonEncode(detectedFields.toJson());


    await isar.writeTxn(() async {
      await isar.rateFileAnalysisIsars.put(entity);
    });
  }
  Map<String, dynamic> _detectedFieldsToJson(DetectedFields d) {
    return {
      'hasFloor': d.hasFloor,
      'hasElevation': d.hasElevation,
      'hasMoc': d.hasMoc,
      'hasSize': d.hasSize,
      'hasHP': d.hasHP,
      'hasThickness': d.hasThickness,
      'hasWeight': d.hasWeight,
      'hasPower': d.hasPower,
      'hasDiameter': d.hasDiameter,
      'floors': d.floors,
      'elevations': d.elevations,
      'mocs': d.mocs,
      'sizes': d.sizes,
      'thicknesses': d.thicknesses,
      'uoms': d.uoms,
    };
  }



  Future<void> saveMaterialsAndVariants({
    required String siteId,
    required String rateFileId,
    required List<RateFileMaterialIsar> materials,
    required List<RateVariantIsar> variants,
  }) async {
    await isar.writeTxn(() async {
      await isar.rateFileMaterialIsars.putAll(materials);
      await isar.rateVariantIsars.putAll(variants);
    });
  }

  Future<List<RateVariantIsar>> getVariants({
    required String siteId,
    required String materialId,
  }) async {
    return await isar.rateVariantIsars
        .filter()
        .siteIdEqualTo(siteId)
        .materialIdEqualTo(materialId)
        .findAll();
  }
}
