// ============================================================
// manpower_upload_handler.dart
// Handles background upload for the manpower field-mapping flow.
//
// Metadata keys written by ManFieldMappingScreen._enqueueImport():
//   'type'     → String  (required) e.g. 'mechanical_work'
//   'siteId'   → String? (optional) site to assign employees to
//   'mappings' → String? (optional) JSON-encoded List<{csvColumn, modelField}>
//   'configId' → String? (optional) saved configuration ID (alternative to mappings)
//
// The handler calls POST /api/v1/manpower/field-mapping/import which is the
// new field-mapping API instead of the legacy /manpower/flexible-upload.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart' hide ProgressCallback;

import '../../../features/modules/all_Modules/Manpower Details/service/manpowerService.dart';
import '../../../../core/upload/handlers/upload_handler.dart';
import '../../../../core/upload/models/upload_job.dart';

class ManpowerUploadHandler implements UploadHandler {
  @override
  String get moduleId => 'manpower';

  @override
  Future<Map<String, dynamic>> execute({
    required UploadJob job,
    required ProgressCallback onProgress,
  }) async {
    // ── 1. Resolve file ────────────────────────────────────
    final file = File(job.filePath);
    if (!file.existsSync()) {
      throw Exception('File not found at path: ${job.filePath}');
    }

    // ── 2. Read metadata ───────────────────────────────────
    final type = job.metadata['type'] as String? ?? '';
    if (type.isEmpty) throw Exception('metadata.type is required');

    final mappedType = mapManpowerType(type); // validates + normalises type

    final siteId = job.metadata['siteId'] as String? ?? '';

    // mappings and configId are mutually exclusive;
    // mappings takes priority when both are present.
    final mappingsJson = job.metadata['mappings'] as String?;
    final configId = job.metadata['configId'] as String?;

    // ── 3. Build multipart body ────────────────────────────
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    // ── 4. Build query parameters ──────────────────────────
    final queryParams = <String, dynamic>{'type': mappedType};

    if (siteId.isNotEmpty) queryParams['siteId'] = siteId;

    if (mappingsJson != null && mappingsJson.isNotEmpty) {
      // Pass pre-serialised JSON string as-is — backend expects a JSON string
      // in the 'mappings' query param.
      queryParams['mappings'] = mappingsJson;
    } else if (configId != null && configId.isNotEmpty) {
      queryParams['configId'] = configId;
    }
    // If neither mappings nor configId are present the backend will return 400
    // (missing mappings). The screen always ensures at least one is set before
    // enqueueing, so this is a safety net only.

    // ── 5. POST to field-mapping import endpoint ───────────
    final dio = ManpowerAPI.dio;

    final res = await dio.post(
      '/manpower/field-mapping/import',
      queryParameters: queryParams,
      data: formData,
      options: Options(headers: {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      }),
      onSendProgress: (sent, total) {
        if (total <= 0) return;
        final progress = (sent / total).clamp(0.0, 1.0);
        onProgress(
          progress,
          'Uploading… ${(progress * 100).toStringAsFixed(0)}%',
        );
      },
    );

    // ── 6. Validate response ───────────────────────────────
    final statusCode = res.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      return {'success': true, 'data': res.data, 'statusCode': statusCode};
    }

    throw Exception(
      'Import failed with status $statusCode: ${res.data}',
    );
  }
}