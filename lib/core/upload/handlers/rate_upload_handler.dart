import 'dart:io';
import 'package:dio/dio.dart' hide ProgressCallback;
import '../../../features/modules/all_Modules/rate/data/rateApi.dart';
import '../models/upload_job.dart';
import 'upload_handler.dart';

class RateUploadHandler implements UploadHandler {
  @override
  String get moduleId => 'rate';

  @override
  Future<Map<String, dynamic>> execute({
    required UploadJob job,
    required ProgressCallback onProgress,
  }) async {
    final client = RateApiClient();
    final file = File(job.filePath);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final res = await client.uploadCsvWithProgress(
      data: formData,
      type: job.metadata['type'] as String,
      siteId: job.metadata['siteId'] as String,
      onProgress: (sent, total) {
        final p = total == 0 ? 0.0 : (sent / total).clamp(0.0, 1.0);
        onProgress(p, 'Uploading... ${(p * 100).toStringAsFixed(0)}%');
      },
    );

    if (res is Map<String, dynamic> && res['success'] == true) {
      return res;
    }
    throw Exception(res.toString());
  }
}