import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/upload_job.dart';
import '../models/upload_status.dart';
import '../registry/upload_handler_registry.dart';
import '../../router/route_tracker.dart';
import '../../router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

final uploadManagerProvider =
NotifierProvider<UploadManager, List<UploadJob>>(UploadManager.new);

class UploadManager extends Notifier<List<UploadJob>> {
  /// Active processor tasks per moduleId (for sequential-per-module enforcement)
  final Map<String, bool> _processingModules = {};
  Timer? _autoDismissTimer;

  @override
  List<UploadJob> build() => [];

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Wait for a specific job to complete and return its final state.
  /// Throws a [TimeoutException] if the job does not complete within [timeout].
  Future<UploadJob> waitForCompletion(String jobId, {Duration timeout = const Duration(minutes: 5)}) async {
    print("🔍 [UploadManager] Starting tracking for job: $jobId (timeout: ${timeout.inSeconds}s)");
    
    final completer = Completer<UploadJob>();
    Timer? timeoutTimer;

    // Check if already completed
    final initial = _getJob(jobId);
    if (initial != null && initial.status.isTerminal) {
      print("✅ [UploadManager] Job $jobId already in terminal state: ${initial.status}");
      return initial;
    }

    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        print("⏰ [UploadManager] Timeout reached for job: $jobId");
        completer.completeError(TimeoutException("Job $jobId timed out after ${timeout.inSeconds}s"));
      }
    });

    // Listen for state changes
    final subscription = ref.listen<List<UploadJob>>(uploadManagerProvider, (previous, next) {
      final job = next.where((j) => j.jobId == jobId).firstOrNull;
      
      if (job == null) {
        print("❓ [UploadManager] Job $jobId removed from queue during tracking");
        if (!completer.isCompleted) {
          completer.completeError(Exception("Job $jobId was removed from queue"));
        }
        return;
      }

      if (job.status.isTerminal) {
        print("🏁 [UploadManager] Job $jobId reached terminal state: ${job.status}");
        if (!completer.isCompleted) {
          completer.complete(job);
        }
      } else {
        print("⏳ [UploadManager] Job $jobId status update: ${job.status} (${(job.progress * 100).toStringAsFixed(0)}%)");
      }
    });

    try {
      return await completer.future;
    } finally {
      timeoutTimer.cancel();
      subscription.close();
      print("🧹 [UploadManager] Tracking cleaned up for job: $jobId");
    }
  }

  String enqueue(UploadJob job) {
    _cancelAutoDismiss();
    
    // ✅ Automatically record the current route if not provided
    final currentRoute = ref.read(currentRouteProvider);
    final finalJob = job.originatingRoute == null 
        ? job.copyWith(originatingRoute: currentRoute) 
        : job;

    state = [...state, finalJob];
    _tryProcessModule(finalJob.moduleId);
    return finalJob.jobId;
  }

  void retry(String jobId) {
    _updateJob(jobId, (j) => j.copyWith(
      status: UploadStatus.queued,
      progress: 0,
      message: 'Retrying...',
      retryCount: j.retryCount + 1,
    ));
    final job = _getJob(jobId);
    if (job != null) _tryProcessModule(job.moduleId);
  }

  void cancel(String jobId) {
    // For future: cancel token support
    removeJob(jobId);
  }

  void removeJob(String jobId) {
    state = state.where((j) => j.jobId != jobId).toList();
    _scheduleAutoDismissIfAllDone();
  }

  void stopAutoDismiss(String jobId) {
    _updateJob(jobId, (j) => j.copyWith(autoDismissAt: null));
  }

  void clearCompleted() {
    state = state.where((j) => !j.status.isTerminal).toList();
  }

  // ─── Queue Processing ─────────────────────────────────────────────────────

  void _tryProcessModule(String moduleId) {
    if (_processingModules[moduleId] == true) return;
    _processModuleQueue(moduleId);
  }

  Future<void> _processModuleQueue(String moduleId) async {
    _processingModules[moduleId] = true;

    try {
      while (true) {
        final nextJob = state
            .where((j) =>
        j.moduleId == moduleId && j.status == UploadStatus.queued)
            .firstOrNull;

        if (nextJob == null) break;

        await _executeJob(nextJob);
      }
    } finally {
      _processingModules[moduleId] = false;
      _scheduleAutoDismissIfAllDone();
    }
  }

  Future<void> _executeJob(UploadJob job) async {
    _updateJob(job.jobId, (j) => j.copyWith(
      status: UploadStatus.uploading,
      progress: 0.01,
      message: 'Uploading...',
      startedAt: DateTime.now(),
    ));

    try {
      final handler = UploadHandlerRegistry.instance.resolve(job.moduleId);

      final result = await handler.execute(
        job: job,
        onProgress: (progress, message) {
          if (progress >= 1.0) {
            _updateJob(job.jobId, (j) => j.copyWith(
              status: UploadStatus.processing,
              progress: 1.0,
              message: 'Processing on server...',
            ));
          } else {
            _updateJob(job.jobId, (j) => j.copyWith(
              status: UploadStatus.uploading,
              progress: progress,
              message: message,
            ));
          }
        },
      );

      _updateJob(job.jobId, (j) => j.copyWith(
        status: UploadStatus.success,
        progress: 1.0,
        message: '✅ Upload complete',
        completedAt: DateTime.now(),
        autoDismissAt: DateTime.now().add(const Duration(seconds: 5)),
        response: result,
      ));

      // ✅ Check for auto-navigation on success
      _handleAutoNavigation(job.jobId);
      
      // Auto-remove terminal jobs after delay
      _scheduleJobRemoval(job.jobId);
    } catch (e) {
      print("❌ Upload failed: $e");
      final current = _getJob(job.jobId);
      final canRetry =
          current != null && current.retryCount < current.maxRetries;

      _updateJob(job.jobId, (j) => j.copyWith(
        status: UploadStatus.failed,
        message: canRetry
            ? '❌ Failed — tap to retry'
            : '❌ Failed after ${current?.maxRetries} retries',
        completedAt: DateTime.now(),
        autoDismissAt: DateTime.now().add(const Duration(seconds: 5)),
        response: e.toString(),
      ));

      // ✅ Check for auto-navigation on failure
      _handleAutoNavigation(job.jobId);

      _scheduleJobRemoval(job.jobId);
    }
  }

  void _handleAutoNavigation(String jobId) {
    final job = _getJob(jobId);
    if (job == null || job.targetRoute == null) return;

    final currentRoute = ref.read(currentRouteProvider);
    
    // Only navigate if user is still on the originating screen
    if (currentRoute == job.originatingRoute) {
      print("🚀 [UploadManager] Auto-navigating for job $jobId to ${job.targetRoute}");
      
      // Trigger navigation using GoRouter
      final router = ref.read(appRouterProvider);
      router.push(job.targetRoute!);

      // Immediately remove from queue as requested
      removeJob(jobId);
    } else {
      print("ℹ️ [UploadManager] Skipping auto-navigation for job $jobId (current: $currentRoute, originating: ${job.originatingRoute})");
    }
  }

  void _scheduleJobRemoval(String jobId) {
    Future.delayed(const Duration(seconds: 5), () {
      final current = _getJob(jobId);
      if (current != null && current.status.isTerminal && current.autoDismissAt != null) {
        removeJob(jobId);
      }
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _scheduleAutoDismissIfAllDone() {
    final hasActive = state.any((j) => j.status.isActive);
    final hasTerminal = state.any((j) => j.status.isTerminal);

    if (!hasActive && hasTerminal) {
      _autoDismissTimer = Timer(const Duration(seconds: 5), clearCompleted);
    }
  }

  void _cancelAutoDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
  }

  UploadJob? _getJob(String jobId) =>
      state.where((j) => j.jobId == jobId).firstOrNull;

  void _updateJob(String jobId, UploadJob Function(UploadJob) updater) {
    state = [
      for (final j in state) if (j.jobId == jobId) updater(j) else j,
    ];
  }
}