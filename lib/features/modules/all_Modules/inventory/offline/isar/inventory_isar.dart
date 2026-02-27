import 'package:isar/isar.dart';
import '../../models/inventory_model.dart';

part 'inventory_isar.g.dart';

@collection
class InventoryCategoryIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String siteId;

  late String name;
  late String type; // consumable / fixed
  late DateTime updatedAt;
}

@collection
class InventoryIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String siteId;

  @Index()
  late String categoryId;

  late String name;
  late String type; // consumable

  String? uom;
  double? totalQuantityAdded;
  double? currentBalance;
  double? minimumStockLevel;

  // fixed
  int? totalUnits;
  int? availableUnits;

  String? condition;
  String? remarks;

  late bool isDeleted;
  late DateTime updatedAt;
}

@collection
class InventoryUsageIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String siteId;

  final inventory = IsarLink<InventoryIsar>();

  late double quantityUsed;
  String? uom;

  late String usedByName;
  String? usedById;

  late DateTime usageDate;
  String? remarks;

  late bool isDeleted;
  late DateTime createdAt;
  late DateTime updatedAt;
}
@collection
class InventoryCheckoutIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late String siteId;

  /// 🔥 relation instead of id
  final inventory = IsarLink<InventoryIsar>();

  late String issuedToName;
  late String status;
  late int quantity;

  DateTime? actualReturnDate;
  String? returnRemarks;

  late DateTime updatedAt;
}


extension CategoryIsarMapper on InventoryCategoryIsar {
  Category toModel() => Category(
    id: id,
    name: name,
    type: type,
  );
}

extension InventoryIsarMapper on InventoryIsar {
  Inventory toModel() => Inventory(
    id: id,
    name: name,
    category: Category(
      id: categoryId,
      name: '',
      type: '',
    ),
    type: type,
    uom: uom,
    totalQuantityAdded: totalQuantityAdded,
    currentBalance: currentBalance,
    minimumStockLevel: minimumStockLevel,
    totalUnits: totalUnits,
    availableUnits: availableUnits,
    condition: condition,
    remarks: remarks,
    createdAt: updatedAt,
  );
}

extension UsageIsarMapper on InventoryUsageIsar {
  InventoryUsage toModel() => InventoryUsage(
    id: id,
    inventory: inventory.value!.toModel(),
    quantityUsed: quantityUsed,
    uom: uom,
    usedByName: usedByName,
    usedBy: null, // not persisted fully locally
    usageDate: usageDate,
    remarks: remarks,
    isDeleted: isDeleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
extension CheckoutIsarMapper on InventoryCheckoutIsar {
  InventoryCheckout toModel() => InventoryCheckout(
    id: id,
    inventory: inventory.value!.toModel(),

    issuedToName: issuedToName,
    status: status,
    quantity: quantity,
    actualReturnDate: actualReturnDate,
    returnRemarks: returnRemarks,
  );
}
