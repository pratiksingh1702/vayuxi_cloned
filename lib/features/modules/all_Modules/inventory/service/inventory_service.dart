// api/inventory_api.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/dio.dart';
import '../models/inventory_Model.dart';


class InventoryApi {
  static final dio = DioClient.dio;
  // Category APIs

  // 1. Get All Categories
  Future<List<Category>> getCategories({
    required String siteId,
  }) async {
    try {
      final response = await dio.get(
        '/site/$siteId/inventory/category',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  // 2. Create Category
  Future<Category> createCategory({
    required String siteId,
    required String name,
  }) async {
    try {
      final response = await dio.post(
        '/site/$siteId/inventory/category',
        data: {'name': name},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Category.fromJson(response.data);
      } else {
        throw Exception('Failed to create category');
      }
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  // 3. Update Category
  Future<Category> updateCategory({
    required String siteId,
    required String categoryId,
    required String name,
  }) async {
    try {
      final response = await dio.put(
        '/site/$siteId/inventory/category/$categoryId',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        return Category.fromJson(response.data);
      } else {
        throw Exception('Failed to update category');
      }
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // 4. Delete Category
  Future<void> deleteCategory({
    required String siteId,
    required String categoryId,
  }) async {
    try {
      final response = await dio.delete(
        '/site/$siteId/inventory/category/$categoryId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete category');
      }
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Subcategory APIs

  // 5. Get All Subcategories
  Future<List<Subcategory>> getSubcategories({
    required String siteId,
    String? categoryId,
  }) async {
    try {
      final queryParams = {
        if (categoryId != null) 'categoryId': categoryId,
      };

      final response = await dio.get(
        '/site/$siteId/inventory/subcategory',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => Subcategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      print('Error fetching subcategories: $e');
      rethrow;
    }
  }

  // 6. Create Subcategory
  Future<Subcategory> createSubcategory({
    required String siteId,
    required String name,
    required String categoryId,
  }) async {
    try {
      final response = await dio.post(
        '/site/$siteId/inventory/subcategory',
        data: {
          'name': name,
          'category': categoryId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Subcategory.fromJson(response.data);
      } else {
        throw Exception('Failed to create subcategory');
      }
    } catch (e) {
      print('Error creating subcategory: $e');
      rethrow;
    }
  }

  // 7. Update Subcategory
  Future<Subcategory> updateSubcategory({
    required String siteId,
    required String subcategoryId,
    required String name,
    required String categoryId,
  }) async {
    try {
      final response = await dio.put(
        '/site/$siteId/inventory/subcategory/$subcategoryId',
        data: {
          'name': name,
          'category': categoryId,
        },
      );

      if (response.statusCode == 200) {
        return Subcategory.fromJson(response.data);
      } else {
        throw Exception('Failed to update subcategory');
      }
    } catch (e) {
      print('Error updating subcategory: $e');
      rethrow;
    }
  }

  // 8. Delete Subcategory
  Future<void> deleteSubcategory({
    required String siteId,
    required String subcategoryId,
  }) async {
    try {
      final response = await dio.delete(
        '/site/$siteId/inventory/subcategory/$subcategoryId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete subcategory');
      }
    } catch (e) {
      print('Error deleting subcategory: $e');
      rethrow;
    }
  }

  // Item APIs

  // 9. Get All Items
  Future<List<InventoryItem>> getItems({
    required String siteId,
    String? subcategoryId,
  }) async {
    try {
      final queryParams = {
        if (subcategoryId != null) 'subcategoryId': subcategoryId,
      };

      final response = await dio.get(
        '/site/$siteId/inventory/item',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => InventoryItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print('Error fetching items: $e');
      rethrow;
    }
  }

  // 10. Create Item
  Future<InventoryItem> createItem({
    required String siteId,
    required String name,
    required String categoryId,
    required String subcategoryId,
  }) async {
    try {
      final response = await dio.post(
        '/site/$siteId/inventory/item',
        data: {
          'name': name,
          'category': categoryId,
          'subcategory': subcategoryId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InventoryItem.fromJson(response.data);
      } else {
        throw Exception('Failed to create item');
      }
    } catch (e) {
      print('Error creating item: $e');
      rethrow;
    }
  }

  // 11. Update Item
  Future<InventoryItem> updateItem({
    required String siteId,
    required String itemId,
    required String name,
    required String categoryId,
    required String subcategoryId,
  }) async {
    try {
      final response = await dio.put(
        '/site/$siteId/inventory/item/$itemId',
        data: {
          'name': name,
          'category': categoryId,
          'subcategory': subcategoryId,
        },
      );

      if (response.statusCode == 200) {
        return InventoryItem.fromJson(response.data);
      } else {
        throw Exception('Failed to update item');
      }
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  // 12. Delete Item
  Future<void> deleteItem({
    required String siteId,
    required String itemId,
  }) async {
    try {
      final response = await dio.delete(
        '/site/$siteId/inventory/item/$itemId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete item');
      }
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
    }
  }

  // Inventory Stock APIs

  // 13. Add/Update Inventory Stock
  Future<Inventory> addUpdateInventoryStock({
    required String siteId,
    required String itemId,
    required String categoryId,
    required String subcategoryId,
    required double totalQuantityAdded,
    required double minimumStockLevel,
    required String uom,
    String? remarks,
  }) async {
    try {
      final payload = {
        'item': itemId,
        'category': categoryId,
        'subcategory': subcategoryId,
        'totalQuantityAdded': totalQuantityAdded,
        'minimumStockLevel': minimumStockLevel,
        'uom': uom,
        if (remarks != null) 'remarks': remarks,
      };

      final response = await dio.post(
        '/site/$siteId/inventory',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Inventory.fromJson(response.data);
      } else {
        throw Exception('Failed to add/update inventory stock');
      }
    } catch (e) {
      print('Error adding/updating inventory stock: $e');
      rethrow;
    }
  }
  // 20. Get All Inventory Stock
  Future<List<Inventory>> getAllInventory({
    required String siteId,
  }) async {
    try {
      final response = await dio.get(
        '/site/$siteId/inventory',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => Inventory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load inventory stock');
      }
    } catch (e) {
      print('Error fetching inventory stock: $e');
      rethrow;
    }
  }

// 21. Get Inventory Stock with Filtering
  Future<List<Inventory>> getInventoryWithFilters({
    required String siteId,
    String? categoryId,
    String? subcategoryId,
    String? itemId,
    bool? lowStockOnly,
  }) async {
    try {
      final queryParams = {
        if (categoryId != null) 'categoryId': categoryId,
        if (subcategoryId != null) 'subcategoryId': subcategoryId,
        if (itemId != null) 'itemId': itemId,
        if (lowStockOnly != null) 'lowStockOnly': lowStockOnly,
      };

      final response = await dio.get(
        'site/$siteId/inventory',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => Inventory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load filtered inventory');
      }
    } catch (e) {
      print('Error fetching filtered inventory: $e');
      rethrow;
    }
  }

  // 14. Get Inventory by ID
  Future<Inventory> getInventoryById({
    required String siteId,
    required String inventoryId,
  }) async {
    try {
      final response = await dio.get(
        '/site/$siteId/inventory/$inventoryId',
      );

      if (response.statusCode == 200) {
        return Inventory.fromJson(response.data);
      } else {
        throw Exception('Failed to load inventory');
      }
    } catch (e) {
      print('Error fetching inventory: $e');
      rethrow;
    }
  }

  // 15. Update Inventory
  Future<Inventory> updateInventory({
    required String siteId,
    required String inventoryId,
    double? totalQuantityAdded,
    double? minimumStockLevel,
    String? uom,
    String? remarks,
  }) async {
    try {
      final payload = {
        if (totalQuantityAdded != null) 'totalQuantityAdded': totalQuantityAdded,
        if (minimumStockLevel != null) 'minimumStockLevel': minimumStockLevel,
        if (uom != null) 'uom': uom,
        if (remarks != null) 'remarks': remarks,
      };

      final response = await dio.put(
        '/site/$siteId/inventory/$inventoryId',
        data: payload,
      );

      if (response.statusCode == 200) {
        return Inventory.fromJson(response.data);
      } else {
        throw Exception('Failed to update inventory');
      }
    } catch (e) {
      print('Error updating inventory: $e');
      rethrow;
    }
  }

  // 16. Delete Inventory
  Future<void> deleteInventory({
    required String siteId,
    required String inventoryId,
  }) async {
    try {
      final response = await dio.delete(
        '/site/$siteId/inventory/$inventoryId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete inventory');
      }
    } catch (e) {
      print('Error deleting inventory: $e');
      rethrow;
    }
  }

  // 17. Get Usage History
  Future<List<InventoryUsage>> getUsageHistory({
    required String siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T')[0],
      };

      final response = await dio.get(
        '/site/$siteId/inventory/usage',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => InventoryUsage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load usage history');
      }
    } catch (e) {
      print('Error fetching usage history: $e');
      rethrow;
    }
  }

  // 18. Get Low Stock Items
  Future<List<Inventory>> getLowStockItems({
    required String siteId,
  }) async {
    try {
      final response = await dio.get(
        '/site/$siteId/inventory/low-stock',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => Inventory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load low stock items');
      }
    } catch (e) {
      print('Error fetching low stock items: $e');
      rethrow;
    }
  }

  // 19. Bulk Upload Inventory via JSON
  Future<Map<String, dynamic>> bulkUploadInventoryJson({
    required String siteId,
    required List<Map<String, dynamic>> inventoryData,
  }) async {
    try {
      final response = await dio.post(
        '/site/$siteId/inventory/bulk-upload',
        data: {'data': inventoryData},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to bulk upload inventory');
      }
    } catch (e) {
      print('Error in bulk upload: $e');
      rethrow;
    }
  }

  // 1. Get Inventory List
  Future<List<Inventory>> getInventoryList({
    required String siteId,
  }) async {
    try {
      final response = await dio.get(
        '/inventory',
        queryParameters: {
          'siteId': siteId,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => Inventory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load inventory list');
      }
    } catch (e) {
      print('Error fetching inventory list: $e');
      rethrow;
    }
  }

  // 2. Bulk Upload Inventory via CSV
  Future<Map<String, dynamic>> bulkUploadInventory({
    required String siteId,
    required File csvFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'siteId': siteId,
        'file': await MultipartFile.fromFile(
          csvFile.path,
          filename: 'inventory_upload.csv',
        ),
      });

      final response = await dio.post(
        '/inventory/bulk-upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to upload inventory CSV');
      }
    } catch (e) {
      print('Error uploading inventory CSV: $e');
      rethrow;
    }
  }

  // 3. Record Inventory Usage
  Future<InventoryUsage> recordInventoryUsage({
    required String inventoryId,
    required String itemId,
    required String siteId,
    required double quantityUsed,
    String? categoryId,
    String? subcategoryId,
    String? usageDate,
    String? remarks,
  }) async {
    try {
      final payload = {
        'inventoryId': inventoryId,
        'itemId': itemId,
        'siteId': siteId,
        'quantityUsed': quantityUsed,
        if (categoryId != null) 'categoryId': categoryId,
        if (subcategoryId != null) 'subcategoryId': subcategoryId,
        if (usageDate != null) 'usageDate': usageDate,
        if (remarks != null) 'remarks': remarks,
      };

      final response = await dio.post(
        '/inventory/usage',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InventoryUsage.fromJson(response.data);
      } else {
        throw Exception('Failed to record inventory usage');
      }
    } catch (e) {
      print('Error recording inventory usage: $e');
      rethrow;
    }
  }

  // 4. Get Daily Inventory Usage List
  Future<List<InventoryUsage>> getDailyUsage({
    required String siteId,
    DateTime? date,
  }) async {
    try {
      final queryParams = {
        'siteId': siteId,
        if (date != null) 'date': date.toIso8601String().split('T')[0],
      };

      final response = await dio.get(
        '/inventory/daily-usage',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        return data.map((json) => InventoryUsage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load daily usage');
      }
    } catch (e) {
      print('Error fetching daily usage: $e');
      rethrow;
    }
  }

  // 5. Generate Inventory Usage Report (Excel)
  Future<Uint8List> generateReport({
    required String siteId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await dio.get(
        '/site/$siteId/inventory/report',
        queryParameters: {
          'format': 'excel',
          'siteId': siteId,
          'fromDate': fromDate.toIso8601String().split('T')[0],
          'toDate': toDate.toIso8601String().split('T')[0],
        },
        options: Options(
          responseType: ResponseType.bytes, // 🔥 IMPORTANT
        ),
      );

      return Uint8List.fromList(response.data);
    } catch (e) {
      print('Error generating report: $e');
      rethrow;
    }
  }

  // Helper method to download and save Excel file
  Future<File> downloadReport(InventoryReport report) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${report.fileName}');

      // Decode base64 and write to file
      final bytes = base64.decode(report.data);
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      print('Error downloading report: $e');
      rethrow;
    }
  }

}