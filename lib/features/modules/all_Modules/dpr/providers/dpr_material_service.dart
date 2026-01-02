// lib/services/dpr_material_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../../core/api/dio.dart';

class DprMaterialService {
  // Fetch material by ID
  static Future<Map<String, dynamic>> fetchMaterialById({
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
  static Future<Map<String, dynamic>> postMaterial({
    required FormData data,
    required String mechanicalId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/mechnical/$mechanicalId",
        data: data,
        options: Options(
          extra: {"withCredentials": true},
          validateStatus: (status) => true, // 👈 DON'T auto-throw
        ),
      );

      print("✅ RESPONSE STATUS: ${response.statusCode}");
      print("📦 RESPONSE DATA: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }

      // Backend responded but with error
      throw Exception(
        "Server Error ${response.statusCode}: ${response.data}",
      );
    } on DioException catch (e) {
      // 🔥 THIS is where real debugging happens
      print("❌ DIO ERROR");

      print("➡️ URL: ${e.requestOptions.uri}");
      print("➡️ METHOD: ${e.requestOptions.method}");

      if (e.response != null) {
        print("🚨 STATUS CODE: ${e.response?.statusCode}");
        print("🚨 RESPONSE DATA: ${e.response?.data}");
        print("🚨 HEADERS: ${e.response?.headers}");
      } else {
        print("⚠️ NO RESPONSE FROM SERVER");
      }

      print("📛 ERROR TYPE: ${e.type}");
      print("📛 ERROR MESSAGE: ${e.message}");

      rethrow;
    } catch (e, stack) {
      // Non-Dio error (logic, parsing, etc.)
      print("❌ UNEXPECTED ERROR: $e");
      print("📍 STACK TRACE:\n$stack");
      rethrow;
    }
  }


  // Update material
  static Future<Map<String, dynamic>> updateMaterial({
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

  // Fetch UOM rates
  static Future<List<dynamic>> fetchRates() async {
    try {
      final response = await DioClient.dio.get(
        "/rates", // Adjust endpoint as needed
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception("Failed to fetch rates. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching rates: $e");
      rethrow;
    }
  }
}