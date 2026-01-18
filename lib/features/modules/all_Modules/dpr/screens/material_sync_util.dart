import '../models/pipingModel.dart';
import '../models/equipmentModel.dart';

/// ---------------------------------------------------------------------------
/// MATERIAL SYNC SERVICE (Server-First Approach)
/// ---------------------------------------------------------------------------
/// - Server is the ONLY source of truth
/// - Shows ONLY materials that exist on server
/// - Matches server materials with local to get images
/// - All data (qty, weight, etc.) comes from server
/// - Images come from local asset paths
/// ---------------------------------------------------------------------------

class MaterialSyncService {
  /// Generates a stable key to match local ↔ server materials
  static String _materialKey({
    required String materialName,
    required String designation,
    String? uom, // Make optional for matching
    String? calculationCategory, // Make optional for matching
  }) {
    // For matching purposes, we need to be flexible
    // The primary key should be designation + materialName
    return '${designation.toLowerCase()}::'
        '${materialName.trim().toLowerCase()}';
  }

  /// Alternative key for more flexible matching
  static String _flexibleMaterialKey(String materialName, String designation) {
    return '${designation.toLowerCase()}::'
        '${materialName.trim().toLowerCase()}';
  }

  // ===========================================================================
  // PIPING - SERVER FIRST
  // ===========================================================================
  static List<PipingItem> syncPiping({
    required List<PipingItem> local,
    required List<PipingItem> server,
  }) {
    _debugPrintList(
      'PIPING – LOCAL (for image lookup only)',
      local,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'image': m.image,
        'uom': m.uom,
        'calcCat': m.calculationCategory,
      },
    );

