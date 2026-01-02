import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../core/api/dio.dart';

class ManpowerAPI {
  static final dio = DioClient.dio;
  /// Delete manpower by ID
  static Future<Map<String, dynamic>> deleteManpower(String id) async {
    try {
      final res = await dio.delete("/manpower/$id");

      return {
        "success": true,
        "data": res.data,
        "statusCode": res.statusCode,
      };
    } on DioException catch (e) {
      String errorMessage = "Delete failed";

      if (e.response != null) {
        if (e.response!.data is Map) {
          errorMessage =
              e.response!.data['message'] ??
                  e.response!.data['error'] ??
                  errorMessage;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      return {
        "success": false,
        "error": "Delete Error",
        "message": errorMessage,
        "statusCode": e.response?.statusCode,
      };
    } catch (e) {
      return {
        "success": false,
        "error": "Unexpected Error",
        "message": e.toString(),
      };
    }
  }


  /// Fetch manpower list by type
  static Future<Map<String, dynamic>> fetchManpower(String type) async {
    try {
      final res = await dio.get(
        "/manpower",
        queryParameters: {"type": type},
      );

      return {
        "success": true,
        "data": res.data,
      };
    } on DioException catch (e, stackTrace) {
      // 🔥 FULL ERROR LOG
      debugPrint("❌ DIO ERROR");
      debugPrint("➡️ URL: ${e.requestOptions.uri}");
      debugPrint("➡️ Method: ${e.requestOptions.method}");
      debugPrint("➡️ Query: ${e.requestOptions.queryParameters}");
      debugPrint("➡️ Status Code: ${e.response?.statusCode}");
      debugPrint("➡️ Response Data: ${e.response?.data}");
      debugPrint("➡️ Headers: ${e.response?.headers}");
      debugPrint("➡️ Error Type: ${e.type}");
      debugPrint("➡️ Message: ${e.message}");
      debugPrint("➡️ StackTrace:\n$stackTrace");

      return {
        "success": false,
        "data": null,
        "error": {
          "type": e.type.toString(),
          "statusCode": e.response?.statusCode,
          "message": e.message,
          "response": e.response?.data,
          "path": e.requestOptions.path,
        },
      };
    } catch (e, stackTrace) {
      // 🔥 NON-DIO ERROR
      debugPrint("❌ UNKNOWN ERROR");
      debugPrint("➡️ Error: $e");
      debugPrint("➡️ StackTrace:\n$stackTrace");

      return {
        "success": false,
        "data": null,
        "error": {
          "type": "Unknown",
          "message": e.toString(),
        },
      };
    }
  }

  /// Create manpower
  static Future<Map<String, dynamic>> postManpower(
      String type, dynamic data) async {
    try {
      final res = await dio.post(
        "/manpower",
        queryParameters: {"type": type},
        data: data,
      );
      return {
        "success": true,
        "data": res.data,
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }

  /// Fetch manpower by ID
  static Future<Map<String, dynamic>> fetchManpowerById(String id) async {
    try {
      final res = await dio.get("/manpower/$id");
      return {
        "success": true,
        "data": res.data,
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }

  /// Update manpower
  static Future<Map<String, dynamic>> updateManpower(
      String id, dynamic data) async {
    try {
      final res = await dio.put("/manpower/$id", data: data);
      return {
        "success": true,
        "data": res.data,
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }
  static Future<Map<String, dynamic>> uploadManpowerBulk(FormData formData) async {
    try {
      print('📤 Uploading manpower file...');
      print('📊 FormData fields: ${formData.fields.length}');
      print('📁 FormData files: ${formData.files.length}');
      print('📦 FormData: ${formData.files}');


      final response = await DioClient.dio.post(
        '/manpower/bulk-upload', // Make sure the endpoint is correct
        data: formData,
        options: Options(
          headers: {

            'Accept': 'application/json',
          },
        ),
      );

      print('✅ Upload successful: ${response.statusCode}');
      print('📦 Response: ${response.data}');

      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Upload successful',
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ Message: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status code: ${e.response?.statusCode}');
      print('❌ Headers: ${e.response?.headers}');

      String errorMessage = 'Upload failed';

      if (e.response != null) {
        if (e.response!.data != null) {
          try {
            // Try to parse error message from response
            if (e.response!.data is Map) {
              errorMessage = e.response!.data['message'] ??
                  e.response!.data['error'] ??
                  'Upload failed';
            } else if (e.response!.data is String) {
              errorMessage = e.response!.data;
            }
          } catch (parseError) {
            errorMessage = 'Server error: ${e.response!.statusCode}';
          }
        } else {
          errorMessage = 'Server error: ${e.response!.statusCode}';
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      return {
        'success': false,
        'error': 'Upload Error',
        'message': errorMessage,
        'statusCode': e.response?.statusCode,
      };
    } catch (e, stack) {
      print('❌ Unexpected error: $e');
      print('❌ Stack trace: $stack');
      return {
        'success': false,
        'error': 'Unexpected Error',
        'message': e.toString()
      };
    }
  }
  /// Mark manpower as left
  static Future<Map<String, dynamic>> leftManpower(
      String id, dynamic data) async {
    try {
      final res = await dio.put("/left-manpower/$id", data: data);
      return {
        "success": true,
        "data": res.data,
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }

  /// Get all left manpower
  static Future<Map<String, dynamic>> getLeftManpower() async {
    try {
      final res = await dio.put("/left-manpower");
      return {
        "success": true,
        "data": res.data,
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }

  /// Fetch manpower view
  static Future<Map<String, dynamic>> fetchManpowerView() async {
    try {
      final res = await dio.get("/manpower/view");
      return {
        "success": true,
        "data": res.data,
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": e.toString(),
      };
    }
  }
}
