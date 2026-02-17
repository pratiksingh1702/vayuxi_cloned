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
  static Future<Map<String, dynamic>> bulkDeleteManpower(
      List<String> manpowerIds,
      ) async {
    if (manpowerIds.isEmpty) {
      return {
        "success": false,
        "message": "Manpower IDs list cannot be empty",
      };
    }

    try {
      final res = await dio.post(
        "/manpower/bulk-delete",
        data: {
          "ids": manpowerIds,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );

      return {
        "success": true,
        "data": res.data,
        "statusCode": res.statusCode,
      };
    } on DioException catch (e) {
      String errorMessage = "Bulk delete failed";

      if (e.response?.data is Map) {
        errorMessage =
            e.response?.data['message'] ??
                e.response?.data['error'] ??
                errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data;
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      return {
        "success": false,
        "error": "Bulk Delete Error",
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
  /// Upload Excel via flexible-upload API
  static Future<Map<String, dynamic>> flexibleUploadExcel({
    required File file,
    required String type,
    bool analyze = false,
  }) async {
    try {
      final mappedType = mapManpowerType(type);

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      debugPrint("📤 Uploading excel using flexible-upload...");
      debugPrint("📌 Type: $mappedType | Analyze: $analyze");
      debugPrint("📁 File: ${file.path}");

      final res = await dio.post(
        "/manpower/flexible-upload",
        queryParameters: {
          "type": mappedType,
          if (analyze) "analyze": true,
        },
        data: formData,
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "multipart/form-data",
          },
        ),
      );

      debugPrint("✅ flexible-upload success: ${res.statusCode}");
      debugPrint("📦 Response: ${res.data}");

      return {
        "success": true,
        "data": res.data,
        "statusCode": res.statusCode,
      };
    } on DioException catch (e, stackTrace) {
      debugPrint("❌ flexible-upload DIO ERROR");
      debugPrint("➡️ URL: ${e.requestOptions.uri}");
      debugPrint("➡️ Method: ${e.requestOptions.method}");
      debugPrint("➡️ Query: ${e.requestOptions.queryParameters}");
      debugPrint("➡️ Status Code: ${e.response?.statusCode}");
      debugPrint("➡️ Response Data: ${e.response?.data}");
      debugPrint("➡️ Message: ${e.message}");
      debugPrint("➡️ StackTrace:\n$stackTrace");

      String errorMessage = "Upload failed";

      if (e.response?.data is Map) {
        errorMessage =
            e.response?.data['message'] ??
                e.response?.data['error'] ??
                errorMessage;
      } else if (e.response?.data is String) {
        errorMessage = e.response!.data;
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      return {
        "success": false,
        "error": "Flexible Upload Error",
        "message": errorMessage,
        "statusCode": e.response?.statusCode,
        "data": e.response?.data,
      };
    } catch (e, stackTrace) {
      debugPrint("❌ flexible-upload UNKNOWN ERROR: $e");
      debugPrint("➡️ StackTrace:\n$stackTrace");

      return {
        "success": false,
        "error": "Unexpected Error",
        "message": e.toString(),
      };
    }
  }

  /// Shortcut: Upload only
  static Future<Map<String, dynamic>> uploadExcel({
    required File file,
    required String type,
  }) {
    return flexibleUploadExcel(file: file, type: type, analyze: false);
  }

  /// Shortcut: Upload + Analyze
  static Future<Map<String, dynamic>> analyzeExcel({
    required File file,
    required String type,
  }) {
    return flexibleUploadExcel(file: file, type: type, analyze: true);
  }

  static Future<Map<String, dynamic>> uploadManpowerBulk(FormData formData,String type) async {
    try {
      print('📤 Uploading manpower file...');
      print('📊 FormData fields: ${formData.fields.length}');
      print('📁 FormData files: ${formData.files.length}');
      print('📦 FormData: ${formData.files}');
      final mappedType = mapManpowerType(type);

      print('📤 Uploading manpower file...');
      print('📌 Final type sent: $mappedType');



      final response = await DioClient.dio.post(
        '/manpower/bulk-upload', // Make sure the endpoint is correct
        data: formData,
        queryParameters: {"type": mappedType},
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

String mapManpowerType(String rawType) {
  switch (rawType) {
    case 'mechanical':
    case 'mechanical_work':
      return 'mechanical_work';

    case 'insulation':
    case 'insulation_work':
      return 'insulation_work';

    default:
      throw Exception(
        "Invalid manpower type: $rawType. Allowed: mechanical_work, insulation_work",
      );
  }
}

class ExcelUploadIssue {
  final int? row;
  final String message;

  ExcelUploadIssue({this.row, required this.message});

  @override
  String toString() {
    if (row == null) return message;
    return "Row $row: $message";
  }
}