    _debugPrintList(
      'PIPING – SERVER (source of truth)',
      server,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'uom': m.uom,
        'qty': m.qty,
        'length': m.length,
        'calcCat': m.calculationCategory,
      },
    );

    // Create multiple lookup maps for flexible matching
    final localMapExact = {
      for (final l in local)
        _materialKey(
          materialName: l.materialName,
          designation: 'piping',
          uom: l.uom,
          calculationCategory: l.calculationCategory,
        ): l
    };

    // Create a more flexible map for matching
    final localMapFlexible = {
      for (final l in local)
        _flexibleMaterialKey(l.materialName, 'piping'): l
    };

    // Process ONLY server materials
    final result = server.map((s) {
      // Try exact match first
      final exactKey = _materialKey(
        materialName: s.materialName,
        designation: 'piping',
        uom: s.uom,
        calculationCategory: s.calculationCategory,
      );

      // Try flexible match
      final flexibleKey = _flexibleMaterialKey(s.materialName, 'piping');

      PipingItem? matchedLocal;

      // Check exact match
      if (localMapExact.containsKey(exactKey)) {
        matchedLocal = localMapExact[exactKey]!;
        print('✅ EXACT MATCH PIPING → ${s.materialName} (uom: ${s.uom})');
      }
      // Fall back to flexible match
      else if (localMapFlexible.containsKey(flexibleKey)) {
        matchedLocal = localMapFlexible[flexibleKey]!;
        print('🔄 FLEXIBLE MATCH PIPING → ${s.materialName} (server uom: ${s.uom}, local uom: ${matchedLocal.uom})');
      } else {
        print('⚠️ NO LOCAL MATCH → ${s.materialName} (using server image)');
      }

      // Use ALL data from server, ONLY image from local if matched
      if (matchedLocal != null && matchedLocal.image != null && matchedLocal.image!.isNotEmpty) {
        print('📸 Using local image for ${s.materialName}');
        return s.copyWith(
          image: matchedLocal.image,
          // Keep all server data including UOM
          uom: s.uom,
          length: s.length,
          calculationCategory: s.calculationCategory,
          remarks: s.remarks,
        );
      }
      if (s.image.isNotEmpty) {
        return s; // <-- THIS was missing
      }

      // If no match or no image, return server item as-is
      return s.copyWith(
        // Ensure we keep server UOM
        image: s.image,
        uom: s.uom,length: s.length,
        calculationCategory: s.calculationCategory,
      );
    }).toList();

    _debugPrintList(
      'PIPING – FINAL (server materials only)',
      result,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'image': m.image,
        'uom': m.uom, // Check this field!
        'qty': m.qty,
        'length': m.length,
        'calcCat': m.calculationCategory,
      },
    );

    _assertIds(result, (m) => m.id, 'Piping');

    return result;
  }

  // ===========================================================================
  // EQUIPMENT - SERVER FIRST
  // ===========================================================================
  static List<EquipmentItem> syncEquipment({
    required List<EquipmentItem> local,
    required List<EquipmentItem> server,
  }) {
    _debugPrintList(
      'EQUIPMENT – LOCAL (for image lookup only)',
      local,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'image': m.image,
        'uom': m.uom,
        'calcCat': m.calculationCategory,
      },
    );

    _debugPrintList(
      'EQUIPMENT – SERVER (source of truth)',
      server,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'uom': m.uom, // Check this field!
        'qty': m.qty,
        'weight': m.weight,
        'calcCat': m.calculationCategory,
      },
    );

    // Create multiple lookup maps for flexible matching
    final localMapExact = {
      for (final l in local)
        _materialKey(
          materialName: l.materialName,
          designation: 'equipment',
          uom: l.uom,
          calculationCategory: l.calculationCategory,
        ): l
    };

    // Create a more flexible map for matching
    final localMapFlexible = {
      for (final l in local)
        _flexibleMaterialKey(l.materialName, 'equipment'): l
    };

    // Process ONLY server materials
    final result = server.map((s) {
      // Try exact match first
      final exactKey = _materialKey(
        materialName: s.materialName,
        designation: 'equipment',
        uom: s.uom,
        calculationCategory: s.calculationCategory,
      );

      // Try flexible match
      final flexibleKey = _flexibleMaterialKey(s.materialName, 'equipment');

      EquipmentItem? matchedLocal;

      // Check exact match
      if (localMapExact.containsKey(exactKey)) {
        matchedLocal = localMapExact[exactKey]!;
        print('✅ EXACT MATCH EQUIPMENT → ${s.materialName} (uom: ${s.uom})');
      }
      // Fall back to flexible match
      else if (localMapFlexible.containsKey(flexibleKey)) {
        matchedLocal = localMapFlexible[flexibleKey]!;
        print('🔄 FLEXIBLE MATCH EQUIPMENT → ${s.materialName} (server uom: ${s.uom}, local uom: ${matchedLocal.uom})');
      } else {
        print('⚠️ NO LOCAL MATCH → ${s.materialName} (using server image)');
      }

      // Use ALL data from server, ONLY image from local if matched
      if (matchedLocal != null && matchedLocal.image != null && matchedLocal.image!.isNotEmpty) {
        print('📸 Using local image for ${s.materialName}');
        return s.copyWith(
          image: matchedLocal.image,
          // Keep all server data including UOM
          uom: s.uom,
          length: s.length,
          calculationCategory: s.calculationCategory,
          remarks: s.remarks,
        );
      }
      if (s.image.isNotEmpty) {
        return s; // <-- THIS was missing
      }

      // If no match or no image, return server item as-is
      return s.copyWith(
        // Ensure we keep server UOM
        image: s.image,
        uom: s.uom,
        length: s.length,
        calculationCategory: s.calculationCategory,
      );
    }).toList();

    _debugPrintList(
      'EQUIPMENT – FINAL (server materials only)',
      result,
          (m) => {
        'id': m.id,
        'name': m.materialName,
        'image': m.image,
        'uom': m.uom, // Check this field!
        'qty': m.qty,
        'weight': m.weight,
        'calcCat': m.calculationCategory,
      },
    );

    _assertIds(result, (m) => m.id, 'Equipment');

    return result;
  }

  // ===========================================================================
  // DEBUG & SAFETY
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