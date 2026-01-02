import '../models/pipingModel.dart';
import '../models/equipmentModel.dart';

/// ---------------------------------------------------------------------------
/// MATERIAL SYNC SERVICE
/// ---------------------------------------------------------------------------
/// - Syncs local template materials with server materials
/// - Replaces local IDs with server IDs
/// - Merges server-only materials into local list
/// - Safe for DPR, Edit, View, All Materials pages
/// ---------------------------------------------------------------------------

class MaterialSyncService {
  /// Generates a stable key to match local ↔ server materials
  static String _materialKey({
    required String materialName,
    required String designation,
    required String uom,
    required String calculationCategory,
  }) {
    return '${designation.toLowerCase()}::'
        '${materialName.trim().toLowerCase()}::'
        '${uom.toLowerCase()}::'
        '${calculationCategory.toLowerCase()}';
  }

  // ===========================================================================
  // PIPING
  // ===========================================================================
  static List<PipingItem> syncPiping({
    required List<PipingItem> local,
    required List<PipingItem> server,
  }) {
    _debugPrintList(
      'PIPING – LOCAL BEFORE SYNC',
      local,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'uom': m.uom,
        'qty': m.qty,
        'calc': m.calculationCategory,
      },
    );

    _debugPrintList(
      'PIPING – SERVER',
      server,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'uom': m.uom,
        'qty': m.qty,
        'calc': m.calculationCategory,
      },
    );

    final serverMap = {
      for (final s in server)
        _materialKey(
          materialName: s.materialName,
          designation: 'piping',
          uom: s.uom,
          calculationCategory: s.calculationCategory,
        ): s
    };

    final usedKeys = <String>{};

    final updatedLocal = local.map((l) {
      final key = _materialKey(
        materialName: l.materialName,
        designation: 'piping',
        uom: l.uom,
        calculationCategory: l.calculationCategory,
      );

      usedKeys.add(key);

      if (serverMap.containsKey(key)) {
        final s = serverMap[key]!;
        print('✅ MATCHED PIPING → ${l.materialName}');

        return l.copyWith(
          id: s.id,
          qty: s.qty,
          length: s.length,
          rmt: s.rmt,
          diameter: s.diameter,
          weight: s.weight,
          power: s.power,
          remarks: s.remarks,
          moc: s.moc,
          size: s.size,
          location: s.location,
          plant: s.plant
        );
      }

      print('⚠️ NO SERVER MATCH → ${l.materialName}');
      return l;
    }).toList();

    final serverOnly = server.where((s) {
      final key = _materialKey(
        materialName: s.materialName,
        designation: 'piping',
        uom: s.uom,
        calculationCategory: s.calculationCategory,
      );
      return !usedKeys.contains(key);
    }).toList();

    if (serverOnly.isNotEmpty) {
      _debugPrintList(
        'PIPING – SERVER ONLY (ADDED)',
        serverOnly,
            (m) => {
          'id': m.id,
          'name': m.materialName,
          'uom': m.uom,
        },
      );
    }

    final serverOnlyMapped = serverOnly.map((s) {
      return s.copyWith(
        image: s.image, // server has no assets
      );
    }).toList();

    final merged = [...updatedLocal, ...serverOnlyMapped];


    _debugPrintList(
      'PIPING – FINAL MERGED',
      merged,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'uom': m.uom,
        'qty': m.qty,
      },
    );

    _assertIds(merged, (m) => m.id, 'Piping');

    return merged;
  }

  // ===========================================================================
  // EQUIPMENT
  // ===========================================================================

  static List<EquipmentItem> syncEquipment({
    required List<EquipmentItem> local,
    required List<EquipmentItem> server,
  }) {
    final serverMap = {
      for (final s in server)
        _materialKey(
          materialName: s.materialName,
          designation: 'equipment',
          uom: s.uom,
          calculationCategory: s.calculationCategory,
        ): s
    };

    final usedKeys = <String>{};

    final updatedLocal = local.map((l) {
      final key = _materialKey(
        materialName: l.materialName,
        designation: 'equipment',
        uom: l.uom,
        calculationCategory: l.calculationCategory,
      );

      usedKeys.add(key);

      if (serverMap.containsKey(key)) {
        final s = serverMap[key]!;
        return l.copyWith(
          id: s.id,
          qty: s.qty,
          weight: s.weight,
          power: s.power,
          remarks: s.remarks,
          moc: s.moc,
          size: s.size,
          location: s.location,
          plant: s.plant,
        );
      }
      return l;
    }).toList();

    final serverOnly = server.where((s) {
      final key = _materialKey(
        materialName: s.materialName,
        designation: 'equipment',
        uom: s.uom,
        calculationCategory: s.calculationCategory,
      );
      return !usedKeys.contains(key);
    }).toList();

    final merged = [...updatedLocal, ...serverOnly];

    _assertIds(merged, (m) => m.id, 'Equipment');

    return merged;
  }

  // ===========================================================================
  // SAFETY CHECK
  // ===========================================================================

  static void _assertIds<T>(
      List<T> list,
      String Function(T) idGetter,
      String type,
      ) {
    assert(
    list.every((m) => idGetter(m).isNotEmpty),
    '❌ $type material has empty ID after sync',
    );
  }
  static void _debugPrintList<T>(
      String title,
      List<T> list,
      Map<String, dynamic> Function(T) mapper,
      ) {
    print('========== $title (${list.length}) ==========');
    for (final item in list) {
      print(mapper(item));
    }
    print('=======================================');
  }

}

