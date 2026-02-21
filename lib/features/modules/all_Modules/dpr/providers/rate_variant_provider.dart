import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:untitled2/features/modules/all_Modules/dpr/providers/service/rate_upload_material_dpr.dart';
import '../../../../../core/local/isar_db.dart';
import '../models/data/floor_default.dart';
import '../models/data/moc_default.dart';
import '../models/floorModel.dart';
import '../models/pipingModel.dart';
import '../models/rate_file_models.dart';
import '../offline/mech/repo/rate_Repo.dart';



/// ------------------------------------------------------------
/// OFFLINE-FIRST RATE FILE ANALYSIS PROVIDER
/// ------------------------------------------------------------
/// IMPORTANT:
/// - KEEP SAME PROVIDER NAME
/// - LOAD CACHE FIRST
/// - IF ONLINE -> SYNC IN BACKGROUND
/// - IF OFFLINE -> SHOW CACHE (NO DIO EXCEPTION)
final rateFileAnalysisProvider =
StreamProvider.family<RateFileAnalysis?, String>((ref, siteId) {
  final repo = RateRepository(AppIsarDB.isar);

  // background sync
  Future.microtask(() async {
    final hasNet =
        await Connectivity().checkConnectivity() != ConnectivityResult.none;

    if (!hasNet) return;

    try {
      await repo.syncRateFile(siteId);
    } catch (_) {}
  });


  return repo.watchRateAnalysis(siteId);
});



final mocWithImagesProvider =
Provider.family<List<NamedImage>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));

  print("📦 DEFAULT MOCs:");
  for (final m in defaultMOCList) {
    print("   → ${m.name} = ${m.imageUrl}");
  }

  if (detected?.hasMoc != true) {
    print("🚫 Backend has NO MOC → using DEFAULTS");

    return defaultMOCList
        .map((e) => NamedImage(
      name: e.name,
      image: e.imageUrl!,
    ))
        .toList();
  }

  print("✅ Backend MOCs:");
  for (final m in detected!.mocs) {
    print("   → $m");
  }

  return detected.mocs.map((rawName) {
    final normalized = normalize(rawName);

    // alias correction
    final finalKey = mocAliases[normalized] ?? normalized;

    final asset = defaultMocImages[finalKey];

    // 👇 find server image
    final serverImage = detected.mocsWithImages
        .where((e) => e.name == rawName)
        .map((e) => e.image)
        .firstWhere(
          (e) => e.isNotEmpty,
      orElse: () => '',
    );

    final finalImage =
        asset ?? (serverImage.isNotEmpty ? serverImage : 'assets/images/default.webp');

    if (asset != null) {
      print("🎯 ASSET MATCH → $rawName → $asset");
    } else if (serverImage.isNotEmpty) {
      print("🌐 SERVER IMAGE → $rawName → $serverImage");
    } else {
      print("❌ NO MATCH → $rawName → generic");
    }

    return NamedImage(
      name: rawName,
      image: finalImage,
    );
  }).toList();


});
String normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll('_', '')
      .trim();
}
final Map<String, String> mocAliases = {
  'ss304': 'ss304',
  'ss 304': 'ss304',
  'ss-304': 'ss304',

  'ss316': 'ss316',
  'ss 316': 'ss316',

  'ppfrp2': 'ppfrp',
  'pp frp': 'ppfrp',
  'pp frp2': 'ppfrp',

  'frp2': 'frp',

  'rubber': 'rubberlined',

  'hastely': 'hastelloy',
};

final Map<String, String> defaultMocImages = {
  for (final m in defaultMOCList) m.name.toLowerCase(): m.imageUrl!,
};

