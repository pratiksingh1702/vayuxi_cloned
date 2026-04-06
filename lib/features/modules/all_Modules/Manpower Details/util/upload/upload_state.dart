// lib/features/modules/all_Modules/Manpower Details/upload/state/upload_job_state.dart

enum UploadJobStatus { idle, uploading, polling, completed, failed }

class UploadJobState {
  final UploadJobStatus status;
  final String? jobId;

  // Progress fields from job-status API
  final int totalRows;
  final int processedRows;
  final int successCount;
  final int errorCount;
  final int duplicatesFound;
  final double percentage; // 0.0 → 1.0

  // Error / warning messages
  final List<String> errors;
  final List<String> warnings;
  final List<Map<String, dynamic>> duplicateDetails;

  // Human-readable message shown in UI
  final String? message;

  const UploadJobState({
    this.status = UploadJobStatus.idle,
    this.jobId,
    this.totalRows = 0,
    this.processedRows = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.duplicatesFound = 0,
    this.percentage = 0.0,
    this.errors = const [],
    this.warnings = const [],
    this.duplicateDetails = const [],
    this.message,
  });

  bool get isIdle => status == UploadJobStatus.idle;
  bool get isUploading => status == UploadJobStatus.uploading;
  bool get isPolling => status == UploadJobStatus.polling;
  bool get isCompleted => status == UploadJobStatus.completed;
  bool get isFailed => status == UploadJobStatus.failed;
  bool get isInProgress => isUploading || isPolling;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasDuplicates => duplicateDetails.isNotEmpty;

  UploadJobState copyWith({
    UploadJobStatus? status,
    String? jobId,
    int? totalRows,
    int? processedRows,
    int? successCount,
    int? errorCount,
    int? duplicatesFound,
    double? percentage,
    List<String>? errors,
    List<String>? warnings,
    List<Map<String, dynamic>>? duplicateDetails,
    String? message,
  }) {
    return UploadJobState(
      status: status ?? this.status,
      jobId: jobId ?? this.jobId,
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
      duplicatesFound: duplicatesFound ?? this.duplicatesFound,
      percentage: percentage ?? this.percentage,
      errors: errors ?? this.errors,
      warnings: warnings ?? this.warnings,
      duplicateDetails: duplicateDetails ?? this.duplicateDetails,
      message: message ?? this.message,
    );
  }

  /// Parse from job-status API response JSON
  static UploadJobState fromJobStatus(Map<String, dynamic> json, String jobId) {
    final progress = json['progress'] as Map<String, dynamic>? ?? {};
    final rawErrors = json['errors'] as List<dynamic>? ?? [];
    final rawWarnings = json['warnings'] as List<dynamic>? ?? [];
    final rawDuplicates = json['duplicateDetails'] as List<dynamic>? ?? [];

    final rawStatus = json['status']?.toString() ?? '';
    final jobStatus = _parseStatus(rawStatus);

    final rawPct = progress['percentage'];
    final pct = (rawPct is num ? rawPct.toDouble() : double.tryParse('$rawPct') ?? 0.0) / 100.0;

    return UploadJobState(
      status: jobStatus,
      jobId: jobId,
      totalRows: _parseInt(progress['totalRows']),
      processedRows: _parseInt(progress['processedRows']),
      successCount: _parseInt(progress['successCount']),
      errorCount: _parseInt(progress['errorCount']),
      duplicatesFound: _parseInt(progress['duplicatesFound']),
      percentage: pct.clamp(0.0, 1.0),
      errors: rawErrors.map((e) => e.toString()).toList(),
      warnings: rawWarnings.map((e) => e.toString()).toList(),
      duplicateDetails: rawDuplicates
          .whereType<Map<String, dynamic>>()
          .toList(),
    );
  }

  static UploadJobStatus _parseStatus(String raw) {
    switch (raw.toLowerCase()) {
      case 'completed':
        return UploadJobStatus.completed;
      case 'failed':
        return UploadJobStatus.failed;
      default:
        return UploadJobStatus.polling;
    }
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }
}