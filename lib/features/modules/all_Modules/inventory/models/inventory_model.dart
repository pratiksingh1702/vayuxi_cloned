
import '../../../../profile_page/userModel/userModel.dart';
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
  final Inventory inventory;
  final double quantityUsed;
  final String? uom;
  final String usedByName;
  final User? usedBy;
  final DateTime usageDate;
  final String? remarks;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryUsage({
    required this.id,
    required this.inventory,
    required this.quantityUsed,
this.uom,
    required this.usedByName,
    this.usedBy,
    required this.usageDate,
    this.remarks,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  /// 🔥 Hybrid UOM priority
  String get effectiveUom {
    if (uom != null && uom!.isNotEmpty) return uom!;
    if (inventory.uom != null && inventory.uom!.isNotEmpty) {
      return inventory.uom!;
    }
    return '';
  }

  factory InventoryUsage.fromJson(Map<String, dynamic> json) {
    return InventoryUsage(
      id: json['_id']?.toString() ?? '',
      inventory: Inventory.fromJson(json['inventory']),
      quantityUsed: (json['quantityUsed'] as num?)?.toDouble() ?? 0.0,
      uom: json['uom']?.toString() ?? '',
      usedByName: json['usedByName']?.toString() ?? '',
      usedBy: json['usedBy'] is Map<String, dynamic>
          ? User.fromJson(json['usedBy'])
          : null,
      usageDate: DateTime.tryParse(json['usageDate'] ?? '') ?? DateTime.now(),
      remarks: json['remarks']?.toString(),
      isDeleted: json['isDeleted'] ?? false,
      createdAt:
      DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
      DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
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
  final String? remarks;
  final DateTime? expectedReturnDate;

  InventoryCheckout({
    required this.id,
    required this.inventory,
    required this.issuedToName,
    required this.status,
    required this.quantity,
    this.expectedReturnDate,
    this.actualReturnDate,
    this.returnRemarks,this.remarks,
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
      expectedReturnDate: json['expectedReturnDate'] != null
          ? DateTime.tryParse(json['expectedReturnDate'])
          : null,
      actualReturnDate: json['actualReturnDate'] != null
          ? DateTime.tryParse(json['actualReturnDate'])
          : null,

      returnRemarks: json['returnRemarks']?.toString(),   remarks: json['returnRemarks']?.toString(),
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