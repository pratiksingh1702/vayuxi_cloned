import 'package:isar/isar.dart';
import '../../models/inventory_model.dart';
import '../../service/inventory_service.dart';
import '../isar/inventory_isar.dart';

class InventoryRepository {
  final Isar isar;
  final InventoryApi api;

  InventoryRepository(this.isar, this.api);

  // ---------------------------------------------------------------------------
  // WATCH
  // ---------------------------------------------------------------------------

  Stream<List<Category>> watchCategories(String siteId) {
    return isar.inventoryCategoryIsars
        .filter()
        .siteIdEqualTo(siteId)
        .watch(fireImmediately: true)
        .map((e) => e.map((x) => x.toModel()).toList());
  }

  Stream<List<Inventory>> watchInventory(String siteId) {
    return isar.inventoryIsars
        .filter()
        .siteIdEqualTo(siteId)
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((e) => e.map((x) => x.toModel()).toList());
  }

  Stream<List<Inventory>> watchLowStock(String siteId) {
    return watchInventory(siteId).map(
          (list) => list.where((e) => e.isLowStock).toList(),
    );
  }

  Stream<List<InventoryUsage>> watchUsage(String siteId) {
    print("👀 WATCH USAGE CALLED for site: $siteId");

    return isar.inventoryUsageIsars
        .filter()
        .siteIdEqualTo(siteId)
        .watch(fireImmediately: true)
        .map((e) {
      print("📦 ISAR USAGE EMITTED: ${e.length}");
      return e.map((x) => x.toModel()).toList();
    });
  }

  Stream<List<InventoryCheckout>> watchCheckouts(String siteId) {
    return isar.inventoryCheckoutIsars
        .filter()
        .siteIdEqualTo(siteId)
        .watch(fireImmediately: true)
        .map((list) => list.map((e) => e.toModel()).toList());
  }
  Future<Inventory> createInventory({
    required String siteId,
    required String name,
    required String categoryId,
    String? uom,
    double? totalQuantityAdded,
    double? minimumStockLevel,
    int? totalUnits,
    String? condition,
    String? remarks,
  }) async {

    // 1️⃣ Call API
    final created = await api.createInventory(
      siteId: siteId,
      name: name,
      categoryId: categoryId,
      uom: uom,
      totalQuantityAdded: totalQuantityAdded,
      minimumStockLevel: minimumStockLevel,
      totalUnits: totalUnits,
      condition: condition,
      remarks: remarks,
    );

    // 2️⃣ Persist locally immediately
    await isar.writeTxn(() async {
      print("➡️ Isar object prepared:");
      await isar.inventoryIsars.put(
        InventoryIsar()
          ..id = created.id
          ..siteId = siteId
          ..categoryId = created.category.id
          ..name = created.name
          ..type = created.type
          ..uom = created.uom
          ..totalQuantityAdded = created.totalQuantityAdded
          ..currentBalance = created.currentBalance
          ..minimumStockLevel = created.minimumStockLevel
          ..totalUnits = created.totalUnits
          ..availableUnits = created.availableUnits
          ..condition = created.condition
          ..remarks = created.remarks
          ..isDeleted = false
          ..updatedAt = DateTime.now(),
      );
    });
    final check = await isar.inventoryIsars
        .filter()
        .idEqualTo(created.id)
        .findFirst();

    print("🔎 DB CHECK: ${check?.name}");

    return created;
  }

  // ---------------------------------------------------------------------------
  // SYNC
  // ---------------------------------------------------------------------------

