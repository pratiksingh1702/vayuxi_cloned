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
class InventoryUsageRangeParams {
  final String siteId;
  final DateTime? startDate;
  final DateTime? endDate;

  InventoryUsageRangeParams({
    required this.siteId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryUsageRangeParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => siteId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

final inventoryUsageRangeProvider = StreamProvider.family<
    List<InventoryUsage>,
    InventoryUsageRangeParams
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
class CreateCheckoutParams {
  final String siteId;
  final String inventoryId;
  final String issuedToName;
  final int quantity;
  final DateTime? expectedReturnDate;
  final String? remarks;

  CreateCheckoutParams({
    required this.siteId,
    required this.inventoryId,
    required this.issuedToName,
    required this.quantity,
    this.expectedReturnDate,
    this.remarks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateCheckoutParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          inventoryId == other.inventoryId &&
          issuedToName == other.issuedToName &&
          quantity == other.quantity &&
          expectedReturnDate == other.expectedReturnDate &&
          remarks == other.remarks;

  @override
  int get hashCode =>
      siteId.hashCode ^
      inventoryId.hashCode ^
      issuedToName.hashCode ^
      quantity.hashCode ^
      expectedReturnDate.hashCode ^
      remarks.hashCode;
}

final createCheckoutProvider = FutureProvider.family<InventoryCheckout, CreateCheckoutParams>((ref, args) async {
  final repo = ref.read(repositoryProvider);

  return repo.checkoutItem(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
    issuedToName: args.issuedToName,
    quantity: args.quantity,
    expectedReturnDate: args.expectedReturnDate,
    remarks: args.remarks,
  );
});

class UpdateCheckoutParams {
  final String siteId;
  final String checkoutId;
  final String status;
  final DateTime? actualReturnDate;
  final String? returnRemarks;
  final String? condition;

  UpdateCheckoutParams({
    required this.siteId,
    required this.checkoutId,
    required this.status,
    this.actualReturnDate,
    this.returnRemarks,
    this.condition,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateCheckoutParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          checkoutId == other.checkoutId &&
          status == other.status &&
          actualReturnDate == other.actualReturnDate &&
          returnRemarks == other.returnRemarks &&
          condition == other.condition;

  @override
  int get hashCode =>
      siteId.hashCode ^
      checkoutId.hashCode ^
      status.hashCode ^
      actualReturnDate.hashCode ^
      returnRemarks.hashCode ^
      condition.hashCode;
}

final updateCheckoutProvider = FutureProvider.family<InventoryCheckout, UpdateCheckoutParams>((ref, args) async {
  final repo = ref.read(repositoryProvider);

  return repo.updateCheckout(
    siteId: args.siteId,
    checkoutId: args.checkoutId,
    status: args.status,
    actualReturnDate: args.actualReturnDate,
    returnRemarks: args.returnRemarks,
    condition: args.condition,
  );
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
class CreateInventoryParams {
  final String siteId;
  final String name;
  final String categoryId;
  final String? uom;
  final double? totalQuantityAdded;
  final double? minimumStockLevel;
  final int? totalUnits;
  final String? condition;
  final String? remarks;

  CreateInventoryParams({
    required this.siteId,
    required this.name,
    required this.categoryId,
    this.uom,
    this.totalQuantityAdded,
    this.minimumStockLevel,
    this.totalUnits,
    this.condition,
    this.remarks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateInventoryParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          name == other.name &&
          categoryId == other.categoryId &&
          uom == other.uom &&
          totalQuantityAdded == other.totalQuantityAdded &&
          minimumStockLevel == other.minimumStockLevel &&
          totalUnits == other.totalUnits &&
          condition == other.condition &&
          remarks == other.remarks;

  @override
  int get hashCode =>
      siteId.hashCode ^
      name.hashCode ^
      categoryId.hashCode ^
      uom.hashCode ^
      totalQuantityAdded.hashCode ^
      minimumStockLevel.hashCode ^
      totalUnits.hashCode ^
      condition.hashCode ^
      remarks.hashCode;
}

final createInventoryProvider = FutureProvider.family<Inventory, CreateInventoryParams>((ref, args) {
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

class UpdateInventoryParams {
  final String siteId;
  final String inventoryId;
  final String? name;
  final String? uom;
  final double? minimumStockLevel;
  final int? totalUnits;
  final String? condition;
  final String? remarks;

  UpdateInventoryParams({
    required this.siteId,
    required this.inventoryId,
    this.name,
    this.uom,
    this.minimumStockLevel,
    this.totalUnits,
    this.condition,
    this.remarks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateInventoryParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          inventoryId == other.inventoryId &&
          name == other.name &&
          uom == other.uom &&
          minimumStockLevel == other.minimumStockLevel &&
          totalUnits == other.totalUnits &&
          condition == other.condition &&
          remarks == other.remarks;

  @override
  int get hashCode =>
      siteId.hashCode ^
      inventoryId.hashCode ^
      name.hashCode ^
      uom.hashCode ^
      minimumStockLevel.hashCode ^
      totalUnits.hashCode ^
      condition.hashCode ^
      remarks.hashCode;
}

final updateInventoryProvider = FutureProvider.family<Inventory, UpdateInventoryParams>((ref, args) async {
  final repo = ref.read(repositoryProvider);
  return repo.updateInventory(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
    name: args.name,
    uom: args.uom,
    minimumStockLevel: args.minimumStockLevel,
    totalUnits: args.totalUnits,
    condition: args.condition,
    remarks: args.remarks,
  );
});

class DeleteInventoryParams {
  final String siteId;
  final String inventoryId;
  DeleteInventoryParams({required this.siteId, required this.inventoryId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeleteInventoryParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          inventoryId == other.inventoryId;

  @override
  int get hashCode => siteId.hashCode ^ inventoryId.hashCode;
}

final deleteInventoryProvider = FutureProvider.family<void, DeleteInventoryParams>((ref, args) async {
  final repo = ref.read(repositoryProvider);
  await repo.deleteInventory(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
  );
});

class RecordUsageParams {
  final String siteId;
  final String inventoryId;
  final double quantityUsed;
  final String usedByName;
  final DateTime? usageDate;
  final String? remarks;

  RecordUsageParams({
    required this.siteId,
    required this.inventoryId,
    required this.quantityUsed,
    required this.usedByName,
    this.usageDate,
    this.remarks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordUsageParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          inventoryId == other.inventoryId &&
          quantityUsed == other.quantityUsed &&
          usedByName == other.usedByName &&
          usageDate == other.usageDate &&
          remarks == other.remarks;

  @override
  int get hashCode =>
      siteId.hashCode ^
      inventoryId.hashCode ^
      quantityUsed.hashCode ^
      usedByName.hashCode ^
      usageDate.hashCode ^
      remarks.hashCode;
}

final recordUsageProvider = FutureProvider.family<InventoryUsage, RecordUsageParams>((ref, args) async {
  final repo = ref.read(repositoryProvider);
  return repo.recordUsage(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
    quantityUsed: args.quantityUsed,
    usedByName: args.usedByName,
    usageDate: args.usageDate,
    remarks: args.remarks,
  );
});


class BulkUploadParams {
  final String siteId;
  final File file;
  BulkUploadParams({required this.siteId, required this.file});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BulkUploadParams &&
          runtimeType == other.runtimeType &&
          siteId == other.siteId &&
          file == other.file;

  @override
  int get hashCode => siteId.hashCode ^ file.hashCode;
}

final bulkUploadProvider = FutureProvider.family<Map<String, dynamic>, BulkUploadParams>((ref, args) async {
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
