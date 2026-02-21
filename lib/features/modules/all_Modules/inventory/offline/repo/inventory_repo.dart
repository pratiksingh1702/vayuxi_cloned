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
    return isar.inventoryUsageIsars
        .filter()
        .siteIdEqualTo(siteId)
        .watch(fireImmediately: true)
        .map((e) => e.map((x) => x.toModel()).toList());
  }

  Stream<List<InventoryCheckout>> watchCheckouts(String siteId) {
    return isar.inventoryCheckoutIsars
        .filter()
        .siteIdEqualTo(siteId)
        .watch(fireImmediately: true)
        .map((list) => list.map((e) => e.toModel()).toList());
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
          ..inventoryId = u.inventory
          ..quantityUsed = u.quantityUsed
          ..usedByName = u.usedByName
          ..usageDate = u.usageDate
          ..remarks = u.remarks
          ..updatedAt = u.usageDate).toList(),
      );

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