  Future<void> syncAll(String siteId) async {
    print("syncAll called❤️❤️");/**/
    final categories = await api.getCategories(siteId: siteId);

    List<Category> finalCategories = categories;

    if (categories.isEmpty) {
      final local = await isar.inventoryCategoryIsars
          .filter()
          .siteIdEqualTo(siteId)
          .findAll();

      if (local.isEmpty) {
        finalCategories = [
          Category(id: 'consumable', name: 'Consumable', type: 'consumable'),
          Category(id: 'fixed', name: 'Fixed', type: 'fixed'),
        ];
      } else {
        finalCategories = local.map((e) => e.toModel()).toList();
      }
    }


    final safeCategories = categories.isEmpty
        ? [
      Category(id: 'consumable', name: 'Consumable', type: 'consumable'),
      Category(id: 'fixed', name: 'Fixed', type: 'fixed'),
    ]
        : categories;

    List<Inventory> inventory = [];
    List<InventoryUsage> usage = [];
    List<InventoryCheckout> checkouts = [];

    try {
      inventory = await api.getAllInventory(siteId: siteId);
      print("📦 Inventory fetched: ${inventory.length}");
    } catch (e, st) {
      print("❌ Inventory fetch failed: $e");
      print(st);
    }

    try {
      usage = await api.getUsageHistory(siteId: siteId);
      print("🧾 Usage fetched: ${usage.length}");
    } catch (e, st) {
      print("❌ Usage fetch failed: $e");
      print(st);
    }

    try {
      checkouts = await api.getCheckouts(siteId: siteId);
      print("📤 Checkouts fetched: ${checkouts.length}");
    } catch (e, st) {
      print("❌ Checkouts fetch failed: $e");
      print(st);
    }

    print("📝 Writing categories to Isar: ${finalCategories.length}");
    for (final c in finalCategories) {
      print("   ↳ SAVE: ${c.id} | ${c.name} | ${c.type}");
    }

    await isar.writeTxn(() async {
      await isar.inventoryCategoryIsars.putAll(
        finalCategories.map((c) => InventoryCategoryIsar()
          ..id = c.id
          ..siteId = siteId
          ..name = c.name
          ..type = c.type
          ..updatedAt = DateTime.now(),
        ).toList(),
      );


      final afterWrite = await isar.inventoryCategoryIsars
          .filter()
          .siteIdEqualTo(siteId)
          .findAll();

      print("✅ DB AFTER WRITE: ${afterWrite.length}");
      for (final c in afterWrite) {
        print("   ↳ DB: ${c.id} | ${c.name} | ${c.type}");
      }
/**/

      await isar.inventoryIsars.putAll(
        inventory.map((i) => InventoryIsar()
          ..id = i.id
          ..siteId = siteId
          ..categoryId = i.category.id
          ..name = i.name
          ..type = i.type
          ..uom = i.uom
          ..totalQuantityAdded = i.totalQuantityAdded
          ..currentBalance = i.currentBalance
          ..minimumStockLevel = i.minimumStockLevel
          ..totalUnits = i.totalUnits
          ..availableUnits = i.availableUnits
          ..condition = i.condition
          ..remarks = i.remarks
          ..isDeleted = false
          ..updatedAt = i.createdAt).toList(),
      );

      await isar.inventoryUsageIsars.putAll(
        usage.map((u) => InventoryUsageIsar()
          ..id = u.id
          ..siteId = siteId
          ..quantityUsed = u.quantityUsed
          ..uom = u.uom
          ..usedByName = u.usedBy!.fullName
          ..usedById = u.usedBy?.id
          ..usageDate = u.usageDate
          ..remarks = u.remarks
          ..isDeleted = u.isDeleted
          ..createdAt = u.createdAt
          ..updatedAt = u.updatedAt
        ).toList(),
      );

// 🔥 Link inventory
      for (final u in usage) {
        final usageIsar = await isar.inventoryUsageIsars
            .filter()
            .idEqualTo(u.id)
            .findFirst();

        final inventoryIsar = await isar.inventoryIsars
            .filter()
            .idEqualTo(u.inventory.id)
            .findFirst();

        usageIsar?.inventory.value = inventoryIsar;
        await usageIsar?.inventory.save();
      }
      await isar.inventoryCheckoutIsars.putAll(
        checkouts.map((c) => InventoryCheckoutIsar()
          ..id = c.id
          ..siteId = siteId
          ..issuedToName = c.issuedToName
          ..status = c.status
          ..quantity = c.quantity
          ..actualReturnDate = c.actualReturnDate
          ..returnRemarks = c.returnRemarks
          ..updatedAt = DateTime.now(),
        ).toList(),
      );

// after put → link inventories
      for (final c in checkouts) {
        final checkoutIsar = await isar.inventoryCheckoutIsars
            .filter()
            .idEqualTo(c.id)
            .findFirst();

        final inventoryIsar = await isar.inventoryIsars
            .filter()
            .idEqualTo(c.inventory.id)
            .findFirst();

        checkoutIsar?.inventory.value = inventoryIsar;
        await checkoutIsar?.inventory.save();
      }

    });
  }
}
