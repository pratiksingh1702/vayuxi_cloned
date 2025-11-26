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