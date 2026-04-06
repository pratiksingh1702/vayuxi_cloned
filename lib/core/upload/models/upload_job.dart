import 'package:uuid/uuid.dart';
import 'upload_status.dart';

class UploadJob {
  final String jobId;
  final String moduleId;       // e.g. 'rate', 'document', 'invoice'
  final String filePath;
  final Map<String, dynamic> metadata; // siteId, type, etc.
  final String? targetRoute;   // optional: navigate here on success
  final String? originatingRoute; // optional: where the user was when they enqueued the job

  final UploadStatus status;
  final double progress;       // 0.0 – 1.0
  final String message;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? autoDismissAt;
  final dynamic response;
  final int retryCount;
  final int maxRetries;

  const UploadJob({
    required this.jobId,
    required this.moduleId,
    required this.filePath,
    required this.metadata,
    this.targetRoute,
    this.originatingRoute,
    this.status = UploadStatus.queued,
    this.progress = 0.0,
    this.message = 'Queued',
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.autoDismissAt,
    this.response,
    this.retryCount = 0,
    this.maxRetries = 2,
  });

  factory UploadJob.create({
    required String moduleId,
    required String filePath,
    required Map<String, dynamic> metadata,
    String? targetRoute,
    String? originatingRoute,
    int maxRetries = 2,
  }) {
    return UploadJob(
      jobId: const Uuid().v4(),
      moduleId: moduleId,
      filePath: filePath,
      metadata: metadata,
      targetRoute: targetRoute,
      originatingRoute: originatingRoute,
      createdAt: DateTime.now(),
      maxRetries: maxRetries,
    );
  }

  UploadJob copyWith({
    UploadStatus? status,
    double? progress,
    String? message,
    String? originatingRoute,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? autoDismissAt,
    dynamic response,
    int? retryCount,
  }) {
    return UploadJob(
      jobId: jobId,
      moduleId: moduleId,
      filePath: filePath,
      metadata: metadata,
      targetRoute: targetRoute,
      originatingRoute: originatingRoute ?? this.originatingRoute,
      createdAt: createdAt,
      maxRetries: maxRetries,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      autoDismissAt: autoDismissAt ?? this.autoDismissAt,
      response: response ?? this.response,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}