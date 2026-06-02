import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../../core/api/dio.dart';

class ManpowerAPI {
  static final dio = DioClient.dio;

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> deleteManpower(String id) async {
    try {
      final res = await dio.delete("/manpower/$id");
      return {"success": true, "data": res.data, "statusCode": res.statusCode};
    } on DioException catch (e) {
      return _dioError("Delete Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  static Future<Map<String, dynamic>> bulkDeleteManpower(
    List<String> manpowerIds,
  ) async {
    if (manpowerIds.isEmpty) {
      return {"success": false, "message": "Manpower IDs list cannot be empty"};
    }
    try {
      final res = await dio.post(
        "/manpower/bulk-delete",
        data: {"ids": manpowerIds},
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      return {"success": true, "data": res.data, "statusCode": res.statusCode};
    } on DioException catch (e) {
      return _dioError("Bulk Delete Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ─────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────

  /// Fetch ALL manpower for a type (company-wide)
  static Future<Map<String, dynamic>> fetchManpower(String type) async {
    try {
      final res = await dio.get(
        "/manpower",
        queryParameters: {"type": type},
      );
      return {"success": true, "data": res.data};
    } on DioException catch (e, st) {
      debugPrint(
          "❌ fetchManpower DIO ERROR\n${e.requestOptions.uri}\n${e.response?.data}\n$st");
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
    } catch (e, st) {
      debugPrint("❌ fetchManpower UNKNOWN ERROR\n$e\n$st");
      return {
        "success": false,
        "data": null,
        "error": {"type": "Unknown", "message": e.toString()}
      };
    }
  }

  /// Fetch manpower assigned to a specific site
  /// Uses GET /api/v1/site/[siteId]/manpower?type=...
  static Future<Map<String, dynamic>> fetchManpowerBySite({
    required String siteId,
    required String type,
  }) async {
    try {
      final res = await dio.get(
        "/site/$siteId/manpower",
        queryParameters: {"type": type},
      );
      return {"success": true, "data": res.data};
    } on DioException catch (e) {
      return _dioError("Fetch By Site Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  static Future<Map<String, dynamic>> fetchManpowerById(String id) async {
    try {
      final res = await dio.get("/manpower/$id");
      return {"success": true, "data": res.data};
    } catch (e) {
      return {"success": false, "data": null, "error": e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // CREATE / UPDATE
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> postManpower(
    String type,
    dynamic data,
  ) async {
    try {
      final res = await dio.post(
        "/manpower",
        queryParameters: {"type": type},
        data: data,
      );
      return {"success": true, "data": res.data};
    } catch (e) {
      return {"success": false, "data": null, "error": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateManpower(
    String id,
    dynamic data,
  ) async {
    try {
      final res = await dio.put("/manpower/$id", data: data);
      return {"success": true, "data": res.data};
    } catch (e) {
      return {"success": false, "data": null, "error": e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // ✅ SITE MANAGEMENT  (NEW)
  // PUT /api/v1/manpower/[id]/sites
  // ─────────────────────────────────────────────

  /// Manage sites for a manpower: action = "add" | "remove" | "set"
  static Future<Map<String, dynamic>> manageManpowerSites({
    required String manpowerId,
    required String action, // "add" | "remove" | "set"
    required List<String> siteIds,
  }) async {
    try {
      final res = await dio.put(
        "/manpower/$manpowerId/sites",
        data: {"action": action, "siteIds": siteIds},
        options: Options(headers: {"Content-Type": "application/json"}),
      );
      return {"success": true, "data": res.data};
    } on DioException catch (e) {
      return _dioError("Manage Sites Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ─────────────────────────────────────────────
  // ✅ MARK LEFT  (FIXED endpoint)
  // Was: PUT /left-manpower/:id
  // Now: POST /manpower/:id/left
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> leftManpower(
    String id,
    dynamic data,
  ) async {
    try {
      final res = await dio.post("/manpower/$id/left", data: data);
      return {"success": true, "data": res.data};
    } on DioException catch (e) {
      return _dioError("Mark Left Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ─────────────────────────────────────────────
  // EXCEL / BULK
  // ─────────────────────────────────────────────
// ─────────────────────────────────────────────
// ADD THIS METHOD inside ManpowerAPI class
// lib/features/modules/all_Modules/Manpower Details/service/manpowerService.dart
// ─────────────────────────────────────────────

// ✅ STEP 1: Upload and get jobId  (replaces old uploadExcel call in _onUploadPressed)
// This already exists as flexibleUploadExcel — just pass siteId in queryParameters.
// Update the existing flexibleUploadExcel like this:

  static Future<Map<String, dynamic>> flexibleUploadExcelWithSite({
    required File file,
    required String type,
    String? siteId,
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
      final queryParams = {
        "type": mappedType,
        if (analyze) "analyze": true,
        if (siteId != null && siteId.isNotEmpty) "siteId": siteId,
      };
      final res = await dio.post(
        "/manpower/flexible-upload",
        queryParameters: queryParams,
        data: formData,
        options: Options(
          headers: {
            "Accept": "application/json",
            "Content-Type": "multipart/form-data"
          },
        ),
      );
      return {"success": true, "data": res.data, "statusCode": res.statusCode};
    } on DioException catch (e) {
      return _dioError("Flexible Upload Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

// ✅ STEP 2: Poll job status
// GET /api/v1/manpower/job-status/{jobId}
  static Future<Map<String, dynamic>> fetchJobStatus(String jobId) async {
    try {
      final res = await dio.get("/manpower/job-status/$jobId");
      return {"success": true, "data": res.data};
    } on DioException catch (e) {
      return _dioError("Job Status Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  static Future<Map<String, dynamic>> flexibleUploadExcel({
    required File file,
    required String type,
    bool analyze = false,
    String? siteId, // Added optional siteId parameter
  }) async {
    try {
      final mappedType = mapManpowerType(type);
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      // Build query parameters with siteId
      final queryParams = {
        "type": mappedType,
        if (analyze) "analyze": true,
        if (siteId != null) "siteId": siteId, // Add siteId if provided
      };

      final res = await dio.post(
        "/manpower/flexible-upload",
        queryParameters: queryParams,
        data: formData,
        options: Options(headers: {
          "Accept": "application/json",
          "Content-Type": "multipart/form-data"
        }),
      );
      return {"success": true, "data": res.data, "statusCode": res.statusCode};
    } on DioException catch (e) {
      return _dioError("Flexible Upload Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  static Future<Map<String, dynamic>> uploadExcel({
    required File file,
    required String type,
    String? siteId, // Added optional siteId parameter
  }) =>
      flexibleUploadExcel(
        file: file,
        type: type,
        analyze: false,
        siteId: siteId, // Pass siteId through
      );
  static Future<Map<String, dynamic>> analyzeExcel(
          {required File file, required String type}) =>
      flexibleUploadExcel(file: file, type: type, analyze: true);

  static Future<Map<String, dynamic>> uploadManpowerBulk(
    FormData formData,
    String type,
  ) async {
    try {
      final mappedType = mapManpowerType(type);
      final response = await DioClient.dio.post(
        '/manpower/bulk-upload',
        data: formData,
        queryParameters: {"type": mappedType},
        options: Options(headers: {'Accept': 'application/json'}),
      );
      return {
        'success': true,
        'data': response.data,
        'message': response.data['message'] ?? 'Upload successful',
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      return _dioError("Bulk Upload Error", e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ─────────────────────────────────────────────
  // DOWNLOAD / VIEW
  // ─────────────────────────────────────────────

  /// Download manpower sheet as excel or pdf
  /// GET /api/v1/manpower/view?format=excel|pdf
  static Future<Uint8List> downloadManpowerSheet({
    String format = 'excel',
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/manpower/view",
        queryParameters: {"format": format},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchManpowerView() async {
    try {
      final res = await dio.get("/manpower/view");
      return {"success": true, "data": res.data};
    } catch (e) {
      return {"success": false, "data": null, "error": e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // LEFT MANPOWER
  // ─────────────────────────────────────────────

  /// GET /api/v1/left-manpower
  static Future<Map<String, dynamic>> getLeftManpower({String? type}) async {
    try {
      final res = await dio.get(
        "/left-manpower",
        queryParameters: {
          if (type != null) "type": type,
        },
      );
      return {"success": true, "data": res.data};
    } catch (e) {
      return {"success": false, "data": null, "error": e.toString()};
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  static Map<String, dynamic> _dioError(String label, DioException e) {
    String msg = "Request failed";
    if (e.response?.data is Map) {
      msg = e.response?.data['message'] ?? e.response?.data['error'] ?? msg;
    } else if (e.response?.data is String) {
      msg = e.response!.data;
    } else if (e.message != null) {
      msg = e.message!;
    }
    return {
      "success": false,
      "error": label,
      "message": msg,
      "statusCode": e.response?.statusCode,
    };
  }

  static Map<String, dynamic> _unexpectedError(Object e) {
    return {
      "success": false,
      "error": "Unexpected Error",
      "message": e.toString()
    };
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
    case 'civil':
    case 'civil_work':
      return 'civil_work';
    case 'erection':
    case 'erection_work':
      return 'erection_work';
    case 'roofing':
    case 'roofing_work':
      return 'roofing_work';
    case 'fabrication':
    case 'fabrication_work':
      return 'fabrication_work';
    case 'structure':
    case 'structure_work':
      return 'structure_work';
    case 'peb':
    case 'peb_work':
      return 'peb_work';
    default:
      throw Exception(
        "Invalid manpower type: $rawType. Please select a valid service type.",
      );
  }
}

class ExcelUploadIssue {
  final int? row;
  final String message;
  ExcelUploadIssue({this.row, required this.message});

  @override
  String toString() => row == null ? message : "Row $row: $message";
}