final Map<String, String> defaultFloorImages = {
  for (final f in defaultFloorList) f.name.toLowerCase(): f.image,
};
List<String> splitFloors(String raw) {
  return raw
      .split(RegExp(r'&|,|/'))   // split by &, comma, slash
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

String normalizeFloor(String input) {
  var value = input.toLowerCase();

  value = value.replaceAll('floor', '');

  // 1st → 1
  value = value.replaceAll(RegExp(r'(\d+)(st|nd|rd|th)'), r'\1');

  value = value.replaceAll(RegExp(r'[^a-z0-9]'), '');

  return value.trim();
}

final Map<String, String> floorAliases = {
  'g': 'ground',
  'gf': 'ground',
  'ground': 'ground',

  '0': 'ground',

  '1': 'first',
  'first': 'first',

  '2': 'second',
  'second': 'second',

  '3': 'third',
  'third': 'third',

  '4': 'fourth',
  'fourth': 'fourth',

  'terrace': 'terrace',
};

final floorWithImagesProvider =
Provider.family<List<Floor>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));

  print("📦 DEFAULT FLOORS:");
  for (final f in defaultFloorList) {
    print("   → ${f.name} = ${f.image}");
  }

  if (detected?.hasFloor != true) {
    print("🚫 Backend has NO FLOOR → using DEFAULTS");
    return defaultFloorList;
  }

  print("✅ Backend FLOORS:");
  for (final f in detected!.floors) {
    print("   → $f");
  }

  return detected.floors.expand((rawName) {
    final parts = splitFloors(rawName);

    return parts.map((name) {
      final normalized = normalizeFloor(name);
      final canonical = floorAliases[normalized];

      final asset =
      canonical != null ? defaultFloorImages[canonical] : null;

      final serverImage = detected.floorsWithImages
          .where((e) => e.name == rawName)
          .map((e) => e.image)
          .firstWhere(
            (e) => e.isNotEmpty,
        orElse: () => '',
      );

      final finalImage =
          asset ?? (serverImage.isNotEmpty ? serverImage : 'assets/images/floor_default.webp');

      if (asset != null) {
        print("🎯 ASSET MATCH → $name → $asset");
      } else if (serverImage.isNotEmpty) {
        print("🌐 SERVER IMAGE → $name → $serverImage");
      } else {
        print("❌ NO MATCH → $name → generic");
      }

      return Floor(
        id: name,
        name: name,
        image: finalImage,
        isDeleted: false,
        isApplied: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });
  }).toList();



});

final materialDynamicFieldsProvider =
Provider.family<List<DynamicField>, ({String siteId, String materialId})>(
      (ref, params) {
    final materials = ref.watch(rateLineItemsProvider(params.siteId));

    final material = materials.firstWhere(
          (m) => m.id == params.materialId,
      orElse: () => RateFileMaterial.empty(), // create empty factory
    );


    return material.dynamicFields;
  },
);
final materialHasFieldProvider =
Provider.family<bool, ({String siteId, String materialId, String key})>(
      (ref, params) {
    final fields =
    ref.watch(materialDynamicFieldsProvider((siteId: params.siteId, materialId: params.materialId)));

    return fields.any((f) => f.key == params.key);
  },
);


/// ------------------------------------------------------------
/// BELOW ALL YOUR PROVIDERS STAY SAME
/// ------------------------------------------------------------

final rateLineItemsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final asyncAnalysis = ref.watch(rateFileAnalysisProvider(siteId));

  return asyncAnalysis.maybeWhen(
    data: (analysis) => analysis?.lineItems ?? [],

    orElse: () => [],
  );
});

final detectedFieldsProvider =
Provider.family<DetectedFields?, String>((ref, siteId) {
  final async = ref.watch(rateFileAnalysisProvider(siteId));

  return async.maybeWhen(
    data: (a) => a?.detectedFields,
    orElse: () => null,
  );
});
final floorListDetectedProvider =
Provider.family<List<String>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));
  if (detected?.hasFloor != true) return [];

  return detected!.floors;
});
final mocListDetectedProvider =
Provider.family<List<String>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));
  if (detected?.hasMoc != true) return [];

  return detected!.mocs;
});

final elevationListDetectedProvider =
Provider.family<List<String>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));
  if (detected?.hasElevation != true) return [];

  return detected!.elevations;
});
final sizeListDetectedProvider =
Provider.family<List<String>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));
  if (detected?.hasSize != true && detected?.hasHP != true) return [];

  return detected!.sizes;
});
final thicknessListDetectedProvider =
Provider.family<List<String>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));
  if (detected?.hasThickness != true) return [];

  return detected!.thicknesses;
});
final uomListDetectedProvider =
Provider.family<List<String>, String>((ref, siteId) {
  final detected = ref.watch(detectedFieldsProvider(siteId));
  return detected?.uoms ?? [];
});
final hasWeightProvider =
Provider.family<bool, String>((ref, siteId) {
  return ref.watch(detectedFieldsProvider(siteId))?.hasWeight == true;
});

