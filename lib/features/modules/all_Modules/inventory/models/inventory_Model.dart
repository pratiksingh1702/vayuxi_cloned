// models/inventory_model.dart

// Category Model
class Category {
  final String id;
  final String name;
  final String company;
  final String site;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.company,
    required this.site,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      site: json['site'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'company': company,
      'site': site,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Subcategory Model
// Subcategory Model
class Subcategory {
  final String id;
  final String name;
  final String category; // This stores the category ID as string
  final String categoryName; // Add this to store the category name for display
  final String company;
  final String site;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subcategory({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryName,
    required this.company,
    required this.site,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    // Handle the category field which can be either a string ID or a full object
    String categoryId;
    String categoryName = '';

    if (json['category'] is String) {
      categoryId = json['category'];
    } else if (json['category'] is Map<String, dynamic>) {
      // Extract ID and name from the category object
      categoryId = json['category']['_id'] ?? '';
      categoryName = json['category']['name'] ?? '';
    } else {
      categoryId = '';
    }

    return Subcategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: categoryId,
      categoryName: categoryName,
      company: json['company'] ?? '',
      site: json['site'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'category': category, // Send only the category ID as string
      'company': company,
      'site': site,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
// Inventory Item Model (with nested category and subcategory)
// Inventory Item Model (with nested category and subcategory)
class InventoryItem {
  final String id;
  final String name;
  final Subcategory subcategory;
  final Category category;
  final String company;
  final String site;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Convenience getters for IDs
  String get categoryId => category.id;
  String get subcategoryId => subcategory.id;
  String get companyId => company;
  String get siteId => site;

  InventoryItem({
    required this.id,
    required this.name,
    required this.subcategory,
    required this.category,
    required this.company,
    required this.site,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle category
    Category categoryObj;
    if (json['category'] is String) {
      categoryObj = Category(
        id: json['category'],
        name: '',
        company: json['company'] ?? '',
        site: json['site'] ?? '',
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      categoryObj = Category.fromJson(json['category'] ?? {});
    }

    // Handle subcategory
    Subcategory subcategoryObj;
    if (json['subcategory'] is String) {
      subcategoryObj = Subcategory(
        id: json['subcategory'],
        name: '',
        category: categoryObj.id,
        categoryName: '',
        company: json['company'] ?? '',
        site: json['site'] ?? '',
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      subcategoryObj = Subcategory.fromJson(json['subcategory'] ?? {});
    }

    return InventoryItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      subcategory: subcategoryObj,
      category: categoryObj,
      company: json['company'] ?? '',
      site: json['site'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Alternative constructor for creating items with IDs only
  factory InventoryItem.create({
    required String name,
    required String categoryId,
    required String subcategoryId,
    required String companyId,
    required String siteId,
  }) {
    return InventoryItem(
      id: '',
      name: name,
      subcategory: Subcategory(
        id: subcategoryId,
        name: '',
        category: categoryId,
        categoryName: '',
        company: companyId,
        site: siteId,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      category: Category(
        id: categoryId,
        name: '',
        company: companyId,
        site: siteId,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      company: companyId,
      site: siteId,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'subcategory': subcategory.id, // Send only the ID
      'category': category.id, // Send only the ID
      'company': company,
      'site': site,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'subcategory': subcategory.id, // Send only the ID as string
      'category': category.id, // Send only the ID as string
      'company': company,
      'site': site,
    };
  }
}
// Inventory Model (for stock management)
class Inventory {
  final String id;
  final String? categoryId;
  final String? subcategoryId;
  final String itemId;
  final String companyId;
  final String siteId;
  final String uom;
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

  // Nested objects for detailed views
  final Category? category;
  final Subcategory? subcategory;
  final InventoryItem? item;

  Inventory({
    required this.id,
    this.categoryId,
    this.subcategoryId,
    required this.uom,

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
    this.category,
    this.subcategory,
    this.item,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    // Handle category
    String? categoryId;
    String? categoryName;
    Category? categoryObj;

    if (json['category'] is String) {
      categoryId = json['category'];
    } else if (json['category'] is Map) {
      categoryId = json['category']['_id'];
      categoryName = json['category']['name'];
      categoryObj = Category.fromJson(json['category']);
    }

    // Handle subcategory
    String? subcategoryId;
    String? subcategoryName;
    Subcategory? subcategoryObj;

    if (json['subcategory'] is String) {
      subcategoryId = json['subcategory'];
    } else if (json['subcategory'] is Map) {
      subcategoryId = json['subcategory']['_id'];
      subcategoryName = json['subcategory']['name'];
      subcategoryObj = Subcategory.fromJson(json['subcategory']);
    }

    // Handle item
    String itemId = '';
    String itemName = '';
    InventoryItem? itemObj;

    if (json['item'] is String) {
      itemId = json['item'];
    } else if (json['item'] is Map) {
      itemId = json['item']['_id'];
      itemName = json['item']['name'] ?? '';
      itemObj = InventoryItem.fromJson(json['item']);
    }

    return Inventory(
      id: json['_id'] ?? '',
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      itemId: itemId,
      companyId: json['company'] ?? '',
      siteId: json['site'] ?? '',
      totalQuantityAdded: (json['totalQuantityAdded'] ?? 0).toDouble(),
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toDouble(),
      remarks: json['remarks'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isDeleted: json['isDeleted'] ?? false,
      categoryName: categoryName,
      subcategoryName: subcategoryName,
      itemName: itemName,
      category: categoryObj,
      subcategory: subcategoryObj,
      item: itemObj, uom: json['uom'],
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

  // Get category name with fallback
  String get displayCategoryName => category?.name ?? categoryName ?? '';

  // Get subcategory name with fallback
  String get displaySubcategoryName => subcategory?.name ?? subcategoryName ?? '';

  // Get item name with fallback
  String get displayItemName => item?.name ?? itemName;
}

// Inventory Usage Model
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

  // Nested objects
  final Inventory? inventory;
  final InventoryItem? item;
  final Category? category;
  final Subcategory? subcategory;

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
    this.inventory,
    this.item,
    this.category,
    this.subcategory,
  });

  factory InventoryUsage.fromJson(Map<String, dynamic> json) {
    // Inventory
    String inventoryId = '';
    Inventory? inventoryObj;

    if (json['inventory'] is String) {
      inventoryId = json['inventory'];
    } else if (json['inventory'] is Map<String, dynamic>) {
      inventoryId = json['inventory']['_id'] ?? '';
      inventoryObj = Inventory.fromJson(json['inventory']);
    }

    // Item
    String itemId = '';
    String itemName = '';
    InventoryItem? itemObj;

    if (json['item'] is String) {
      itemId = json['item'];
    } else if (json['item'] is Map<String, dynamic>) {
      itemId = json['item']['_id'] ?? '';
      itemName = json['item']['name'] ?? '';
      itemObj = InventoryItem.fromJson(json['item']);
    }

    // Category
    Category? categoryObj;
    String? categoryName;

    if (json['category'] is Map<String, dynamic>) {
      categoryObj = Category.fromJson(json['category']);
      categoryName = json['category']['name'];
    }

    // Subcategory
    Subcategory? subcategoryObj;
    String? subcategoryName;

    if (json['subcategory'] is Map<String, dynamic>) {
      subcategoryObj = Subcategory.fromJson(json['subcategory']);
      subcategoryName = json['subcategory']['name'];
    }

    return InventoryUsage(
      id: json['_id'] ?? '',
      inventoryId: inventoryId,
      itemId: itemId,
      companyId: json['company'] ?? '',
      siteId: json['site'] ?? '',
      quantityUsed: (json['quantityUsed'] ?? 0).toDouble(),
      usageDate: DateTime.parse(
        json['usageDate'] ?? DateTime.now().toIso8601String(),
      ),
      remarks: json['remarks'],
      usedById: json['usedBy'] is Map
          ? json['usedBy']['_id'] ?? ''
          : json['usedBy'] ?? '',
      isDeleted: json['isDeleted'] ?? false,

      inventory: inventoryObj,
      item: itemObj,
      category: categoryObj,
      subcategory: subcategoryObj,

      categoryName: categoryName,
      subcategoryName: subcategoryName,
      itemName: itemName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventory': inventoryId,
      'item': itemId,
      'site': siteId,
      'quantityUsed': quantityUsed,
      'usageDate': usageDate.toIso8601String(),
      'remarks': remarks,
      'usedBy': usedById,
    };
  }

  // Display name getters with fallbacks
  String get displayCategoryName => category?.name ?? categoryName ?? '';
  String get displaySubcategoryName => subcategory?.name ?? subcategoryName ?? '';
  String get displayItemName => item?.name ?? itemName;
}

// Inventory Report Model
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
