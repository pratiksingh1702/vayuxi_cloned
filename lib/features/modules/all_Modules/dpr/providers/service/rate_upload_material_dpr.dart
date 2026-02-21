import 'package:dio/dio.dart';
import '../../../../../../core/api/dio.dart';
import '../../models/rate_file_models.dart';

class RateUploadApi {
  static Future<RateFileAnalysis> fetchRateFileAnalysis({
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/dpr-setup/rate-upload",
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to fetch rate upload. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'FETCH RATE UPLOAD');
      rethrow;
    }
  }
  /// ----------------------------
  /// Reject Rate File Materials
  /// ----------------------------
  static Future<RateFileAnalysis> rejectMaterials({
    required String rateUploadId,
    required List<String> materialIds,
    required String rejectionReason,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/dpr-setup/rate-upload/$rateUploadId/materials/reject",
        data: {
          "materialIds": materialIds,
          "rejectionReason": rejectionReason,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to reject materials. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'REJECT MATERIALS');
      rethrow;
    }
  }


  /// ----------------------------
  /// Approve Rate File Materials
  /// ----------------------------
  static Future<RateFileAnalysis> approveMaterials({
    required String rateUploadId,
    required List<String> materialIds,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/dpr-setup/rate-upload/$rateUploadId/materials/approve",
        data: {
          "materialIds": materialIds,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to approve materials. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'APPROVE MATERIALS');
      rethrow;
    }
  }

  /// ----------------------------
  /// Shared Dio error logger
  /// ----------------------------
  static void _logDioError(DioException e, String tag) {
    print("❌ RATE UPLOAD API ERROR [$tag]");
    print("➡️ URL: ${e.requestOptions.uri}");
    print("➡️ METHOD: ${e.requestOptions.method}");
    print("➡️ STATUS: ${e.response?.statusCode}");
    if (e.response?.data != null) {
      print("📦 RESPONSE:");
      print(e.response?.data);
    }
    print("🧨 MESSAGE: ${e.message}");
  }
  // --------------------------------------------------
  // COPY LINE ITEM
  // --------------------------------------------------
  static Future<RateFileAnalysis> copyLineItem({
    required String rateUploadId,
    required String lineItemId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/dpr-setup/rate-upload/$rateUploadId/line-item/$lineItemId/copy",
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RateFileAnalysis.fromJson(response.data['data']);
      } {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to copy line item. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'COPY LINE ITEM');
      rethrow;
    }
  }

  // --------------------------------------------------
  // DELETE LINE ITEM
  // --------------------------------------------------
  static Future<RateFileAnalysis> deleteLineItem({
    required String rateUploadId,
    required String lineItemId,
  }) async {
    try {
      final response = await DioClient.dio.delete(
        "/dpr-setup/rate-upload/$rateUploadId/line-item/$lineItemId",
        options: Options(extra: {"withCredentials": true}),
      );

      if (response.statusCode == 200) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to delete line item. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'DELETE LINE ITEM');
      rethrow;
    }
  }

  // --------------------------------------------------
  // UPDATE (EDIT) LINE ITEM
  // --------------------------------------------------

  static Future<RateFileAnalysis> addLineItem({
    required String rateUploadId,
    required FormData data,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/dpr-setup/rate-upload/$rateUploadId/line-item",
        data: data,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception("Failed to add line item. Status: ${response.statusCode}");
    } on DioException catch (e) {
      _logDioError(e, "ADD LINE ITEM");
      rethrow;
    }
  }
// --------------------------------------------------
// BULK DELETE LINE ITEMS
// --------------------------------------------------
  static Future<RateFileAnalysis> bulkDeleteLineItems({
    required String rateUploadId,
    required List<String> materialIds,
  }) async {
    try {
      final response = await DioClient.dio.delete(
        "/dpr-setup/rate-upload/$rateUploadId/line-items/bulk-delete",
        data: {
          "materialIds": materialIds,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to bulk delete line items. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'BULK DELETE LINE ITEMS');
      rethrow;
    }
  }

  
  static Future<RateFileAnalysis> updateLineItem({
    required String rateUploadId,
    required String lineItemId,
    required FormData data,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/dpr-setup/rate-upload/$rateUploadId/line-item/$lineItemId",
        data: data,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"withCredentials": true},
        ),
      );

      if (response.statusCode == 200) {
        return RateFileAnalysis.fromJson(response.data['data']);
      }

      throw Exception(
        "Failed to update line item. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, 'UPDATE LINE ITEM');
      rethrow;
    }
  }
  // --------------------------------------------------
  // CREATE DPR (MECHANICAL V2)
  // --------------------------------------------------
  static Future<Response> createDprMechanicalV2({
    required String siteId,
    required String teamId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/team/$teamId/dpr-mechanical-v2/dpr-mechanical-v2",
        data: data,
        options: Options(
          headers: {"Content-Type": "application/json"},
          extra: {"withCredentials": true},
        ),
      );

      // backend can return 200 or 201 for successful create
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      }

      throw Exception(
        "Failed to create DPR. Status: ${response.statusCode}",
      );
    } on DioException catch (e) {
      _logDioError(e, "CREATE DPR MECHANICAL V2");
      rethrow;
    }
  }


}
