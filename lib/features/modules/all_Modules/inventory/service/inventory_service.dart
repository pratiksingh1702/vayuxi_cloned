// api/inventory_api.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../../core/api/dio.dart';
import '../models/inventory_model.dart';

class InventoryApi {
  static final dio = DioClient.dio;

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
  Future<BulkUploadResult> bulkUploadInventory({
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
        return BulkUploadResult.fromJson(response.data);
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
    DateTime? usageDate,
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
        if (usageDate != null) 'usageDate': usageDate.toIso8601String().split('T')[0],
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
  Future<InventoryReport> generateReport({
    required String siteId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final response = await dio.get(
        '/inventory/report',
        queryParameters: {
          'siteId': siteId,
          'fromDate': fromDate.toIso8601String().split('T')[0],
          'toDate': toDate.toIso8601String().split('T')[0],
        },
      );

      if (response.statusCode == 200) {
        return InventoryReport.fromJson(response.data);
      } else {
        throw Exception('Failed to generate report');
      }
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