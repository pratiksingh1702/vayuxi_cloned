import 'dart:io';
import '../models/upload_job.dart';

typedef ProgressCallback = void Function(double progress, String message);

abstract class UploadHandler {
  /// Unique ID matching UploadJob.moduleId
  String get moduleId;

  /// Execute the actual upload. Call [onProgress] as you go.
  /// Return the server response map on success.
  /// Throw on failure.
  Future<Map<String, dynamic>> execute({
    required UploadJob job,
    required ProgressCallback onProgress,
  });
}