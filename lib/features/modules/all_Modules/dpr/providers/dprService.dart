import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../../core/api/dio.dart';
import '../models/dprModel.dart';


class DprApi {
  // ----------------------------
  // 1. Fetch DPR Work List
  // ----------------------------
  static Future<List<DprModel>> fetchDprWork({
    required String siteId,
    required String teamId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team/$teamId/dpr-mechanical",
        options: Options(extra: {"withCredentials": true}),
      );

      print("🔹 DPR Work Response Status: ${response.statusCode}");
      printFormattedJson(response.data);

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => DprModel.fromJson(e))
            .toList();
      } else {
        throw Exception("Failed to fetch DPR work. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error fetching DPR work: $e");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 2. Fetch DPR Work by ID
  // ----------------------------
  static Future<DprModel> fetchDprWorkById({
    required String siteId,
    required String teamId,
    required String workId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team/$teamId/dpr-mechanical/$workId",
        options: Options(extra: {"withCredentials": true}),
      );
      printFormattedJson(response.data);

      if (response.statusCode == 200) {
        return DprModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch DPR work by ID. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error fetching DPR by ID: $e");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 3. Post DPR Work
  // ----------------------------
  static Future<DprModel> postDprWork({
    required Map<String, dynamic> data,
    required String siteId,
    required String teamId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/team/$teamId/dpr-mechanical",
        data: data,
        queryParameters: {"type": "mechanical_work"},
        options: Options(extra: {"withCredentials": true}),
      );

      printFormattedJson(response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DprModel.fromJson(response.data);
      } else {
        throw Exception("Failed to post DPR work. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error posting DPR: $e");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 4. Update DPR Work
  // ----------------------------
  static Future<void> updateDprWork({
    required Map<String, dynamic> data,
    required String mechanicalId,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/mechnical/$mechanicalId/update",
        data: data,
        options: Options(extra: {"withCredentials": true}),
      );
      printFormattedJson(response.data);

      if (response.statusCode != 200) {
        throw Exception("Failed to update DPR work. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error updating DPR: $e");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 5. Update DPR Material Qty
  // ----------------------------
  static Future<void> updateDprMaterialQty({
    required Map<String, dynamic> data,
    required String siteId,
    required String materialId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/team/$materialId/dpr-mechanical/qty",
        data: data,
        options: Options(
          headers: {"Content-Type": "application/json"},
          extra: {"withCredentials": true},
        ),
      );

      printFormattedJson(response.data);

      if (response.statusCode != 200) {
        throw Exception("Failed to update DPR material qty. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error updating DPR material qty: $e");
      print(stack);
      rethrow;
    }
    Future<Map<String, dynamic>> fetchMaterialById({
      required String mechanicalId,
      required String editDprId,
    }) async {
      try {
        final response = await DioClient.dio.get(
          "/site/$mechanicalId/team/$editDprId/dpr-mechanical/qty",
          options: Options(extra: {"withCredentials": true}),
        );

        if (response.statusCode == 200) {
          return response.data;
        } else {
          throw Exception("Failed to fetch material. Status: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Error fetching material: $e");
        rethrow;
      }
    }

    // Post material
    Future<Map<String, dynamic>> postMaterial({
      required FormData data,
      required String mechanicalId,
    }) async {
      try {
        final response = await DioClient.dio.post(
          "/mechnical/$mechanicalId",
          data: data,
          options: Options(extra: {"withCredentials": true}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return response.data;
        } else {
          throw Exception("Failed to post material. Status: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Error posting material: $e");
        rethrow;
      }
    }

    // Update material
    Future<Map<String, dynamic>> updateMaterial({
      required FormData data,
      required String mechanicalId,
    }) async {
      try {
        final response = await DioClient.dio.patch(
          "/mechnical/$mechanicalId",
          data: data,
          options: Options(extra: {"withCredentials": true}),
        );

        if (response.statusCode == 200) {
          return response.data;
        } else {
          throw Exception("Failed to update material. Status: ${response.statusCode}");
        }
      } catch (e) {
        print("❌ Error updating material: $e");
        rethrow;
      }
    }
  }

  // ----------------------------
  // 6. Copy DPR Material
  // ----------------------------
  static Future<void> copyDprMaterial({
    required String siteId,
    required String materialId,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/site/$siteId/team/$materialId/dpr-mechanical/copy",
        options: Options(extra: {"withCredentials": true}),
      );

      printFormattedJson(response.data);

      if (response.statusCode != 200) {
        throw Exception("Failed to copy DPR material. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error copying DPR material: $e");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 7. Sheet Handlers
  // ----------------------------
  static Future<List<dynamic>> fetchMeasurementSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
  }) async =>
      _fetchSheet("/site/$siteId/team/123/dpr-mechanical/measurment-sheet-dpr", fromDate, toDate);

  static Future<List<dynamic>> fetchMeasurementCalculationSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
  }) async =>
      _fetchSheet("/site/$siteId/team/123/dpr-mechanical/abstract-sheet", fromDate, toDate);

  static Future<List<dynamic>> fetchSummarySheet({
    required String siteId,
    required String fromDate,
    required String toDate,
  }) async =>
      _fetchSheet("/site/$siteId/team/123/dpr-mechanical/summery-sheet", fromDate, toDate);

  static Future<List<dynamic>> fetchInvoiceSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
  }) async =>
      _fetchSheet("/site/$siteId/team/123/dpr-mechanical/invoice-sheet", fromDate, toDate);

  static Future<Uint8List> _fetchSheet(String path, String fromDate, String toDate) async {
    try {
      final response = await DioClient.dio.get(
        "$path",
        queryParameters: {"fromDate": fromDate, "toDate": toDate},
        options: Options(extra: {"withCredentials": true}),
      );

      printFormattedJson(response.data);

      if (response.statusCode == 200) {
        if (response.data is Map && response.data["data"] is String) {
          return base64Decode(response.data["data"]);
        } else {
          throw Exception("Invalid response format: expected {data: base64String}");
        }
      } else {
        throw Exception("Failed to fetch sheet. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("❌ Error fetching sheet: $e");
      print(stack);
      rethrow;
    }
  }


  // ----------------------------
  // Helper: Pretty-print JSON
  // ----------------------------
  static void printFormattedJson(dynamic data) {
    if (data == null) return;
    const encoder = JsonEncoder.withIndent('  ');
    try {
      if (data is List || data is Map) {
        print("📄 Response Data:\n${encoder.convert(data)}");
      } else {
        print("📄 Response Data: $data");
      }
    } catch (e) {
      print("⚠️ Error printing JSON: $e");
      print(data);
    }
  }
}
