import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_Model.dart';
import '../service/inventory_service.dart';

// 1. Provide the InventoryApi instance
final inventoryApiProvider = Provider<InventoryApi>((ref) {
  return InventoryApi();
});

// Category Providers

// 2. Categories list provider
final categoriesProvider = FutureProvider.family<List<Category>, String>((ref, siteId) async {
  final api = ref.read(inventoryApiProvider);
  return api.getCategories(siteId: siteId);
});

// 3. Create category provider
final createCategoryProvider = FutureProvider.family<Category, ({String siteId, String name})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.createCategory(
    siteId: args.siteId,
    name: args.name,
  );
});

// 4. Update category provider
final updateCategoryProvider = FutureProvider.family<Category, ({String siteId, String categoryId, String name})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.updateCategory(
    siteId: args.siteId,
    categoryId: args.categoryId,
    name: args.name,
  );
});

// 5. Delete category provider
final deleteCategoryProvider = FutureProvider.family<void, ({String siteId, String categoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.deleteCategory(
    siteId: args.siteId,
    categoryId: args.categoryId,
  );
});

// Subcategory Providers

// 6. Subcategories list provider
final subcategoriesProvider = FutureProvider.family<List<Subcategory>, ({String siteId, String? categoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.getSubcategories(
    siteId: args.siteId,
    categoryId: args.categoryId,
  );
});

// 7. Create subcategory provider
final createSubcategoryProvider = FutureProvider.family<Subcategory, ({String siteId, String name, String categoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.createSubcategory(
    siteId: args.siteId,
    name: args.name,
    categoryId: args.categoryId,
  );
});

// 8. Update subcategory provider
final updateSubcategoryProvider = FutureProvider.family<Subcategory, ({String siteId, String subcategoryId, String name, String categoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.updateSubcategory(
    siteId: args.siteId,
    subcategoryId: args.subcategoryId,
    name: args.name,
    categoryId: args.categoryId,
  );
});

// 9. Delete subcategory provider
final deleteSubcategoryProvider = FutureProvider.family<void, ({String siteId, String subcategoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.deleteSubcategory(
    siteId: args.siteId,
    subcategoryId: args.subcategoryId,
  );
});

// Item Providers

// 10. Items list provider
final itemsProvider = FutureProvider.family<List<InventoryItem>, ({String siteId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.getItems(
    siteId: args.siteId,

  );
});

// 11. Create item provider
final createItemProvider = FutureProvider.family<InventoryItem, ({String siteId, String name, String categoryId, String subcategoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.createItem(
    siteId: args.siteId,
    name: args.name,
    categoryId: args.categoryId,
    subcategoryId: args.subcategoryId,
  );
});

// 12. Update item provider
final updateItemProvider = FutureProvider.family<InventoryItem, ({String siteId, String itemId, String name, String categoryId, String subcategoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.updateItem(
    siteId: args.siteId,
    itemId: args.itemId,
    name: args.name,
    categoryId: args.categoryId,
    subcategoryId: args.subcategoryId,
  );
});

// 13. Delete item provider
final deleteItemProvider = FutureProvider.family<void, ({String siteId, String itemId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.deleteItem(
    siteId: args.siteId,
    itemId: args.itemId,
  );
});

// Inventory Stock Providers
// 36. Get all inventory stock provider
final allInventoryProvider = FutureProvider.family<List<Inventory>, String>((ref, siteId) async {
  final api = ref.read(inventoryApiProvider);
  return api.getAllInventory(siteId: siteId);
});

// 37. Get filtered inventory provider
final filteredInventoryProvider = FutureProvider.family<List<Inventory>, ({
String siteId,
String? categoryId,
String? subcategoryId,
String? itemId,
bool? lowStockOnly,
})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.getInventoryWithFilters(
    siteId: args.siteId,
    categoryId: args.categoryId,
    subcategoryId: args.subcategoryId,
    itemId: args.itemId,
    lowStockOnly: args.lowStockOnly,
  );
});
// 14. Add/update inventory stock provider
final addUpdateInventoryStockProvider = FutureProvider.family<Inventory, ({
String siteId,
String itemId,
String categoryId,
String subcategoryId,
double totalQuantityAdded,
double minimumStockLevel,
String uom,
String? remarks,
})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.addUpdateInventoryStock(
    siteId: args.siteId,
    itemId: args.itemId,
    categoryId: args.categoryId,
    subcategoryId: args.subcategoryId,
    totalQuantityAdded: args.totalQuantityAdded,
    minimumStockLevel: args.minimumStockLevel,
    uom: args.uom,
    remarks: args.remarks,
  );
});

