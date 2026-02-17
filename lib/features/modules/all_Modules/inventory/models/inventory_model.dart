
import '../offline/isar/inventory_isar.dart';

class Category {
  final String id;
  final String name;
  final String type;

  Category({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
    );
  }
}

class Inventory {
  final String id;
  final String name;
  final Category category;
  final String type;

  final String? uom;
  final double? totalQuantityAdded;
  final double? currentBalance;
  final double? minimumStockLevel;

  final int? totalUnits;
  final int? availableUnits;
  final String? condition;

  final String? remarks;
  final DateTime createdAt;

  Inventory({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    this.uom,
    this.totalQuantityAdded,
    this.currentBalance,
    this.minimumStockLevel,
    this.totalUnits,
    this.availableUnits,
    this.condition,
    this.remarks,
    required this.createdAt,
  });

  bool get isLowStock =>
      type == "consumable" &&
          currentBalance != null &&
          minimumStockLevel != null &&
          currentBalance! <= minimumStockLevel!;

  factory Inventory.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'];

    return Inventory(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',

      category: rawCategory is Map<String, dynamic>
          ? Category.fromJson(rawCategory)
          : Category(
        id: rawCategory?.toString() ?? '',
        name: '',
        type: '',
      ),

      type: json['type']?.toString() ?? '',

      uom: json['uom']?.toString(),

      totalQuantityAdded:
      (json['totalQuantityAdded'] as num?)?.toDouble(),

      currentBalance:
      (json['currentBalance'] as num?)?.toDouble(),

      minimumStockLevel:
      (json['minimumStockLevel'] as num?)?.toDouble(),

      totalUnits: json['totalUnits'] as int?,
      availableUnits: json['availableUnits'] as int?,

      condition: json['condition']?.toString(),
      remarks: json['remarks']?.toString(),

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }


}

class InventoryUsage {
  final String id;
  final String inventory;
  final double quantityUsed;
  final String usedByName;
  final DateTime usageDate;
  final String? remarks;

  InventoryUsage({
    required this.id,
    required this.inventory,
    required this.quantityUsed,
    required this.usedByName,
    required this.usageDate,
    this.remarks,
  });

  factory InventoryUsage.fromJson(Map<String, dynamic> json) {
    return InventoryUsage(
      id: json['_id'],
      inventory: json['inventory'],
      quantityUsed: (json['quantityUsed']).toDouble(),
      usedByName: json['usedByName'],
      usageDate: DateTime.parse(json['usageDate']),
      remarks: json['remarks'],
    );
  }
}

class InventoryCheckout {
  final String id;
  final Inventory inventory;
  final String issuedToName;
  final String status;
  final int quantity;
  final DateTime? actualReturnDate;
  final String? returnRemarks;

  InventoryCheckout({
    required this.id,
    required this.inventory,
    required this.issuedToName,
    required this.status,
    required this.quantity,
    this.actualReturnDate,
    this.returnRemarks,
  });

  factory InventoryCheckout.fromJson(Map<String, dynamic> json) {
    final rawInventory = json['inventory'];

    return InventoryCheckout(
      id: json['_id']?.toString() ?? '',

      inventory: rawInventory is Map<String, dynamic>
          ? Inventory.fromJson(rawInventory)
          : Inventory(
        id: rawInventory?.toString() ?? '',
        name: '',
        category: Category(id: '', name: '', type: ''),
        type: '',
        createdAt: DateTime.now(),
      ),

      issuedToName: json['issuedToName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      quantity: json['quantity'] ?? 0,

      actualReturnDate: json['actualReturnDate'] != null
          ? DateTime.tryParse(json['actualReturnDate'])
          : null,

      returnRemarks: json['returnRemarks']?.toString(),
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