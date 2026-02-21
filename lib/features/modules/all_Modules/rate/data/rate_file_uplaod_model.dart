enum UploadStatus {
  queued,
  uploading,   // file upload running
  processing,  // backend working (no response yet)
  success,
  failed,
}


class RateUploadJob {
  final String jobId;
  final String siteId;
  final String type;
  final String filePath;

  final UploadStatus status;

  final double progress; // only for UPLOADING (0..1)
  final String message;

  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  final dynamic response;

 RateUploadJob({
    required this.jobId,
    required this.siteId,
    required this.type,
    required this.filePath,
    this.status = UploadStatus.queued,
    this.progress = 0.0,
    this.message = "Queued",
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    this.response,
  }) : createdAt = createdAt ?? DateTime.now();

  RateUploadJob copyWith({
    UploadStatus? status,
    double? progress,
    String? message,
    DateTime? startedAt,
    DateTime? completedAt,
    dynamic response,
  }) {
    return RateUploadJob(
      jobId: jobId,
      siteId: siteId,
      type: type,
      filePath: filePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      response: response ?? this.response,
    );
  }
}
