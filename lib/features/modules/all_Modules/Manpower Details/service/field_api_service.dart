// ============================================================
// field_mapping_api.dart
// API layer for the Manpower Field Mapping feature.
// All methods return Map<String, dynamic> with 'success' flag
// so callers can pattern-match consistently.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../core/api/dio.dart';
import '../model/field_mapping_model.dart';

class FieldMappingAPI {
  static final _dio = DioClient.dio;

  // ──────────────────────────────────────────────────────────
  // 1. PREVIEW
  // POST /api/v1/manpower/field-mapping/preview
  // ──────────────────────────────────────────────────────────

  /// Upload a file and receive suggested mappings + preview rows.
  static Future<Map<String, dynamic>> previewFile({
    required File file,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final res = await _dio.post(
        '/manpower/field-mapping/preview',
        data: formData,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        }),
      );

      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _dioError('Preview Error', e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 2. SAVE CONFIGURATION
  // POST /api/v1/manpower/field-mapping/save
  // ──────────────────────────────────────────────────────────

  /// Persist a named mapping configuration for future reuse.
  static Future<Map<String, dynamic>> saveConfiguration({
    required String configurationName,
    required String type,
    required List<FieldMapping> mappings,
    bool isDefault = false,
  }) async {
    try {
      final res = await _dio.post(
        '/manpower/field-mapping/save',
        data: {
          'configurationName': configurationName,
          'type': type,
          'mappings': mappings.map((m) => m.toJson()).toList(),
          'isDefault': isDefault,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _dioError('Save Config Error', e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 3. GET CONFIGURATIONS
  // GET /api/v1/manpower/field-mapping/save?type=...
  // ──────────────────────────────────────────────────────────

  /// Fetch all saved configurations for a given manpower type.
  static Future<Map<String, dynamic>> getConfigurations({
    required String type,
  }) async {
    try {
      final res = await _dio.get(
        '/manpower/field-mapping/save',
        queryParameters: {'type': type},
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _dioError('Get Configs Error', e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 4. DELETE CONFIGURATION
  // DELETE /api/v1/manpower/field-mapping/save?configId=...
  // ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> deleteConfiguration({
    required String configId,
  }) async {
    try {
      final res = await _dio.delete(
        '/manpower/field-mapping/save',
        queryParameters: {'configId': configId},
      );
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _dioError('Delete Config Error', e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ──────────────────────────────────────────────────────────
  // 5. IMPORT WITH MAPPING
  // POST /api/v1/manpower/field-mapping/import
  // ──────────────────────────────────────────────────────────

  /// Import manpower data with either custom [mappings] or a [configId].
  /// [siteId] is optional — assigns all imported employees to that site.
  static Future<Map<String, dynamic>> importWithMapping({
    required File file,
    required String type,
    List<FieldMapping>? mappings,
    String? configId,
    String? siteId,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final queryParams = <String, dynamic>{'type': type};
      if (siteId != null && siteId.isNotEmpty) queryParams['siteId'] = siteId;
      if (configId != null && configId.isNotEmpty) {
        queryParams['configId'] = configId;
      } else if (mappings != null && mappings.isNotEmpty) {
        // Encode mappings as JSON string in query param
        queryParams['mappings'] =
            jsonEncode(mappings.map((m) => m.toJson()).toList());
      }

      debugPrint('📤 importWithMapping → queryParams: $queryParams');

      final res = await _dio.post(
        '/manpower/field-mapping/import',
        queryParameters: queryParams,
        data: formData,
        options: Options(headers: {
          'Accept': 'application/json',
          'Content-Type': 'multipart/form-data',
        }),
      );

      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _dioError('Import Error', e);
    } catch (e) {
      return _unexpectedError(e);
    }
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────

  static Map<String, dynamic> _dioError(String label, DioException e) {
    String msg = 'Request failed';
    if (e.response?.data is Map) {
      msg = (e.response?.data['message'] ??
              e.response?.data['error'] ??
              msg)
          .toString();
    } else if (e.response?.data is String) {
      msg = e.response!.data as String;
    } else if (e.message != null) {
      msg = e.message!;
    }
    debugPrint('❌ [$label] ${e.response?.statusCode} → $msg');
    return {
      'success': false,
      'error': label,
      'message': msg,
      'statusCode': e.response?.statusCode,
    };
  }

  static Map<String, dynamic> _unexpectedError(Object e) {
    debugPrint('❌ Unexpected error: $e');
    return {
      'success': false,
      'error': 'Unexpected Error',
      'message': e.toString(),
    };
  }
}