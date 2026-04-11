import 'dart:io';

import '../../../features/modules/all_Modules/site_Details/providers/site_service.dart';
import '../models/upload_job.dart';
import 'upload_handler.dart';

class SiteUploadHandler implements UploadHandler {
  @override
  String get moduleId => 'site';

  @override
  Future<Map<String, dynamic>> execute({
    required UploadJob job,
    required ProgressCallback onProgress,
  }) async {
    final file = File(job.filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: ${job.filePath}');
    }

    final type = job.metadata['type'] as String?;
    if (type == null || type.isEmpty) {
      throw Exception('metadata.type is required for site upload');
    }

    final siteId = job.metadata['siteId'] as String?;

    onProgress(0.1, 'Preparing site upload...');

    final response = await SiteAPI.uploadFile(
      file,
      type,
      siteId: siteId,
    );

    onProgress(1.0, 'Site upload complete');
    return response;
  }
}
