// models/inventory_model.dart
class InventoryItem {
  final String id;
  final String name;
  final String? categoryId;
  final String? subcategoryId;
  final String companyId;
  final String siteId;
  final bool isDeleted;

  InventoryItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.subcategoryId,
    required this.companyId,
    required this.siteId,
    this.isDeleted = false,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      categoryId: json['category'],
      subcategoryId: json['subcategory'],
      companyId: json['company'] ?? '',
      siteId: json['site'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': categoryId,
      'subcategory': subcategoryId,
      'company': companyId,
      'site': siteId,
      'isDeleted': isDeleted,
    };
  }
}

class Inventory {
  final String id;
  final String? categoryId;
  final String? subcategoryId;
  final String itemId;
  final String companyId;
  final String siteId;
  final double totalQuantityAdded;
  final double currentBalance;
  final double minimumStockLevel;
  final String? remarks;
  final DateTime createdAt;
  final bool isDeleted;

  // Expanded fields from populate
  final String? categoryName;
  final String? subcategoryName;
  final String itemName;

  Inventory({
    required this.id,
    this.categoryId,
    this.subcategoryId,
    required this.itemId,
    required this.companyId,
    required this.siteId,
    required this.totalQuantityAdded,
    required this.currentBalance,
    required this.minimumStockLevel,
    this.remarks,
    required this.createdAt,
    this.isDeleted = false,
    this.categoryName,
    this.subcategoryName,
    required this.itemName,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['_id'] ?? '',
      categoryId: json['category']?['_id'],
      subcategoryId: json['subcategory']?['_id'],
      itemId: json['item']?['_id'] ?? '',
      companyId: json['company'] ?? '',
      siteId: json['site'] ?? '',
      totalQuantityAdded: (json['totalQuantityAdded'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toDouble(),
      remarks: json['remarks'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isDeleted: json['isDeleted'] ?? false,
      categoryName: json['category']?['name'],
      subcategoryName: json['subcategory']?['name'],
      itemName: json['item']?['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': categoryId,
      'subcategory': subcategoryId,
      'item': itemId,
      'company': companyId,
      'site': siteId,
      'totalQuantityAdded': totalQuantityAdded,
      'currentBalance': currentBalance,
      'minimumStockLevel': minimumStockLevel,
      'remarks': remarks,
      'isDeleted': isDeleted,
    };
  }

  bool get isLowStock => currentBalance <= minimumStockLevel;
}

class InventoryUsage {
  final String id;
  final String inventoryId;
  final String itemId;
  final String companyId;
  final String siteId;
  final double quantityUsed;
  final DateTime usageDate;
  final String? remarks;
  final String usedById;
  final bool isDeleted;

  // Expanded fields
  final String? categoryName;
  final String? subcategoryName;
  final String itemName;
  final String? usedByName;
  final String? usedByEmail;

  InventoryUsage({
    required this.id,
    required this.inventoryId,
    required this.itemId,
    required this.companyId,
    required this.siteId,
    required this.quantityUsed,
    required this.usageDate,
    this.remarks,
    required this.usedById,
    this.isDeleted = false,
    this.categoryName,
    this.subcategoryName,
    required this.itemName,
    this.usedByName,
    this.usedByEmail,
  });

  factory InventoryUsage.fromJson(Map<String, dynamic> json) {
    return InventoryUsage(
      id: json['_id'] ?? '',
      inventoryId: json['inventory']?['_id'] ?? json['inventory'] ?? '',
      itemId: json['item']?['_id'] ?? json['item'] ?? '',
      companyId: json['company'] ?? '',
      siteId: json['site'] ?? '',
      quantityUsed: (json['quantityUsed'] ?? 0).toDouble(),
      usageDate: DateTime.parse(json['usageDate'] ?? DateTime.now().toIso8601String()),
      remarks: json['remarks'],
      usedById: json['usedBy']?['_id'] ?? json['usedBy'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      categoryName: json['category']?['name'] ?? json['inventory']?['category']?['name'],
      subcategoryName: json['subcategory']?['name'] ?? json['inventory']?['subcategory']?['name'],
      itemName: json['item']?['name'] ?? json['inventory']?['item']?['name'] ?? '',
      usedByName: json['usedBy']?['name'],
      usedByEmail: json['usedBy']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'itemId': itemId,
      'siteId': siteId,
      'quantityUsed': quantityUsed,
      'usageDate': usageDate.toIso8601String(),
      'remarks': remarks,
      'categoryId': categoryName != null ? 'temp_category' : null,
      'subcategoryId': subcategoryName != null ? 'temp_subcategory' : null,
    };
  }
}

class BulkUploadResult {
  final String message;
  final int success;
  final int failed;
  final List<String> errors;

  BulkUploadResult({
    required this.message,
    required this.success,
    required this.failed,
    required this.errors,
  });

  factory BulkUploadResult.fromJson(Map<String, dynamic> json) {
    return BulkUploadResult(
      message: json['message'] ?? '',
      success: json['success'] ?? 0,
      failed: json['failed'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }
}

class InventoryReport {
  final String data; // base64 encoded Excel file
  final String fileName;

  InventoryReport({
    required this.data,
    required this.fileName,
  });

  factory InventoryReport.fromJson(Map<String, dynamic> json) {
    return InventoryReport(
      data: json['data'] ?? '',
      fileName: json['fileName'] ?? 'inventory_report.xlsx',
    );
  }
}