import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../../core/api/dio.dart';

import '../model/dpr_model_insu.dart';



class InsulationDprApi {
  // ----------------------------
  // 1. Fetch Insulation DPR List
  // ----------------------------
  static Future<List<InsulationDprModel>> fetchInsulationDprList({
    required String siteId,
    required String teamId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team/$teamId/dpr-insulation",
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data;

        if (data is List) {
          return data
              .map((e) => InsulationDprModel.fromJson(e))
              .toList();
        } else {
          throw Exception("Expected list but got ${data.runtimeType}");
        }
      }

      throw Exception(
        "Unexpected status code: ${response.statusCode}",
      );
    } catch (e, stack) {
      print("❌ FETCH INSULATION DPR LIST FAILED");
      print("Error: $e");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
// 10. Bulk Delete Materials
// ----------------------------
  static Future<void> bulkDeleteMaterials({
    required List<String> ids,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/insulation-dpr-setup/materials/bulk-delete",
        data: {"ids": ids},
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw Exception("Bulk delete failed");
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?["message"] ?? "Bulk delete failed",
      );
    }
  }


  // ----------------------------
  // 2. Fetch Insulation DPR By ID
  // ----------------------------
  static Future<InsulationDprModel> fetchInsulationDprById({
    required String insulationId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/insulation/$insulationId",
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200) {
        return InsulationDprModel.fromJson(response.data);
      }

      throw Exception("Failed to fetch insulation DPR");
    } catch (e, stack) {
      print("❌ FETCH INSULATION DPR FAILED");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 3. Create Insulation DPR
  // ----------------------------
  static Future<InsulationDprModel> createInsulationDpr({
    required String siteId,
    required String teamId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/team/$teamId/dpr-insulation",
        data: data,
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InsulationDprModel.fromJson(response.data);
      }

      throw Exception("Failed to create insulation DPR");
    } catch (e, stack) {
      print("❌ CREATE INSULATION DPR FAILED");
      print(stack);
      rethrow;
    }
  }
  static Future<InsulationDprModel> updateInsulationDpr({
    required String dprId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/insulation-update-dpr/$dprId",
        data: data,
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return InsulationDprModel.fromJson(response.data);
      }

      throw Exception(
        "Unexpected status code: ${response.statusCode}",
      );
    } on DioException catch (e, stack) {
      final statusCode = e.response?.statusCode;
      final backendMessage =
          e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              e.message;

      debugPrint("❌ UPDATE INSULATION DPR FAILED");
      debugPrint("➡️ DPR ID: $dprId");
      debugPrint("➡️ Status Code: $statusCode");
      debugPrint("➡️ Backend Message: $backendMessage");
      debugPrintStack(stackTrace: stack);

      throw Exception(
        backendMessage ?? "Failed to update insulation DPR",
      );
    } catch (e, stack) {
      debugPrint("❌ UPDATE INSULATION DPR FAILED (UNKNOWN)");
      debugPrint("➡️ DPR ID: $dprId");
      debugPrint("➡️ Error: $e");
      debugPrintStack(stackTrace: stack);

      throw Exception(
        "Unexpected error while updating insulation DPR",
      );
    }
  }


  // ----------------------------
  // 4. Update Insulation DPR Header
  // ----------------------------
  static Future<void> updateInsulationHeader({
    required String insulationId,
    required Map<String, dynamic> data,
  }) async {
    final response = await DioClient.dio.put(
      "/dpr-update/$insulationId",
      data: data,
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update insulation DPR header");
    }
  }

  // ----------------------------
  // 5. Add Insulation Material
  // ----------------------------
  static Future<Map<String, dynamic>> addInsulationMaterial({
    required String insulationId,
    required FormData data,
    required String designation, // piping | equipment
  }) async {
    final response = await DioClient.dio.post(
      "/dpr-insulation-update/$insulationId",
      data: data,
      queryParameters: {"designation": designation},
      options: Options(
        headers: {"Content-Type": "multipart/form-data"},
        extra: {"withCredentials": true},
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    }

    throw Exception("Failed to add insulation material");
  }

  // ----------------------------
  // 6. Update Insulation Material
  // ----------------------------
  static Future<Map<String, dynamic>> updateInsulationMaterial({
    required String insulationId,
    required FormData data,
  }) async {
    final response = await DioClient.dio.put(
      "/insulation/$insulationId",
      data: data,
      options: Options(
        headers: {"Content-Type": "multipart/form-data"},
        extra: {"withCredentials": true},
      ),
    );

    if (response.statusCode == 200) {
      return response.data;
    }

    throw Exception("Failed to update insulation material");
  }

  // ----------------------------
  // 7. Delete Insulation Material
  // ----------------------------
  static Future<void> deleteInsulationMaterial({
    required String materialId,
  }) async {
    try {
      final response = await DioClient.dio.delete(
        "/insulation-dpr-setup/materials/$materialId",
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw Exception("Failed to delete insulation material");
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?["message"] ?? "Delete failed",
      );
    }
  }
  // ----------------------------
  // 8. Copy Insulation Material
  // ----------------------------
  static Future<Map<String, dynamic>> copyInsulationMaterial({
    required String materialId,
  }) async {
    final response = await DioClient.dio.post(
      "/insulation-dpr-setup/materials/copy/$materialId",
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      return response.data;
    }


    throw Exception("Failed to copy insulation material");
  }

  // ----------------------------
  // 9. Sheets (Insulation Only)
  // ----------------------------
  static Future<Uint8List> fetchInsulationSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
    required String format,
    required String sheetType, // measurement | abstract | summary | invoice
  }) async {
    final response = await DioClient.dioV2.get(
      "/site/$siteId/sheets/$sheetType",
      queryParameters: {
        "fromDate": fromDate,
        "toDate": toDate,
        "format": format,
        "workType": "insulation",
      },
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode == 200 &&
        response.data is Map &&
        response.data["data"] is String) {
      return base64Decode(response.data["data"]);
    }

    throw Exception("Failed to fetch insulation sheet");
  }
}