final hasPowerProvider =
Provider.family<bool, String>((ref, siteId) {
  return ref.watch(detectedFieldsProvider(siteId))?.hasPower == true;
});

final hasDiameterProvider =
Provider.family<bool, String>((ref, siteId) {
  return ref.watch(detectedFieldsProvider(siteId))?.hasDiameter == true;
});


final pipingRateMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final items = ref.watch(rateLineItemsProvider(siteId));

  return items.where((m) => m.designation.contains('piping')).toList();
});

final equipmentRateMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final items = ref.watch(rateLineItemsProvider(siteId));

  return items.where((m) => m.designation.contains('equipment')).toList();
});

final allRateVariantsProvider =
Provider.family<List<RateVariant>, String>((ref, siteId) {
  final materials = ref.watch(rateLineItemsProvider(siteId));
  return materials.expand((m) => m.availableVariants).toList();
});

final mocListProvider = Provider.family<List<String>, String>((ref, siteId) {
  final variants = ref.watch(allRateVariantsProvider(siteId));

  return variants
      .map((v) => v.moc)
      .where((m) => m.isNotEmpty)
      .toSet()
      .toList();
});

final floorListProvider = Provider.family<List<String>, String>((ref, siteId) {
  final variants = ref.watch(allRateVariantsProvider(siteId));

  return variants
      .map((v) => v.floor)
      .where((f) => f.isNotEmpty)
      .toSet()
      .toList();
});

final uomListProvider = Provider.family<List<String>, String>((ref, siteId) {
  final variants = ref.watch(allRateVariantsProvider(siteId));

  return variants
      .map((v) => v.uom)
      .where((u) => u.isNotEmpty)
      .toSet()
      .toList();
});

final rateVariantsByMaterialProvider =
Provider.family<List<RateVariant>, ({String siteId, String materialId})>(
        (ref, params) {
      final materials = ref.watch(rateLineItemsProvider(params.siteId));

      final material = materials.firstWhere(
            (m) => m.id == params.materialId,
        orElse: () => throw Exception("Material not found"),
      );

      return material.availableVariants;
    });

final pipingItemFromRateProvider =
Provider.family<PipingItem, ({RateFileMaterial material, RateVariant variant})>(
        (ref, data) {
      return PipingItem.fromRateMaterial(
        data.material,
        data.variant,
      );
    });

final rateFileMetaProvider =
Provider.family<Map<String, dynamic>, String>((ref, siteId) {
  final asyncAnalysis = ref.watch(rateFileAnalysisProvider(siteId));

  return asyncAnalysis.maybeWhen(
    data: (a) => {
      'rateFileId': a?.id,
      'fileName': a?.fileName,
      'status': a?.status,
      'uploadedAt': a?.uploadDate,
    },
    orElse: () => {},
  );
});

final approvedRateMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final items = ref.watch(rateLineItemsProvider(siteId));

  return items.where((m) => m.approvalStatus == 'approved').toList();
});

final suggestedRateMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final items = ref.watch(rateLineItemsProvider(siteId));

  return items
      .where((m) =>
  m.approvalStatus != 'approved' && m.approvalStatus != 'rejected')
      .toList();
});

final approvedPipingMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final approved = ref.watch(approvedRateMaterialsProvider(siteId));

  return approved.where((m) => m.designation.contains('piping')).toList();
});

final approvedEquipmentMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final approved = ref.watch(approvedRateMaterialsProvider(siteId));

  return approved.where((m) => m.designation.contains('equipment')).toList();
});

final suggestedPipingMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final suggested = ref.watch(suggestedRateMaterialsProvider(siteId));

  return suggested.where((m) => m.designation.contains('piping')).toList();
});

final suggestedEquipmentMaterialsProvider =
Provider.family<List<RateFileMaterial>, String>((ref, siteId) {
  final suggested = ref.watch(suggestedRateMaterialsProvider(siteId));

  return suggested.where((m) => m.designation.contains('equipment')).toList();
});
