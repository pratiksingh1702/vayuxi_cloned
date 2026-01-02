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
        throw Exception(
          "Failed to fetch DPR work. Status: ${response.statusCode}",
        );
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
        throw Exception(
          "Failed to fetch DPR work by ID. Status: ${response.statusCode}",
        );
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
        throw Exception(
          "Failed to post DPR work. Status: ${response.statusCode}",
        );
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
        throw Exception(
          "Failed to update DPR work. Status: ${response.statusCode}",
        );
      }
    } catch (e, stack) {
      if (e is DioException) {
        print("❌ DIO ERROR");
        print("Type: ${e.type}");
        print("Message: ${e.message}");

        if (e.response != null) {
          print("Status Code: ${e.response?.statusCode}");
          print("Status Message: ${e.response?.statusMessage}");
          print("Response Headers: ${e.response?.headers}");
          print("Response Data:");
          printFormattedJson(e.response?.data);
        } else {
          print("No response received from server");
        }

        if (e.requestOptions != null) {
          print("Request URL: ${e.requestOptions.uri}");
          print("Request Method: ${e.requestOptions.method}");
          print("Request Headers: ${e.requestOptions.headers}");
          print("Request Data: ${e.requestOptions.data}");
        }
      } else {
        print("❌ UNKNOWN ERROR: $e");
      }

      print("STACK TRACE:");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 5. Update DPR Material Qty
  // ----------------------------
  static Future<void> updateDprMaterialQty({
    required Map<String, dynamic> data,
    required String mechanicalID,
    required String materialId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$mechanicalID/team/$materialId/dpr-mechanical/qty",
        data: data,
        options: Options(
          headers: {"Content-Type": "application/json"},
          extra: {"withCredentials": true},
        ),
      );

      printFormattedJson(response.data);

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to update DPR material qty. Status: ${response.statusCode}",
        );
      }
    } catch (e, stack) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        final url = e.requestOptions.uri.toString();
        final method = e.requestOptions.method;
        final data = e.response?.data;
        final msg = e.message;

        print("🔥 DPR MATERIAL QTY UPDATE FAILED");
        print("👉 URL: $url");
        print("👉 METHOD: $method");
        print("👉 STATUS: $status");
        print("👉 BACKEND RESPONSE: ${data ?? 'No response body'}");
        print("👉 DIO MESSAGE: $msg");
        print("👉 STACK:");
        print(stack);

        throw Exception(
          "DPR Qty Update failed — status $status — response: $data",
        );
      }

      print("❌ UNKNOWN ERROR: $e");
      print(stack);
      rethrow;
    }
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
        throw Exception(
          "Failed to fetch material. Status: ${response.statusCode}",
        );
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
        throw Exception(
          "Failed to post material. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("❌ Error posting material: $e");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> deleteMaterial({
    required FormData data,
    required String mechanicalId,
  }) async {
    try {
      final response = await DioClient.dio.delete(
        "/mechnical/$mechanicalId",
        data: data,
        options: Options(
          extra: {"withCredentials": true},
          validateStatus: (s) => true,
        ),
      );

      print("🗑 DELETE STATUS: ${response.statusCode}");
      print("🗑 DELETE RESPONSE: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }

      throw Exception("Delete failed: ${response.statusCode} ${response.data}");
    } on DioException catch (e) {
      print("❌ DELETE DIO ERROR");
      print("➡️ ${e.requestOptions.uri}");
      print("➡️ ${e.response?.statusCode}");
      print("➡️ ${e.response?.data}");
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
        throw Exception(
          "Failed to update material. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("❌ Error updating material: $e");
      rethrow;
    }
  }

  // ----------------------------
  // 6. Copy DPR Material
  // ----------------------------
  // In your DprApi class
  static Future<Map<String, dynamic>> copyDprMaterial({
    required String type,
    required String materialId,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/mechnical-copy/$materialId",
        queryParameters: {"type": type},
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200) {
        print("✅ DPR material copied successfully");
        printFormattedJson(response.data);
        return response.data;
      }

      // Non-200 but no DioException (rare, but possible)
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "Unexpected status code",
      );
    }

    // 🔴 Dio-specific errors (network / backend / timeout)
    on DioException catch (e, stack) {
      final status = e.response?.statusCode;
      final path = e.requestOptions.path;
      final method = e.requestOptions.method;

      print("❌ DPR COPY FAILED (DioException)");
      print("➡️ $method $path");
      print("📟 Status Code: $status");

      if (e.response?.data != null) {
        print("📦 Response Data:");
        printFormattedJson(e.response!.data);
      }

      print("🧨 Error Type: ${e.type}");
      print("📝 Message: ${e.message}");
      print("📌 Stack Trace:");
      print(stack);

      rethrow;
    }

    // 🔴 Any other unexpected error
    catch (e, stack) {
      print("❌ DPR COPY FAILED (Unknown Error)");
      print("📝 Error: $e");
      print("📌 Stack Trace:");
      print(stack);
      rethrow;
    }
  }

  // ----------------------------
  // 7. Sheet Handlers
  // ----------------------------
  static Future<Uint8List> fetchMeasurementSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
    required String format,
    required String workType, // 'mechanical' or 'insulation'
  }) => _fetchSheet(
    siteId,
    "measurement",
    fromDate,
    toDate,
    format,
    workType,
  );

  static Future<Uint8List> fetchMeasurementCalculationSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
    required String format,
    required String workType,
  }) => _fetchSheet(
    siteId,
    "abstract",
    fromDate,
    toDate,
    format,
    workType,
  );

  static Future<Uint8List> fetchSummarySheet({
    required String siteId,
    required String fromDate,
    required String toDate,
    required String format,
    required String workType,
  }) => _fetchSheet(
    siteId,
    "summary",
    fromDate,
    toDate,
    format,
    workType,
  );

  static Future<Uint8List> fetchInvoiceSheet({
    required String siteId,
    required String fromDate,
    required String toDate,
    required String format,
    required String workType,
  }) => _fetchSheet(
    siteId,
    "invoice",
    fromDate,
    toDate,
    format,
    workType,
  );

  static Future<Uint8List> _fetchSheet(
      String siteId,
      String sheetType,
      String fromDate,
      String toDate,
      String format,
      String workType,
      ) async {
    try {
      final String apiWorkType = _convertWorkTypeForApi(workType);
      final response = await DioClient.dioV2.get(
        "/site/$siteId/sheets/$sheetType",
        queryParameters: {
          "fromDate": fromDate,
          "toDate": toDate,
          "format": format,
          "workType": apiWorkType,
        },
        options: Options(extra: {"withCredentials": true}),
      );

      printFormattedJson(response.data);

      if (response.statusCode == 200) {
        if (response.data is Map && response.data["data"] is String) {
          return base64Decode(response.data["data"]);
        } else {
          throw Exception(
            "Invalid response format: expected {data: base64String}",
          );
        }
      } else {
        throw Exception(
          "Failed to fetch sheet. Status: ${response.statusCode}",
        );
      }
    } catch (e, stack) {
      print("❌ Error fetching sheet: $e");
      print(stack);
      rethrow;
    }
  }
  static String _convertWorkTypeForApi(String uiWorkType) {
    switch (uiWorkType) {
      case 'mechanical_work':
        return 'mechanical';
      case 'insulation_work':
        return 'insulation';
      default:
      // If it's already in API format, return as-is
      // This provides backward compatibility
        if (uiWorkType == 'mechanical' || uiWorkType == 'insulation') {
          return uiWorkType;
        }
        throw ArgumentError('Invalid workType: $uiWorkType. '
            'Expected: mechanical_work, insulation_work, mechanical, or insulation');
    }
  }
}

// ----------------------------
// Helper: Pretty-print JSON
// ----------------------------
void printFormattedJson(dynamic data) {
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

