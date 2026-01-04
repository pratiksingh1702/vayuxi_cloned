import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/pipingModel.dart';

import 'equipmentModel.dart';

class HiveStorageService {
  static const String _pipingBoxName = 'pipingMaterials';
  static const String _equipmentBoxName = 'equipmentMaterials';

  // Initialize Hive
  static Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // Register adapters
    // if (!Hive.isAdapterRegistered(0)) {
    //   Hive.registerAdapter(PipingItemAdapter());
    // }
    // if (!Hive.isAdapterRegistered(1)) {
    //   Hive.registerAdapter(EquipmentItemAdapter());
    // }

    // Open boxes
    await Hive.openBox<PipingItem>(_pipingBoxName);
    await Hive.openBox<EquipmentItem>(_equipmentBoxName);
  }

  // Piping Materials Operations

  static Future<void> saveAllPipingMaterials(List<PipingItem> materials) async {
    final box = Hive.box<PipingItem>(_pipingBoxName);
    await box.clear();

    for (var material in materials) {
      await box.put(material.id, material);
    }
  }

  static Future<List<PipingItem>> getAllPipingMaterials() async {
    final box = Hive.box<PipingItem>(_pipingBoxName);
    return box.values.toList();
  }

  static Future<void> addPipingMaterial(PipingItem material) async {
    print("material added ✅✅✅");
    final box = Hive.box<PipingItem>(_pipingBoxName);
    await box.put(material.id, material);
  }

  static Future<void> updatePipingMaterial(String id, PipingItem material) async {
    final box = Hive.box<PipingItem>(_pipingBoxName);
    await box.put(id, material);
  }

  static Future<void> deletePipingMaterial(String id) async {
    final box = Hive.box<PipingItem>(_pipingBoxName);
    await box.delete(id);
  }

  static Future<PipingItem?> getPipingMaterial(String id) async {
    final box = Hive.box<PipingItem>(_pipingBoxName);
    return box.get(id);
  }

  // Equipment Materials Operations

  static Future<void> saveAllEquipmentMaterials(List<EquipmentItem> materials) async {
    final box = Hive.box<EquipmentItem>(_equipmentBoxName);
    await box.clear();

    for (var material in materials) {
      await box.put(material.id, material);
    }
  }

  static Future<List<EquipmentItem>> getAllEquipmentMaterials() async {
    final box = Hive.box<EquipmentItem>(_equipmentBoxName);
    return box.values.toList();
  }

  static Future<void> addEquipmentMaterial(EquipmentItem material) async {
    final box = Hive.box<EquipmentItem>(_equipmentBoxName);
    await box.put(material.id, material);
  }

  static Future<void> updateEquipmentMaterial(String id, EquipmentItem material) async {
    final box = Hive.box<EquipmentItem>(_equipmentBoxName);
    await box.put(id, material);
  }

  static Future<void> deleteEquipmentMaterial(String id) async {
    final box = Hive.box<EquipmentItem>(_equipmentBoxName);
    await box.delete(id);
  }

  static Future<EquipmentItem?> getEquipmentMaterial(String id) async {
    final box = Hive.box<EquipmentItem>(_equipmentBoxName);
    return box.get(id);
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final pipingBox = Hive.box<PipingItem>(_pipingBoxName);
    final equipmentBox = Hive.box<EquipmentItem>(_equipmentBoxName);

    await pipingBox.clear();
    await equipmentBox.clear();
  }

  // Backup data
  static Future<void> backupData() async {
    // You can implement backup logic here
    // For example, save to a specific file or cloud storage
  }

  // Restore data
  static Future<void> restoreData() async {
    // You can implement restore logic here
  }
}