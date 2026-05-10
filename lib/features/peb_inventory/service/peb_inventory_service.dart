import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/peb_inventory_model.dart';

class PebInventoryService {
  final Dio _dio = DioClient.dio;

  Future<List<PebInventoryItem>> getInventory(String siteId, {String? workType, String? materialType}) async {
    final res = await _dio.get('/site/$siteId/peb-inventory', queryParameters: {
      if (workType != null) 'workType': workType,
      if (materialType != null) 'materialType': materialType,
    });
    return (res.data as List).map((e) => PebInventoryItem.fromJson(e)).toList();
  }

  Future<PebInventoryItem> createItem(String siteId, PebInventoryItem item) async {
    final res = await _dio.post('/site/$siteId/peb-inventory', data: item.toJson());
    return PebInventoryItem.fromJson(res.data);
  }

  Future<void> updateItem(String siteId, String inventoryId, Map<String, dynamic> data) async {
    await _dio.put('/site/$siteId/peb-inventory/$inventoryId', data: data);
  }

  Future<void> deleteItem(String siteId, String inventoryId) async {
    await _dio.delete('/site/$siteId/peb-inventory/$inventoryId');
  }

  Future<void> addMovement(String siteId, String inventoryId, InventoryMovement movement) async {
    await _dio.post('/site/$siteId/peb-inventory/$inventoryId/movement', data: movement.toJson());
  }

  Future<void> reserveStock(String siteId, String inventoryId, Map<String, dynamic> reservation) async {
    await _dio.post('/site/$siteId/peb-inventory/$inventoryId/reserve', data: reservation);
  }

  Future<void> consumeStock(String siteId, String inventoryId, Map<String, dynamic> consumption) async {
    await _dio.post('/site/$siteId/peb-inventory/$inventoryId/consume', data: consumption);
  }
}
