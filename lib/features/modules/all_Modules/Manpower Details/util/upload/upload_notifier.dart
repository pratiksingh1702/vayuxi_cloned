// lib/features/modules/all_Modules/Manpower Details/upload/notifier/upload_job_notifier.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/util/upload/upload_state.dart';

import '../../service/manpowerService.dart';

/// How often to poll the job-status endpoint
const _kPollInterval = Duration(seconds: 3);

/// Max consecutive poll failures before we give up
const _kMaxRetries = 5;

class UploadJobNotifier extends StateNotifier<UploadJobState> {
  UploadJobNotifier() : super(const UploadJobState());

  Timer? _pollTimer;
  int _retryCount = 0;

  // ─────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────

  /// Call this instead of ManpowerAPI.uploadExcel in _onUploadPressed.
  /// Returns true if upload succeeded and polling started.
  Future<bool> startUpload({
    required File file,
    required String type,
    String? siteId,
  }) async {
    _cancelPolling();
    state = const UploadJobState(
      status: UploadJobStatus.uploading,
      message: 'Uploading file...',
    );

    try {
      final res = await ManpowerAPI.flexibleUploadExcelWithSite(
        file: file,
        type: type,
        siteId: siteId,
        analyze: false,
      );

      if (res['success'] != true) {
        _setFailed(res['message'] ?? 'Upload failed');
        return false;
      }

      final data = res['data'];
      final jobId = data is Map ? data['jobId']?.toString() : null;

      if (jobId == null || jobId.isEmpty) {
        _setFailed('No jobId returned from server');
        return false;
      }

      state = state.copyWith(
        status: UploadJobStatus.polling,
        jobId: jobId,
        message: 'Processing file...',
        percentage: 0.0,
      );

      _startPolling(jobId);
      return true;
    } catch (e) {
      _setFailed('Unexpected error: $e');
      return false;
    }
  }

  /// Reset to idle (e.g. when the screen re-opens or user cancels)
  void reset() {
    _cancelPolling();
    state = const UploadJobState();
  }

  // ─────────────────────────────────────────────
  // POLLING
  // ─────────────────────────────────────────────

  void _startPolling(String jobId) {
    _retryCount = 0;
    _pollTimer = Timer.periodic(_kPollInterval, (_) => _poll(jobId));
    // Fire immediately so UI updates fast
    _poll(jobId);
  }

  Future<void> _poll(String jobId) async {
    // Guard: don't poll if already done
    if (state.isCompleted || state.isFailed) {
      _cancelPolling();
      return;
    }

    try {
      final res = await ManpowerAPI.fetchJobStatus(jobId);

      if (res['success'] != true) {
        _retryCount++;
        if (_retryCount >= _kMaxRetries) {
          _setFailed('Could not reach server after $_kMaxRetries attempts.');
        }
        return; // Retry next tick
      }

      _retryCount = 0; // Reset on success
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final next = UploadJobState.fromJobStatus(data, jobId);

      state = next;

      if (next.isCompleted || next.isFailed) {
        _cancelPolling();
      }
    } catch (e) {
      _retryCount++;
      debugPrint('🟦 [UploadJobNotifier] Poll error (retry $_retryCount): $e');
      if (_retryCount >= _kMaxRetries) {
        _setFailed('Network error after $_kMaxRetries retries: $e');
      }
    }
  }

  void _cancelPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _setFailed(String message) {
    _cancelPolling();
    state = state.copyWith(
      status: UploadJobStatus.failed,
      message: message,
    );
  }

  // ─────────────────────────────────────────────
  // DISPOSE — prevents memory leaks
  // ─────────────────────────────────────────────

  @override
  void dispose() {
    _cancelPolling();
    super.dispose();
  }
}