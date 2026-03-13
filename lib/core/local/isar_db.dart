import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// if LocalMaterialSchema is here
import '../../features/modules/all_Modules/Manpower Details/offline/isar/manpower_isar.dart';
import '../../features/modules/all_Modules/attendance/offline/isar/attendance_isar.dart';
import '../../features/modules/all_Modules/dpr/offline/data/local/cached_image.dart';
import '../../features/modules/all_Modules/dpr/offline/data/local/local_material.dart';
import '../../features/modules/all_Modules/dpr/offline/mech/isar/dpr_work.dart';
import '../../features/modules/all_Modules/dpr/offline/mech/isar/outbox.dart';
import '../../features/modules/all_Modules/dpr/offline/mech/isar/rate_file_isar.dart';
import '../../features/modules/all_Modules/dpr/offline/mech/isar/sync_meta_isar.dart';
import '../../features/modules/all_Modules/inventory/offline/isar/inventory_isar.dart';
import '../../features/modules/all_Modules/team/offline/isar/team_isar.dart';

class AppIsarDB {
  static Isar? _isar;

  static Isar get isar {
    if (_isar == null) {
      throw Exception("AppIsarDB not initialized. Call AppIsarDB.init() first.");
    }
    return _isar!;
  }

  static Future<void> init() async {
    final existing = Isar.getInstance('app_db');
    if (existing != null) {
      _isar = existing;
      return;
    }

    final dir = await getApplicationDocumentsDirectory();

    final schemas = [
      LocalMaterialSchema,
      CachedImageSchema,
      TeamIsarSchema,
      RateFileAnalysisIsarSchema,
      RateFileMaterialIsarSchema,
      RateVariantIsarSchema,
      DprIsarSchema,
      OutboxIsarSchema,
      SyncMetaIsarSchema,
      InventoryCategoryIsarSchema,

      InventoryIsarSchema,
      InventoryUsageIsarSchema,
      InventoryCheckoutIsarSchema,


      AttendanceIsarSchema,
      ManpowerIsarSchema
    ];

    for (final s in schemas) {
      print("✅ Schema: ${s.name}"); // will crash if invalid schema
    }

    _isar = await Isar.open(
      schemas,
      directory: dir.path,
      name: 'app_db',
      inspector: true,
    );
  }

}
