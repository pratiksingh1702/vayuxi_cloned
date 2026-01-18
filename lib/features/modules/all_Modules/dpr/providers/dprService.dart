import 'dart:convert';
import 'dart:io';
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

    required String mechanicalId,
    required String materialId,
  }) async {
    try {
      final response = await DioClient.dio.delete(
        "/mechnical/$mechanicalId",
        data: FormData.fromMap({
          "_id": materialId,
        }),
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
        options: Options(
          extra: {"withCredentials": true},
          validateStatus: (status) => status != null,
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      // 🔴 Backend responded but with error status
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "Update failed with status ${response.statusCode}",
      );
    }

    // 🔴 Dio-specific errors (THIS IS WHAT YOU WANT)
    on DioException catch (e, stack) {
      final status = e.response?.statusCode;
      final path = e.requestOptions.path;
      final method = e.requestOptions.method;
      final responseData = e.response?.data;

      print("❌ UPDATE MATERIAL FAILED");
      print("➡️ REQUEST: $method $path");
      print("📟 STATUS CODE: $status");

      if (responseData != null) {
        print("📦 BACKEND RESPONSE:");
        try {
          printFormattedJson(responseData);
        } catch (_) {
          print(responseData);
        }
      } else {
        print("📦 NO RESPONSE BODY");
      }

      print("🧨 DIO ERROR TYPE: ${e.type}");
      print("📝 MESSAGE: ${e.message}");

      print("📌 STACK TRACE:");
      print(stack);

      rethrow;
    }

    // 🔴 Any non-Dio error (logic, parsing, etc.)
    catch (e, stack) {
      print("❌ UPDATE MATERIAL FAILED (UNKNOWN ERROR)");
      print("📝 ERROR: $e");
      print("📌 STACK TRACE:");
      print(stack);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addMechanicalMaterial({
    required String dprId,
    required String materialName,
    required String uom,
    File? file,
  }) async {
    try {
      final formData = FormData.fromMap({
        "materialName": materialName,
        "uom": uom,
        if (file != null)
          "file": await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
      });

      final response = await DioClient.dio.post(
        "/mechnical/$dprId",
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
            "Accept": "application/json",
          },
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Mechanical material created successfully");
        printFormattedJson(response.data);
        return {
          "success": true,
          "data": response.data,
          "statusCode": response.statusCode,
        };
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "Unexpected status code ${response.statusCode}",
      );
    }

    // Dio-level errors
    on DioException catch (e, stack) {
      print("❌ MECHANICAL CREATE FAILED");
      print("➡️ ${e.requestOptions.method} ${e.requestOptions.path}");
      print("📟 Status: ${e.response?.statusCode}");

      if (e.response?.data != null) {
        print("📦 Response:");
        printFormattedJson(e.response!.data);
      }

      print("🧨 Dio Error Type: ${e.type}");
      print("📝 Message: ${e.message}");
      print(stack);

      rethrow;
    }

    // Anything else
    catch (e, stack) {
      print("❌ MECHANICAL CREATE FAILED (Unknown)");
      print("📝 Error: $e");
      print(stack);
      rethrow;
    }
  }


  // ----------------------------
  // 6. Copy DPR Material
  // ----------------------------
  // In your DprApi class
  static Future<Map<String, dynamic>> copyDprMaterial({
    required String dprId,
    required String matId,

  }) async {
    try {
      final response = await DioClient.dio.put(
        "/site/$dprId/team/$matId/dpr-mechanical/copy",

        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
            "Accept": "application/json",
          },
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200) {
        print("✅ DPR mechanical copied successfully");
        printFormattedJson(response.data);
        return response.data;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: "Unexpected status code ${response.statusCode}",
      );
    }

    // Dio-level errors
    on DioException catch (e, stack) {
      print("❌ DPR MECHANICAL COPY FAILED");
      print("➡️ ${e.requestOptions.method} ${e.requestOptions.path}");
      print("📟 Status: ${e.response?.statusCode}");

      if (e.response?.data != null) {
        print("📦 Response:");
        printFormattedJson(e.response!.data);
      }

      print("🧨 Dio Error Type: ${e.type}");
      print("📝 Message: ${e.message}");
      print(stack);

      rethrow;
    }

    // Anything else
    catch (e, stack) {
      print("❌ DPR MECHANICAL COPY FAILED (Unknown)");
      print("📝 Error: $e");
      print(stack);
      rethrow;
    }
  }
  static Future<List<DprModel>> fetchInsulationDprWork({
    required String siteId,
    required String teamId,
  }) async {
    final response = await DioClient.dio.get(
      "/site/$siteId/team/$teamId/dpr-insulation",
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode == 200) {
      return (response.data as List)
          .map((e) => DprModel.fromJson(e))
          .toList();
    }
    throw Exception("Failed to fetch insulation DPR list");
  }
  static Future<DprModel> fetchInsulationDprById({
    required String insulationId,
  }) async {
    final response = await DioClient.dio.get(
      "/insulation/$insulationId",
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode == 200) {
      return DprModel.fromJson(response.data);
    }
    throw Exception("Failed to fetch insulation DPR by ID");
  }
  static Future<DprModel> postInsulationDpr({
    required Map<String, dynamic> data,
    required String siteId,
    required String teamId,
  }) async {
    final response = await DioClient.dio.post(
      "/site/$siteId/team/$teamId/dpr-insulation",
      data: data,
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DprModel.fromJson(response.data);
    }
    throw Exception("Failed to create insulation DPR");
  }
  static Future<void> updateInsulationDprHeader({
    required Map<String, dynamic> data,
    required String insulationId,
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
  static Future<Map<String, dynamic>> updateInsulationMaterial({
    required FormData data,
    required String insulationId,
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
  static Future<Map<String, dynamic>> addInsulationMaterial({
    required FormData data,
    required String insulationId,
    required String designation, // piping / equipment
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
  static Future<Map<String, dynamic>> copyInsulationMaterial({
    required String insulationId,
    required String materialId,
  }) async {
    final response = await DioClient.dio.post(
      "/site/$insulationId/team/$materialId/dpr-insulation/copy",
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode == 200) {
      return response.data;
    }
    throw Exception("Failed to copy insulation material");
  }
  static Future<void> deleteInsulationMaterial({
    required String insulationId,
    required String materialId,
  }) async {
    final response = await DioClient.dio.delete(
      "/dpr-insulation-update/$insulationId/item/$materialId",
      options: Options(extra: {"withCredentials": true}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete insulation material");
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

