import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:untitled2/core/local/isar_db.dart';
import 'isar_db.dart';
import 'local_material.dart';
import '../../dpr_insu/model/material_setup.dart';
import '../../dpr_insu/model/field_config.dart';
import '../../dpr_insu/model/eqip_insu.dart';
import '../../dpr_insu/model/piping_insu.dart';

class LocalMaterialDao {
  Isar get _isar => AppIsarDB.isar;


  Future<void> upsertBatch(List<LocalMaterial> materials) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.putAll(materials);
    });
  }

  Stream<List<LocalMaterial>> watchAll({
    required String siteId,
    required String domain,
    required String designation,
  }) {
    final query = _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .domainEqualTo(domain)
        .isDeletedEqualTo(false);

    if (designation.trim().isNotEmpty) {
      return query
          .designationEqualTo(designation)
          .sortByUpdatedAt()
          .watch(fireImmediately: true);
    }

    // If designation is empty → return both
    return query
        .sortByUpdatedAt()
        .watch(fireImmediately: true);
  }
  Future<List<LocalMaterial>> getAll({
    required String siteId,
    required String domain,
    required String designation,
  }) {

    final query = _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .domainEqualTo(domain)
        .isDeletedEqualTo(false);

    if (designation.trim().isNotEmpty) {
      return query
          .designationEqualTo(designation)
          .findAll();
    }

    // 🔥 return both piping + equipment
    return query.findAll();
  }

  Future<List<LocalMaterial>> dirty(String siteId) {
    return _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<List<LocalMaterial>> deleted(String siteId) {
    return _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .isDeletedEqualTo(true)
        .findAll();
  }

  Future<void> upsert(LocalMaterial m) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.put(m);
    });
  }

  Future<void> markDeleted(LocalMaterial m) async {
    await _isar.writeTxn(() async {
      m.isDeleted = true;
      m.isDirty = true;
      await _isar.localMaterials.put(m);
    });
  }

  Future<void> deleteHard(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.delete(id);
    });
  }

  /// ================================
  /// MATERIAL SETUP SYNC
  /// ================================

  /// Sync MaterialSetup from server to local database
  Future<void> syncMaterialSetup({
    required String siteId,
    required List<MaterialSetup> materialSetups,
  }) async {
    final localMaterials = <LocalMaterial>[];

    for (final setup in materialSetups) {
      final existing = await _isar.localMaterials
          .filter()
          .serverIdEqualTo(setup.id)
          .findFirst();

      final localMaterial = existing ?? LocalMaterial();

      localMaterial.serverId = setup.id;
      localMaterial.siteId = siteId;
      localMaterial.domain = 'insulation';
      localMaterial.designation = setup.designation;
      localMaterial.name = setup.name;
      localMaterial.uom = setup.uom;
      localMaterial.images = setup.image;
      localMaterial.materialCode = setup.materialCode;
      localMaterial.calculationType = setup.calculationType;
      localMaterial.isDefault = setup.isDefault;
      localMaterial.displayOrder = setup.displayOrder;

      // Store field configuration as JSON
      localMaterial.fieldConfigJson = jsonEncode(setup.fieldConfig.toJson());

      // Store calculation config if present
      if (setup.calculationConfig != null) {
        localMaterial.calculationConfigJson =
            jsonEncode(setup.calculationConfig!.toJson());
      }

      // Store isConstants for piping materials
      if (setup.isConstants != null) {
        localMaterial.materialDataJson = jsonEncode(setup.isConstants);
      }

      localMaterial.updatedAt = DateTime.now();
      localMaterial.isDirty = false;

      localMaterials.add(localMaterial);
    }

    await upsertBatch(localMaterials);
  }

  /// Get MaterialSetup from local database
  Future<List<MaterialSetup>> getMaterialSetups({
    required String siteId,
    String? designation,
  }) async {
    final query = _isar.localMaterials
        .filter()
        .siteIdEqualTo(siteId)
        .isDeletedEqualTo(false);

    final List<LocalMaterial> localMaterials;
    if (designation != null && designation.trim().isNotEmpty) {
      localMaterials = await query.designationEqualTo(designation).findAll();
    } else {
      localMaterials = await query.findAll();
    }

    return localMaterials
        .where((m) => m.fieldConfigJson != null)
        .map(_toMaterialSetup)
        .toList();
  }

  /// Convert LocalMaterial to MaterialSetup
  MaterialSetup _toMaterialSetup(LocalMaterial local) {
    return MaterialSetup(
      id: local.serverId ?? local.id.toString(),
      name: local.name,
      materialCode: local.materialCode ?? '',
      image: local.images,
      uom: local.uom ?? '',
      designation: local.designation,
      calculationType: local.calculationType ?? 'AREA',
      fieldConfig: local.fieldConfigJson != null
          ? FieldConfig.fromJson(jsonDecode(local.fieldConfigJson!))
          : FieldConfig(
              fields: [],
              unitDropdowns: UnitDropdowns.fromJson({}),
              defaults: FieldDefaults.fromJson({}),
              ui: UiConfig.fromJson({}),
            ),
      calculationConfig: local.calculationConfigJson != null
          ? CalculationConfig.fromJson(jsonDecode(local.calculationConfigJson!))
          : null,
      isConstants: local.materialDataJson != null
          ? jsonDecode(local.materialDataJson!) as Map<String, dynamic>?
          : null,
      isDefault: local.isDefault,
      displayOrder: local.displayOrder,
      siteId: local.siteId,
      companyId: '',
      createdAt: local.updatedAt,
      updatedAt: local.updatedAt,
    );
  }

  /// Store field values for a DPR material entry
  Future<void> storeFieldValues({
    required String materialId,
    required Map<String, dynamic> fieldValues,
  }) async {
    final material = await _isar.localMaterials
        .filter()
        .serverIdEqualTo(materialId)
        .findFirst();

    if (material != null) {
      await _isar.writeTxn(() async {
        material.fieldValuesJson = jsonEncode(fieldValues);
        material.isDirty = true;
        material.updatedAt = DateTime.now();
        await _isar.localMaterials.put(material);
      });
    }
  }

  /// Get field values for a material
  Future<Map<String, dynamic>?> getFieldValues(String materialId) async {
    final material = await _isar.localMaterials
        .filter()
        .serverIdEqualTo(materialId)
        .findFirst();

    if (material?.fieldValuesJson != null) {
      return jsonDecode(material!.fieldValuesJson!) as Map<String, dynamic>;
    }
    return null;
  }

  /// Update custom labels for a material
  Future<void> updateCustomLabels({
    required String materialId,
    required Map<String, String> customLabels,
  }) async {
    final material = await _isar.localMaterials
        .filter()
        .serverIdEqualTo(materialId)
        .findFirst();

    if (material != null) {
      await _isar.writeTxn(() async {
        // Store custom labels in fieldValuesJson or create a separate field
        final currentFieldValues = material.fieldValuesJson != null
            ? jsonDecode(material.fieldValuesJson!) as Map<String, dynamic>
            : <String, dynamic>{};

        currentFieldValues['customLabels'] = customLabels;
        material.fieldValuesJson = jsonEncode(currentFieldValues);
        material.isDirty = true;
        material.updatedAt = DateTime.now();
        await _isar.localMaterials.put(material);
      });
    }
  }

  /// Convert LocalMaterial to EquipmentMaterial with field values
  EquipmentMaterial toEquipmentMaterial(LocalMaterial local) {
    Map<String, dynamic>? fieldValuesMap;
    Map<String, String>? customLabels;

    if (local.fieldValuesJson != null) {
      final decoded = jsonDecode(local.fieldValuesJson!) as Map<String, dynamic>;
      fieldValuesMap = Map<String, dynamic>.from(decoded);
      if (decoded.containsKey('customLabels')) {
        customLabels = Map<String, String>.from(decoded['customLabels']);
        fieldValuesMap.remove('customLabels');
      }
    }

    return EquipmentMaterial(
      id: local.serverId ?? local.id.toString(),
      name: local.name,
      image: local.images,
      uom: local.uom ?? '',
      remarks: local.remarks,
      materialCode: local.materialCode,
      fieldValues: fieldValuesMap != null ? FieldValues(fieldValuesMap) : null,
      customLabels: customLabels,
      qty: local.qty,
      length: local.length,
      circumference: local.circumference,
      zHeight: local.zHeight,
    );
  }

  /// Convert LocalMaterial to PipingMaterial with field values
  PipingMaterial toPipingMaterial(LocalMaterial local) {
    Map<String, dynamic>? fieldValuesMap;
    Map<String, String>? customLabels;

    if (local.fieldValuesJson != null) {
      final decoded = jsonDecode(local.fieldValuesJson!) as Map<String, dynamic>;
      fieldValuesMap = Map<String, dynamic>.from(decoded);
      if (decoded.containsKey('customLabels')) {
        customLabels = Map<String, String>.from(decoded['customLabels']);
        fieldValuesMap.remove('customLabels');
      }
    }

    return PipingMaterial(
      id: local.serverId ?? local.id.toString(),
      name: local.name,
      image: local.images,
      uom: local.uom ?? '',
      remarks: local.remarks,
      materialCode: local.materialCode,
      fieldValues: fieldValuesMap != null ? FieldValues(fieldValuesMap) : null,
      customLabels: customLabels,
      size: local.size,
      sizeUom: local.sizeUom,
      qty: local.qty,
      length: local.length,
    );
  }
}