// 15. Get inventory by ID provider
final inventoryByIdProvider = FutureProvider.family<Inventory, ({String siteId, String inventoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.getInventoryById(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
  );
});

// 16. Update inventory provider
final updateInventoryProvider = FutureProvider.family<Inventory, ({
String siteId,
String inventoryId,
double? totalQuantityAdded,
double? minimumStockLevel,
String? uom,
String? remarks,
})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.updateInventory(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
    totalQuantityAdded: args.totalQuantityAdded,
    minimumStockLevel: args.minimumStockLevel,
    uom: args.uom,
    remarks: args.remarks,
  );
});

// 17. Delete inventory provider
final deleteInventoryProvider = FutureProvider.family<void, ({String siteId, String inventoryId})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.deleteInventory(
    siteId: args.siteId,
    inventoryId: args.inventoryId,
  );
});

// Usage History Providers

// 18. Usage history provider
final usageHistoryProvider = FutureProvider.family<List<InventoryUsage>, ({
String siteId,
DateTime? startDate,
DateTime? endDate,
})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.getUsageHistory(
    siteId: args.siteId,
    startDate: args.startDate,
    endDate: args.endDate,
  );
});

// 19. Low stock items provider
final lowStockItemsProvider = FutureProvider.family<List<Inventory>, String>((ref, siteId) async {
  final api = ref.read(inventoryApiProvider);
  return api.getLowStockItems(siteId: siteId);
});

// 20. Bulk upload JSON provider
final bulkUploadJsonProvider = FutureProvider.family<Map<String, dynamic>, ({
String siteId,
List<Map<String, dynamic>> inventoryData,
})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.bulkUploadInventoryJson(
    siteId: args.siteId,
    inventoryData: args.inventoryData,
  );
});

// Existing providers (you already had these)

// 21. Inventory list provider (GET inventory)
final inventoryListProvider = FutureProvider.family<List<Inventory>, String>((ref, siteId) async {
  final api = ref.read(inventoryApiProvider);
  return api.getInventoryList(siteId: siteId);
});

// 22. Bulk upload provider (POST CSV)
final bulkUploadProvider = FutureProvider.family<Map<String, dynamic>, ({String siteId, File file})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.bulkUploadInventory(
    siteId: args.siteId,
    csvFile: args.file,
  );
});

// 23. Record usage provider (POST usage)
final recordUsageProvider = FutureProvider.family<InventoryUsage, RecordUsageArgs>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.recordInventoryUsage(
    inventoryId: args.inventoryId,
    itemId: args.itemId,
    siteId: args.siteId,
    quantityUsed: args.quantityUsed,
    categoryId: args.categoryId,
    subcategoryId: args.subcategoryId,
    usageDate: args.usageDate,
    remarks: args.remarks,
  );
});

class RecordUsageArgs {
  final String inventoryId;
  final String itemId;
  final String siteId;
  final double quantityUsed;
  final String? categoryId;
  final String? subcategoryId;
  final String? usageDate;
  final String? remarks;

  RecordUsageArgs({
    required this.inventoryId,
    required this.itemId,
    required this.siteId,
    required this.quantityUsed,
    this.categoryId,
    this.subcategoryId,
    this.usageDate,
    this.remarks,
  });
}

// 24. Daily usage provider (GET daily usage)
final dailyUsageProvider = FutureProvider.family<List<InventoryUsage>, ({String siteId, DateTime? date})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.getDailyUsage(
    siteId: args.siteId,
    date: args.date,
  );
});

// 25. Generate report provider (Excel metadata)
final generateReportProvider =
FutureProvider.family<Uint8List, ({String siteId, DateTime from, DateTime to})>((ref, args) async {
  final api = ref.read(inventoryApiProvider);
  return api.generateReport(
    siteId: args.siteId,
    fromDate: args.from,
    toDate: args.to,
  );
});


// 26. Download Excel provider (returns File)
final downloadReportProvider = FutureProvider.family<File, InventoryReport>((ref, report) async {
  final api = ref.read(inventoryApiProvider);
  return api.downloadReport(report);
});

// State Providers for Form Management

