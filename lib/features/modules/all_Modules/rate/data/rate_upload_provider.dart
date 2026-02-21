import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rateApi.dart';
import 'package:untitled2/features/modules/all_Modules/rate/data/rate_file_uplaod_model.dart';
import 'package:uuid/uuid.dart';

final rateUploadQueueProvider =
StateNotifierProvider<RateUploadQueueNotifier, List<RateUploadJob>>(
      (ref) => RateUploadQueueNotifier(ref),
);

class RateUploadQueueNotifier extends StateNotifier<List<RateUploadJob>> {
  final Ref ref;
  final _uuid = const Uuid();

  RateUploadQueueNotifier(this.ref) : super([]);

  bool _isProcessing = false;

  /// ✅ Add upload job in queue
  String enqueueUpload({
    required String siteId,
    required String type,
    required String filePath,
  }) {
    final job = RateUploadJob(
      jobId: _uuid.v4(),
      siteId: siteId,
      type: type,
      filePath: filePath,
    );

    state = [...state, job];
    _processQueue(); // auto start
    return job.jobId;
  }

  void removeJob(String jobId) {
    state = state.where((j) => j.jobId != jobId).toList();
  }

  void clearAll() {
    state = [];
  }

  RateUploadJob? getJob(String jobId) {
    return state.cast<RateUploadJob?>().firstWhere(
          (j) => j!.jobId == jobId,
      orElse: () => null,
    );
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (true) {
        final nextJobIndex = state.indexWhere(
              (j) => j.status == UploadStatus.queued,
        );
        if (nextJobIndex == -1) break;

        final job = state[nextJobIndex];

        // mark uploading
        _updateJob(job.jobId, (j) => j.copyWith(
          status: UploadStatus.uploading,
          progress: 0.01,
          message: "Uploading...",
        ));

        try {
          final client = RateApiClient();
          final file = File(job.filePath);

          final formData = FormData.fromMap({
            "file": await MultipartFile.fromFile(file.path),
          });
          final res = await client.uploadCsvWithProgress(
            data: formData,
            type: job.type,
            siteId: job.siteId,
              onProgress: (sent, total) {
                final p = total == 0 ? 0.0 : sent / total;
                final clamped = p.clamp(0.0, 1.0);

                _updateJob(job.jobId, (j) => j.copyWith(
                  status: UploadStatus.uploading,
                  progress: clamped,
                  message: "Uploading file... ${(clamped * 100).toStringAsFixed(0)}%",
                  startedAt: j.startedAt ?? DateTime.now(),
                ));

                if (clamped >= 1.0) {
                  // ✅ upload complete but backend may still process
                  _updateJob(job.jobId, (j) => j.copyWith(
                    status: UploadStatus.processing,
                    message: "Processing on server...",
                  ));
                }
              },

          );

// ✅ if reached here => server response already returned


          if (res is Map<String, dynamic> && res['success'] == true) {
            _updateJob(job.jobId, (j) => j.copyWith(
              status: UploadStatus.success,
              progress: 1.0,
              message: "✅ Done",
              completedAt: DateTime.now(),
              response: res['data'],
            ));

            // ✅ KEEP IT VISIBLE for a moment
            Future.delayed(const Duration(seconds: 2), () {
              // remove ONLY if still success
              final stillThere = state.where((x) => x.jobId == job.jobId).toList();
              if (stillThere.isNotEmpty &&
                  stillThere.first.status == UploadStatus.success) {
                removeJob(job.jobId);
              }
            });
          }
          else {
            _updateJob(job.jobId, (j) => j.copyWith(
              status: UploadStatus.failed,
              message: "❌ Failed",
              completedAt: DateTime.now(),
              response: res,
            ));

            // keep failure for 3 sec
            Future.delayed(const Duration(seconds: 3), () {
              final stillThere = state.where((x) => x.jobId == job.jobId).toList();
              if (stillThere.isNotEmpty &&
                  stillThere.first.status == UploadStatus.failed) {
                removeJob(job.jobId);
              }
            });
          }


        } catch (e) {
          _updateJob(job.jobId, (j) => j.copyWith(
            status: UploadStatus.failed,
            message: "Server unavailable",
            completedAt: DateTime.now(),
            response: e.toString(),
          ));
          // keep failure for 3 sec
          Future.delayed(const Duration(seconds: 3), () {
            final stillThere = state.where((x) => x.jobId == job.jobId).toList();
            if (stillThere.isNotEmpty &&
                stillThere.first.status == UploadStatus.failed) {
              removeJob(job.jobId);
            }
          });
        }

      }
    } finally {
      _isProcessing = false;
    }
  }

  void _updateJob(String jobId, RateUploadJob Function(RateUploadJob) updater) {
    state = [
      for (final j in state)
        if (j.jobId == jobId) updater(j) else j
    ];
  }
}
