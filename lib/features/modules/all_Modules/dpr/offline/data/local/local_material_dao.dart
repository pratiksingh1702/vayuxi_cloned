// lib/features/modules/all_Modules/offline/data/local/local_material_dao.dart

import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:untitled2/core/local/isar_db.dart';

import '../../../dpr_insu/model/card_form_State.dart';
import '../../../dpr_insu/model/field_config.dart';
import '../../../dpr_insu/model/material_setup.dart';
import '../../../dpr_insu/model/eqip_insu.dart';
import '../../../dpr_insu/model/piping_insu.dart';
import 'isar_db.dart';
import 'local_material.dart';

class LocalMaterialDao {
  Isar get _isar => AppIsarDB.isar;

  // ─────────────────────────────────────────────
  // BASIC CRUD
  // ─────────────────────────────────────────────

  Future<void> upsertBatch(List<LocalMaterial> materials) async {
    await _isar.writeTxn(() async {
      await _isar.localMaterials.putAll(materials);
    });
  }
  Future<LocalMaterial?> findByServerId(String serverId) async {
    return await _isar.localMaterials
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
  }
  // In local_material_dao.dart — add this method

  Future<void> updateMaterialImage({
    required String serverId,
    required List<String> images,
  }) async {
    final material = await _isar.localMaterials
        .filter()
        .serverIdEqualTo(serverId)
        .findFirst();
    if (material == null) return;

    await _isar.writeTxn(() async {
      material.images = images;
      material.updatedAt = DateTime.now();
      // isDirty stays false — we just synced from server
      await _isar.localMaterials.put(material);
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
          .sortByDisplayOrder()
          .watch(fireImmediately: true);
    }

    return query
        .sortByDisplayOrder()
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
      return query.designationEqualTo(designation).findAll();
    }

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

  // ─────────────────────────────────────────────
  // CARD FORM STATE — PER-CARD ISOLATED PERSISTENCE
  // ─────────────────────────────────────────────

  /// Persist the card-level form state for a single material row.
  ///
  /// [isarId] is the local Isar primary key (LocalMaterial.id).
  /// [state] is the fully isolated CardFormState for that card.
  ///
  /// This NEVER touches another card's row — isolation guaranteed.
  Future<void> saveCardFormState({
    required int isarId,
    required CardFormState state,
  }) async {
    final material = await _isar.localMaterials.get(isarId);
    if (material == null) return;

    await _isar.writeTxn(() async {
      material.cardFormStateJson = jsonEncode(state.toJson());
      material.isDirty = true;
      material.updatedAt = DateTime.now();
      await _isar.localMaterials.put(material);
    });
  }

  /// Read back the persisted CardFormState for a card.
  /// Returns null if not yet saved.
  Future<CardFormState?> loadCardFormState(int isarId) async {
    final material = await _isar.localMaterials.get(isarId);
    if (material?.cardFormStateJson == null) return null;
    try {
      return CardFormState.fromJson(
          jsonDecode(material!.cardFormStateJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // MATERIAL SETUP SYNC
  // ─────────────────────────────────────────────

  /// Sync MaterialSetup definitions from the server into local DB.
  /// Each setup row stores the FieldConfig (which drives card rendering)
  /// but does NOT touch the per-card cardFormStateJson.
  Future<void> syncMaterialSetup({
    required String siteId,
    required List<MaterialSetup> materialSetups,
  }) async {
    final localMaterials = <LocalMaterial>[];

    for (final setup in materialSetups) {
      // Find by serverId so we don't duplicate
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
      localMaterial.fieldConfigJson = jsonEncode(setup.fieldConfig.toJson());

      if (setup.calculationConfig != null) {
        localMaterial.calculationConfigJson =
            jsonEncode(setup.calculationConfig!.toJson());
      }

      if (setup.isConstants != null) {
        localMaterial.materialDataJson = jsonEncode(setup.isConstants);
      }

      localMaterial.updatedAt = DateTime.now();
      localMaterial.isDirty = false;
      // ⚠️ Do NOT touch cardFormStateJson — that's card-local user data

      localMaterials.add(localMaterial);
    }

    await upsertBatch(localMaterials);
  }

  /// Get MaterialSetup definitions from local DB.
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
          ? FieldConfig.fromJson(
          jsonDecode(local.fieldConfigJson!) as Map<String, dynamic>)
          : FieldConfig(
        fields: [],
        unitDropdowns: UnitDropdowns.fromJson({}),
        defaults: FieldDefaults.fromJson({}),
        ui: UiConfig.fromJson({}),
      ),
      calculationConfig: local.calculationConfigJson != null
          ? CalculationConfig.fromJson(
          jsonDecode(local.calculationConfigJson!) as Map<String, dynamic>)
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

  // ─────────────────────────────────────────────
  // LEGACY: materialDataJson convenience helpers
  // ─────────────────────────────────────────────

  Future<void> storeFieldValues({
    required String materialId,
    required Map<String, dynamic> fieldValues,
  }) async {
    final material = await _isar.localMaterials
        .filter()
        .serverIdEqualTo(materialId)
        .findFirst();
    if (material == null) return;

    await _isar.writeTxn(() async {
      material.fieldValuesJson = jsonEncode(fieldValues);
      material.isDirty = true;
      material.updatedAt = DateTime.now();
      await _isar.localMaterials.put(material);
    });
  }

  Future<Map<String, dynamic>?> getFieldValues(String materialId) async {
    final material = await _isar.localMaterials
        .filter()
        .serverIdEqualTo(materialId)
        .findFirst();
    if (material?.fieldValuesJson == null) return null;
    return jsonDecode(material!.fieldValuesJson!) as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────
  // CONVERTERS: LocalMaterial → domain models with CardFormState
  // ─────────────────────────────────────────────

  EquipmentMaterial toEquipmentMaterial(LocalMaterial local) {
    // Use extension — reads cardFormStateJson automatically
    return local.toEquipment();
  }

  PipingMaterial toPipingMaterial(LocalMaterial local) {
    // Use extension — reads cardFormStateJson automatically
    return local.toPiping();
  }
}