
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import 'dart:typed_data';


class ExpenseAPI {
  static final dio = DioClient.dio;

  // Fetch expenses
  static Future<List<dynamic>> fetchExpenses({
    required String type,
    required String siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'type': type};

    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['endDate'] = endDate.toIso8601String();
    }

    final response = await dio.get(
      "/site/$siteId/expenses",
      queryParameters: params,
    );
    return response.data;
  }
// Bulk delete expenses
  static Future<void> bulkDeleteExpenses({
    required List<String> expenseIds,
  }) async {
    if (expenseIds.isEmpty) {
      throw Exception("No expense IDs provided for bulk delete");
    }

    try {
      final response = await dio.post(
        "/expenses/bulk-delete",
        data: {
          "ids": expenseIds,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          "Bulk expense delete failed: ${response.statusCode} ${response.data}",
        );
      }

      print("✅ Bulk expense delete successful");
      print("🗑 Deleted IDs: $expenseIds");
    } on DioException catch (e, stack) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      print("❌ BULK DELETE EXPENSE FAILED");
      print("➡️ POST /expenses/bulk-delete");
      print("📟 STATUS: $status");
      print("📦 RESPONSE: $data");
      print(stack);

      rethrow;
    } catch (e, stack) {
      print("❌ UNEXPECTED BULK DELETE ERROR");
      print("📝 ERROR: $e");
      print(stack);
      rethrow;
    }
  }

  // Create expense
  static Future<Map<String, dynamic>> createExpense({
    required Map<String, dynamic> data,
    required String type,
    required String siteId,
  }) async {
    final response = await dio.post(
      "/site/$siteId/expenses?type=$type",
      data: data,
    );
    return response.data;
  }

  // Get expense by ID
  static Future<Map<String, dynamic>> getExpenseById({
    required String siteId,
    required String expenseId,
  }) async {
    final response = await dio.get(
      "/site/$siteId/expenses/$expenseId",
    );
    return response.data;
  }

  // Update expense
  static Future<Map<String, dynamic>> updateExpense({
    required Map<String, dynamic> data,
    required String siteId,
    required String expenseId,
  }) async {
    final response = await dio.put(
      "/site/$siteId/expenses/$expenseId",
      data: data,
    );
    return response.data;
  }

  // Delete expense
  static Future<Map<String, dynamic>> deleteExpense({
    required String siteId,
    required String expenseId,
  }) async {
    final response = await dio.delete(
      "/site/$siteId/expenses/$expenseId",
    );
    return response.data;
  }

  // Generate CSV
  static Future<String> generateExpenseCSV({
    required String serviceType,
    required String type,
    required String siteId,
    required String startDate,
    required String endDate,
    String expenseType="material_tools",
  }) async {
    try {


      // Encode parameters
      final encodedType = Uri.encodeComponent(type);
      final encodedServiceType = Uri.encodeComponent(serviceType);

      // Construct URL with all required parameters
      final url = "/site/$siteId/expenses/generate-expenses?type=$type&serviceType=$encodedServiceType&startDate=${Uri.encodeComponent(startDate)}&endDate=${Uri.encodeComponent(endDate)}";

      print('📊 Generating CSV with URL: $url');

      final response = await dio.get(url,
          options: Options(responseType: ResponseType.bytes),)
      ;

      if (response.statusCode == 200) {
        print('✅ CSV generated successfully');
        return response.data;
      } else {
        throw HttpException(
          'Failed to generate CSV: ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }
    } on DioException catch (e) {
      // More specific Dio error handling
      print('❌ Dio Error generating CSV');
      print('URL: ${e.requestOptions.uri}');
      print('Status: ${e.response?.statusCode}');
      print('Error: ${e.message}');
      print('Response: ${e.response?.data}');

      // You might want to throw a more specific exception
      throw Exception('Failed to generate CSV: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error generating CSV: $e');
      rethrow;
    }
  }
  static Future<Uint8List> generateExpenseExcel({
    required String serviceType,
    required String type,
    required String siteId,
    required String startDate,
    required String endDate,
  }) async {
    final url =
        "/site/$siteId/expenses/generate-expenses?type=$type&serviceType=$serviceType&startDate=$startDate&endDate=$endDate";

    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    if (response.statusCode == 200) {
      print('✅ Excel generated');
      return Uint8List.fromList(response.data);
    }

    throw Exception("Failed to download excel");
  }

  // Helper method to format date as YYYY-MM-DD
  static String _formatDateForAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}