// lib/features/modules/all_Modules/offline/data/local/local_material.dart

import 'dart:convert';
import 'package:isar_community/isar.dart';
import '../../../dpr_insu/model/card_form_State.dart';
import '../../../dpr_insu/model/eqip_insu.dart';
import '../../../dpr_insu/model/piping_insu.dart';
import '../../../dpr_insu/model/field_config.dart' hide FieldEntry;

part 'local_material.g.dart';

@collection
class LocalMaterial {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? serverId;

  /// SCOPE
  late String siteId;
  late String domain;       // insulation | mechanical
  late String designation;  // piping | equipment

  /// MATERIAL SETUP DATA (synced from server, not user-editable)
  String? materialCode;
  String? calculationType;
  String? fieldConfigJson;        // FieldConfig JSON from server
  String? calculationConfigJson;  // CalculationConfig JSON from server
  bool isDefault = false;
  int displayOrder = 0;
  String? fieldValuesJson;

  /// LEGACY FIELDS (backward compat)
  int qty = 0;
  double length = 0;
  String? size;
  String? sizeUom;
  String remarks = '';
  double circumference = 0;
  double zHeight = 0;
  String? materialDataJson;       // Full material toJson() snapshot

  /// ───────────────────────────────────────────────
  /// CARD-LEVEL FORM STATE (new — isolated per card)
  ///
  /// Stores the CardFormState as JSON.
  /// Structure:
  /// {
  ///   "geometryMode": "DIAMETER",
  ///   "fieldEntries": {
  ///     "length":        { "value": 100, "unit": "MM" },
  ///     "diameter":      { "value": 50,  "unit": "MM" },
  ///     "circumference": { "value": null, "unit": "MM" },
  ///     "quantity":      { "value": 1,   "unit": "NOS" }
  ///   },
  ///   "customLabels": { "length": "My Length" }
  /// }
  ///
  /// This is NEVER shared between cards. Each LocalMaterial row
  /// stores its own independent form state.
  /// ───────────────────────────────────────────────
  String? cardFormStateJson;

  /// DATA
  late String name;
  String? uom;
  List<String> images = [];

  /// SYNC
  bool isDirty = false;
  bool isDeleted = false;
  DateTime updatedAt = DateTime.now();
}

// ─────────────────────────────────────────────────
// EXTENSION: Convert LocalMaterial ↔ domain models
// ─────────────────────────────────────────────────
extension LocalMaterialMapper on LocalMaterial {

  // ── Read card-form-state ──────────────────────

  /// Deserialize the persisted CardFormState for this card.
  /// Returns null if none saved yet.
  CardFormState? get savedCardFormState {
    if (cardFormStateJson == null || cardFormStateJson!.isEmpty) return null;
    try {
      return CardFormState.fromJson(
          jsonDecode(cardFormStateJson!) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

// In local_material.dart
  PipingMaterial toPiping() {
    // 1️⃣ Prefer full materialDataJson snapshot
    if (materialDataJson != null && materialDataJson!.isNotEmpty) {
      try {
        final m = PipingMaterial.fromJson(
            jsonDecode(materialDataJson!) as Map<String, dynamic>);

        // ✅ FIX: Always override name AND materialCode with local DB values
        final updated = m.copyWith(
          name: name.isNotEmpty ? name : m.name,
          image: images.isNotEmpty ? images : m.image,  // ✅ Preserve images
          materialCode: materialCode ?? m.materialCode,
          cardFormState: savedCardFormState,
          displayOrder: displayOrder,
        );

        return updated;
      } catch (_) {}
    }

    // 2️⃣ Fallback: construct from individual fields
    return PipingMaterial(
      id: serverId ?? id.toString(),
      name: name,  // ✅ This is correct
      image: images,
      uom: uom ?? '',
      materialCode: materialCode,
      cardFormState: savedCardFormState,
      size: size ?? '',
      sizeUom: sizeUom ?? 'inch',
      qty: qty,
      length: length,
      circumference: circumference,
      circumference1: 0,
      circumference2: 0,
      zHeight: zHeight,
      SlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: remarks,
      displayOrder: displayOrder,
    );
  }

  EquipmentMaterial toEquipment() {
    // 1️⃣ Prefer full materialDataJson snapshot
    if (materialDataJson != null && materialDataJson!.isNotEmpty) {
      try {
        final m = EquipmentMaterial.fromJson(
            jsonDecode(materialDataJson!) as Map<String, dynamic>);

        // ✅ FIX: Always override name AND materialCode with local DB values
        final updated = m.copyWith(
          name: name.isNotEmpty ? name : m.name,
          image: images.isNotEmpty ? images : m.image,  // ✅ Preserve images
          materialCode: materialCode ?? m.materialCode,
          cardFormState: savedCardFormState,
          displayOrder: displayOrder,
        );

        return updated;
      } catch (_) {}
    }

    // 2️⃣ Fallback
    return EquipmentMaterial(
      id: serverId ?? id.toString(),
      name: name,  // ✅ This is correct
      image: images,
      uom: uom ?? '',
      materialCode: materialCode,
      cardFormState: savedCardFormState,
      qty: qty,
      length: length,
      circumference: circumference,
      circumference1: 0,
      circumference2: 0,
      zHeight: zHeight,
      SlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: remarks,
      displayOrder: displayOrder,
    );
  }
}