// 27. Selected category provider
final selectedCategoryProvider = StateProvider<Category?>((ref) => null);

// 28. Selected subcategory provider
final selectedSubcategoryProvider = StateProvider<Subcategory?>((ref) => null);

// 29. Selected item provider
final selectedItemProvider = StateProvider<InventoryItem?>((ref) => null);

// 30. Selected inventory provider
final selectedInventoryProvider = StateProvider<Inventory?>((ref) => null);

// 31. Inventory filter provider
final inventoryFilterProvider = StateProvider<String>((ref) => '');

// 32. Inventory sort provider
final inventorySortProvider = StateProvider<String>((ref) => 'name');

// 33. Date range provider for reports
final dateRangeProvider = StateProvider<({DateTime from, DateTime to})>((ref) {
  final now = DateTime.now();
  return (
  from: DateTime(now.year, now.month, now.day - 30),
  to: now,
  );
});

// Notifier Providers for Complex State Management

// 34. Inventory form state notifier
class InventoryFormState {
  final String? categoryId;
  final String? subcategoryId;
  final String? itemId;
  final double? quantity;
  final double? minimumStock;
  final String? uom;
  final String? remarks;
  final bool isLoading;
  final String? error;

  InventoryFormState({
    this.categoryId,
    this.subcategoryId,
    this.itemId,
    this.quantity,
    this.minimumStock,
    this.uom,
    this.remarks,
    this.isLoading = false,
    this.error,
  });

  InventoryFormState copyWith({
    String? categoryId,
    String? subcategoryId,
    String? itemId,
    double? quantity,
    double? minimumStock,
    String? uom,
    String? remarks,
    bool? isLoading,
    String? error,
  }) {
    return InventoryFormState(
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      uom: uom ?? this.uom,
      remarks: remarks ?? this.remarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final inventoryFormNotifierProvider = StateNotifierProvider<InventoryFormNotifier, InventoryFormState>((ref) {
  return InventoryFormNotifier();
});

class InventoryFormNotifier extends StateNotifier<InventoryFormState> {
  InventoryFormNotifier() : super(InventoryFormState());

  void setCategory(String categoryId) {
    state = state.copyWith(categoryId: categoryId, subcategoryId: null, itemId: null);
  }

  void setSubcategory(String subcategoryId) {
    state = state.copyWith(subcategoryId: subcategoryId, itemId: null);
  }

  void setItem(String itemId) {
    state = state.copyWith(itemId: itemId);
  }

  void setQuantity(double quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void setMinimumStock(double minimumStock) {
    state = state.copyWith(minimumStock: minimumStock);
  }

  void setUom(String uom) {
    state = state.copyWith(uom: uom);
  }

  void setRemarks(String remarks) {
    state = state.copyWith(remarks: remarks);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void reset() {
    state = InventoryFormState();
  }
}

// 35. Inventory search and filter notifier
class InventoryFilterState {
  final String searchQuery;
  final String? categoryFilter;
  final String? subcategoryFilter;
  final bool showLowStockOnly;
  final String sortBy;

  InventoryFilterState({
    this.searchQuery = '',
    this.categoryFilter,
    this.subcategoryFilter,
    this.showLowStockOnly = false,
    this.sortBy = 'name',
  });

  InventoryFilterState copyWith({
    String? searchQuery,
    String? categoryFilter,
    String? subcategoryFilter,
    bool? showLowStockOnly,
    String? sortBy,
  }) {
    return InventoryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      subcategoryFilter: subcategoryFilter ?? this.subcategoryFilter,
      showLowStockOnly: showLowStockOnly ?? this.showLowStockOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final inventoryFilterNotifierProvider = StateNotifierProvider<InventoryFilterNotifier, InventoryFilterState>((ref) {
  return InventoryFilterNotifier();
});

class InventoryFilterNotifier extends StateNotifier<InventoryFilterState> {
  InventoryFilterNotifier() : super(InventoryFilterState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(categoryFilter: categoryId, subcategoryFilter: null);
  }

  void setSubcategoryFilter(String? subcategoryId) {
    state = state.copyWith(subcategoryFilter: subcategoryId);
  }

  void setShowLowStockOnly(bool showLowStockOnly) {
    state = state.copyWith(showLowStockOnly: showLowStockOnly);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void resetFilters() {
    state = InventoryFilterState();
  }
}