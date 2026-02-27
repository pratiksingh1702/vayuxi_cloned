import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/local/isar_db.dart';
import '../models/inventory_model.dart';
import '../offline/repo/inventory_repo.dart';
import '../offline/repo/inventory_sync.dart';
import '../service/inventory_service.dart';

final inventoryApiProvider = Provider((ref) => InventoryApi());

final repositoryProvider = Provider((ref) {
  return InventoryRepository(
    AppIsarDB.isar,
    ref.read(inventoryApiProvider),
  );
});

// ---------------------------------------------------------------------------
// STREAMS
// ---------------------------------------------------------------------------

final categoriesProvider =
StreamProvider.family<List<Category>, String>((ref, siteId) {
  ref.watch(inventorySyncControllerProvider(siteId));
  return ref.read(repositoryProvider).watchCategories(siteId);
});

final inventoryProvider =
StreamProvider.family<List<Inventory>, String>((ref, siteId) {
  ref.watch(inventorySyncControllerProvider(siteId));
  return ref.read(repositoryProvider).watchInventory(siteId);
});

final lowStockProvider =
StreamProvider.family<List<Inventory>, String>((ref, siteId) {
  ref.watch(inventorySyncControllerProvider(siteId));
  return ref.read(repositoryProvider).watchLowStock(siteId);
});

final usageProvider =
StreamProvider.family<List<InventoryUsage>, String>((ref, siteId) {
  ref.watch(inventorySyncControllerProvider(siteId));
  return ref.read(repositoryProvider).watchUsage(siteId);
});
final inventoryUsageRangeProvider = StreamProvider.family<
    List<InventoryUsage>,
    ({
    String siteId,
    DateTime? startDate,
    DateTime? endDate,
    })
>((ref, args) {

  print("🟣 RANGE PROVIDER CALLED");
  print("   Site: ${args.siteId}");
  print("   Start: ${args.startDate}");
  print("   End: ${args.endDate}");

  ref.watch(inventorySyncControllerProvider(args.siteId));

  final repo = ref.read(repositoryProvider);

  return repo.watchUsage(args.siteId).map((list) {
    print("🔵 RAW USAGE COUNT: ${list.length}");

    final start = args.startDate;
    final end = args.endDate ?? start;

    if (start == null) {
      print("🟢 NO DATE FILTER APPLIED");
      return list;
    }

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end!.year, end.month, end.day, 23, 59, 59);

    final filtered = list.where((u) {
      return u.usageDate.isAfter(startDay.subtract(const Duration(seconds: 1))) &&
          u.usageDate.isBefore(endDay.add(const Duration(seconds: 1)));
    }).toList();

    print("🟠 FILTERED COUNT: ${filtered.length}");

    return filtered;
  });
});

final checkoutProvider =
StreamProvider.family<List<InventoryCheckout>, String>((ref, siteId) {
  ref.watch(inventorySyncControllerProvider(siteId));
  return ref.read(repositoryProvider).watchCheckouts(siteId);
});
final createCheckoutProvider = FutureProvider.family<
    InventoryCheckout,
    ({
    String siteId,
    String inventoryId,
    String issuedToName,
    int quantity,
    DateTime? expectedReturnDate,
    String? remarks,
    })>((ref, args) async {
  final api = ref.read(inventoryApiProvider);

  final result = await api.checkoutItem(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
    issuedToName: args.issuedToName,
    quantity: args.quantity,
    expectedReturnDate: args.expectedReturnDate,
    remarks: args.remarks,
  );

  /// 🔥 refresh after success
  ref.invalidate(checkoutProvider(args.siteId));
  ref.invalidate(inventoryProvider(args.siteId));

  return result;
});
final updateCheckoutProvider = FutureProvider.family<
    InventoryCheckout,
    ({
    String siteId,
    String checkoutId,
    String status,
    DateTime? actualReturnDate,
    String? returnRemarks,
    String? condition,
    })>((ref, args) async {
  final api = ref.read(inventoryApiProvider);

  final result = await api.updateCheckout(
    siteId: args.siteId,
    checkoutId: args.checkoutId,
    status: args.status,
    actualReturnDate: args.actualReturnDate,
    returnRemarks: args.returnRemarks,
    condition: args.condition,
  );

  /// 🔥 refresh lists
  ref.invalidate(checkoutProvider(args.siteId));
  ref.invalidate(inventoryProvider(args.siteId));

  return result;
});
final checkoutByStatusProvider = FutureProvider.family<
    List<InventoryCheckout>,
    ({
    String siteId,
    String status,
    })>((ref, args) async {
  final api = ref.read(inventoryApiProvider);

  return api.getCheckouts(
    siteId: args.siteId,
    status: args.status,
  );
});

final generateReportProvider =
FutureProvider.family<Uint8List, ({String siteId, DateTime from})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.generateReport(
    siteId: args.siteId,
    fromDate: args.from,

  );
});
final createInventoryProvider = FutureProvider.family<
    Inventory,
    ({
    String siteId,
    String name,
    String categoryId,
    String? uom,
    double? totalQuantityAdded,
    double? minimumStockLevel,
    int? totalUnits,
    String? condition,
    String? remarks,
    })>((ref, args) {

  final repo = ref.read(repositoryProvider);

  return repo.createInventory(
    siteId: args.siteId,
    name: args.name,
    categoryId: args.categoryId,
    uom: args.uom,
    totalQuantityAdded: args.totalQuantityAdded,
    minimumStockLevel: args.minimumStockLevel,
    totalUnits: args.totalUnits,
    condition: args.condition,
    remarks: args.remarks,
  );
});
final updateInventoryProvider = FutureProvider.family<
    Inventory,
    ({
    String siteId,
    String inventoryId,
    String? name,
    String? uom,
    double? minimumStockLevel,
    int? totalUnits,
    String? condition,
    String? remarks,
    })>((ref, args) async {
  final api = ref.read(inventoryApiProvider);

  final result = await api.updateInventory(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
    name: args.name,
    uom: args.uom,
    minimumStockLevel: args.minimumStockLevel,
    totalUnits: args.totalUnits,
    condition: args.condition,
    remarks: args.remarks,
  );

  return result;
});


final bulkUploadProvider = FutureProvider.family<Map<String, dynamic>, ({String siteId, File file})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.bulkUploadInventory(
    siteId: args.siteId,
    csvFile: args.file,
  );
});


// 26. Download Excel provider (returns File)
final downloadReportProvider = FutureProvider.family<File, InventoryReport>((ref, report) async {
  final api = ref.read(inventoryApiProvider);
  return api.downloadReport(report);
});

// ---------------------------------------------------------------------------
// UI STATE
// ---------------------------------------------------------------------------

final selectedInventoryProvider = StateProvider<Inventory?>((ref) => null);
final inventorySearchProvider = StateProvider<String>((ref) => '');
