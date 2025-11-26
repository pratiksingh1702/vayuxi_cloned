// providers/inventory_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_model.dart';
import 'dart:io';

import '../service/inventory_service.dart';

// 1️⃣ InventoryApi singleton provider
final inventoryApiProvider = Provider<InventoryApi>((ref) {
  return InventoryApi();
});

// 2️⃣ Inventory List FutureProvider
final inventoryListProvider = FutureProvider.family<List<Inventory>, String>((ref, siteId) async {
  final api = ref.watch(inventoryApiProvider);
  return api.getInventoryList(siteId: siteId);
});

// 3️⃣ Daily Usage FutureProvider
final dailyUsageProvider = FutureProvider.family<List<InventoryUsage>, Map<String, dynamic>>(
      (ref, params) async {
    final api = ref.watch(inventoryApiProvider);
    return api.getDailyUsage(
      siteId: params['siteId'] as String,
      date: params['date'] as DateTime?,
    );
  },
);

// 4️⃣ Bulk Upload Provider (function-style)
final bulkUploadProvider = Provider.family<Future<BulkUploadResult>, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(inventoryApiProvider);
  final siteId = params['siteId'] as String;
  final file = params['file'] as File;
  return api.bulkUploadInventory(siteId: siteId, csvFile: file);
});

// 5️⃣ Record Inventory Usage Provider (function-style)
final recordUsageProvider = Provider.family<Future<InventoryUsage>, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(inventoryApiProvider);
  return api.recordInventoryUsage(
    inventoryId: params['inventoryId'] as String,
    itemId: params['itemId'] as String,
    siteId: params['siteId'] as String,
    quantityUsed: params['quantityUsed'] as double,
    categoryId: params['categoryId'] as String?,
    subcategoryId: params['subcategoryId'] as String?,
    usageDate: params['usageDate'] as DateTime?,
    remarks: params['remarks'] as String?,
  );
});

// 6️⃣ Generate Report Provider (function-style)
final generateReportProvider = Provider.family<Future<InventoryReport>, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(inventoryApiProvider);
  return api.generateReport(
    siteId: params['siteId'] as String,
    fromDate: params['fromDate'] as DateTime,
    toDate: params['toDate'] as DateTime,
  );
});
