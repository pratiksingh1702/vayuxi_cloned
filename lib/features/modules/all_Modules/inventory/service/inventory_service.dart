// api/inventory_api.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/dio.dart';
import '../models/inventory_model.dart';


class InventoryApi {
  static final dio = DioClient.dio;
  // Category APIs


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
  Future<Uint8List> generateReport({
    required String siteId,
    required DateTime fromDate,
  }) async {
    try {
      final response = await dio.get(
        '/site/$siteId/inventory/report',
        queryParameters: {
          'format': 'excel',
          'siteId': siteId,
          'fromDate': fromDate.toIso8601String().split('T')[0],
          'toDate': fromDate.toIso8601String().split('T')[0],
        },
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      /// STEP 1 → bytes to string
      final jsonString = utf8.decode(response.data);

      /// STEP 2 → string to json
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      /// STEP 3 → take base64
      final String base64File = jsonMap['data'];

      /// STEP 4 → base64 to real excel bytes
      final Uint8List excelBytes = base64Decode(base64File);

      return excelBytes;
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
// ---------------------------------------------------------------------------
  // ✅ CATEGORY (READ ONLY)
  // ---------------------------------------------------------------------------

  Future<List<Category>> getCategories({
    required String siteId,
  }) async {
    final res = await dio.get('/site/$siteId/inventory/category');

    final List data = res.data ?? [];
    return data.map((e) => Category.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // ✅ INVENTORY
  // ---------------------------------------------------------------------------

  Future<List<Inventory>> getAllInventory({
    required String siteId,
    String? type,
  }) async {
    final res = await dio.get(
      '/site/$siteId/inventory',
      queryParameters: {
        if (type != null) 'type': type,
      },
    );

    final List data = res.data ?? [];
    return data.map((e) => Inventory.fromJson(e)).toList();
  }



  Future<Inventory> createInventory({
    required String siteId,
    required String name,
    required String categoryId,

    // consumable
    String? uom,
    double? totalQuantityAdded,
    double? minimumStockLevel,

    // fixed
    int? totalUnits,
    String? condition,

    String? remarks,
  }) async {
    final payload = {
      'name': name,
      'category': categoryId,
      if (uom != null) 'uom': uom,
      if (totalQuantityAdded != null)
        'totalQuantityAdded': totalQuantityAdded,
      if (minimumStockLevel != null)
        'minimumStockLevel': minimumStockLevel,
      if (totalUnits != null) 'totalUnits': totalUnits,
      if (condition != null) 'condition': condition,
      if (remarks != null) 'remarks': remarks,
    };

    final res = await dio.post(
      '/site/$siteId/inventory',
      data: payload,
    );

    return Inventory.fromJson(res.data);
  }

  Future<Inventory> updateInventory({
    required String siteId,
    required String inventoryId,

    String? name,
    String? uom,
    double? minimumStockLevel,
    int? totalUnits,
    String? condition,
    String? remarks,
  }) async {
    final payload = {
      if (name != null) 'name': name,
      if (uom != null) 'uom': uom,
      if (minimumStockLevel != null)
        'minimumStockLevel': minimumStockLevel,
      if (totalUnits != null) 'totalUnits': totalUnits,
      if (condition != null) 'condition': condition,
      if (remarks != null) 'remarks': remarks,
    };

    final res = await dio.put(
      '/site/$siteId/inventory/$inventoryId',
      data: payload,
    );

    return Inventory.fromJson(res.data);
  }


  // ---------------------------------------------------------------------------
  // ✅ QUANTITY ADD (CONSUMABLE)
  // ---------------------------------------------------------------------------

  Future<Inventory> addQuantity({
    required String siteId,
    required String inventoryId,
    required double quantity,
  }) async {
    final res = await dio.post(
      '/site/$siteId/inventory/$inventoryId/add-quantity',
      data: {
        'quantity': quantity,
        'operation': 'add',
      },
    );

    return Inventory.fromJson(res.data);
  }

  // ---------------------------------------------------------------------------
  // ✅ USAGE (CONSUMABLE)
  // ---------------------------------------------------------------------------

  Future<InventoryUsage> recordUsage({
    required String siteId,
    required String inventoryId,
    required double quantityUsed,
    required String usedByName,
    DateTime? usageDate,
    String? remarks,
  }) async {
    final payload = {
      'inventory': inventoryId,
      'quantityUsed': quantityUsed,
      'usedByName': usedByName,
      if (usageDate != null)
        'usageDate': usageDate.toIso8601String().split('T')[0],
      if (remarks != null) 'remarks': remarks,
    };

    final res = await dio.post(
      '/site/$siteId/inventory/usage',
      data: payload,
    );

    return InventoryUsage.fromJson(res.data['usage'] ?? res.data);
  }



  // ---------------------------------------------------------------------------
  // ✅ CHECKOUT (FIXED)
  // ---------------------------------------------------------------------------

  Future<InventoryCheckout> checkoutItem({
    required String siteId,
    required String inventoryId,
    required String issuedToName,
    int quantity = 1,
    DateTime? expectedReturnDate,
    String? remarks,
  }) async {
    final payload = {
      'inventory': inventoryId,
      'issuedToName': issuedToName,
      'quantity': quantity,
      if (expectedReturnDate != null)
        'expectedReturnDate':
        expectedReturnDate.toIso8601String().split('T')[0],
      if (remarks != null) 'remarks': remarks,
    };

    final res = await dio.post(
      '/site/$siteId/inventory/checkout',
      data: payload,
    );

    return InventoryCheckout.fromJson(res.data['checkout']);
  }

  Future<InventoryCheckout> updateCheckout({
    required String siteId,
    required String checkoutId,
    required String status,
    DateTime? actualReturnDate,
    String? returnRemarks,
    String? condition,
  }) async {
    final payload = {
      'status': status,
      if (actualReturnDate != null)
        'actualReturnDate':
        actualReturnDate.toIso8601String().split('T')[0],
      if (returnRemarks != null) 'returnRemarks': returnRemarks,
      if (condition != null) 'condition': condition,
    };

    final res = await dio.put(
      '/site/$siteId/inventory/checkout/$checkoutId',
      data: payload,
    );

    return InventoryCheckout.fromJson(res.data['checkout']);
  }

  Future<List<InventoryCheckout>> getCheckouts({
    required String siteId,
    String? status,
  }) async {
    final res = await dio.get(
      '/site/$siteId/inventory/checkout',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );

    final List data = res.data ?? [];
    return data.map((e) => InventoryCheckout.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // ✅ LOW STOCK
  // ---------------------------------------------------------------------------

  Future<List<Inventory>> getLowStock({
    required String siteId,
  }) async {
    final res = await dio.get('/site/$siteId/inventory/low-stock');

    final List data = res.data ?? [];
    return data.map((e) => Inventory.fromJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // ✅ REPORT
  // ---------------------------------------------------------------------------

  Future<Uint8List> downloadExcelReport({
    required String siteId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final res = await dio.post(
      '/site/$siteId/inventory/report/excel',
      data: {
        'fromDate': fromDate.toIso8601String().split('T')[0],
        'toDate': toDate.toIso8601String().split('T')[0],
      },
    );

    final String base64File = res.data['data'];
    return base64Decode(base64File);
  }
}