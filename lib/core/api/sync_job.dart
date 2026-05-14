import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncJobStatus {
  queued,
  running,
  success,
  failed,
  cancelled,
}

class SyncJob {
  final String id;
  final String label;

  final SyncJobStatus status;
  final String message;

  const SyncJob({
    required this.id,
    required this.label,
    required this.status,
    required this.message,
  });

  SyncJob copyWith({
    SyncJobStatus? status,
    String? message,
  }) {
    return SyncJob(
      id: id,
      label: label,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class SyncJobsNotifier extends StateNotifier<List<SyncJob>> {
  SyncJobsNotifier() : super([]);

  void addQueued(String id, String label) {
    state = [
      ...state,
      SyncJob(
        id: id,
        label: label,
        status: SyncJobStatus.queued,
        message: "Waiting to sync",
      ),
    ];
  }

  void start(String id, String label) {
    state = [
      for (final j in state)
        if (j.id == id)
          j.copyWith(
            status: SyncJobStatus.running,
            message: "Syncing $label",
          )
        else
          j
    ];
  }

  void success(String id) {
    state = [
      for (final j in state)
        if (j.id == id)
          j.copyWith(
            status: SyncJobStatus.success,
            message: "Done",
          )
        else
          j
    ];
    Future.delayed(const Duration(seconds: 2), () {
      remove(id);
    });
  }

  void failed(String id, String msg) {
    state = [
      for (final j in state)
        if (j.id == id)
          j.copyWith(
            status: SyncJobStatus.failed,
            message: msg,
          )
        else
          j
    ];
    Future.delayed(const Duration(seconds: 2), () {
      remove(id);
    });
  }

  void cancel(String id) {
    state = [
      for (final j in state)
        if (j.id == id)
          j.copyWith(
            status: SyncJobStatus.cancelled,
            message: "Cancelled",
          )
        else
          j
    ];
    Future.delayed(const Duration(seconds: 2), () {
      remove(id);
    });
  }

  void allDone() {
    state = [];
  }

  void remove(String id) {
    state = state.where((j) => j.id != id).toList();
  }
}

final syncJobsProvider = StateNotifierProvider<SyncJobsNotifier, List<SyncJob>>(
  (ref) => SyncJobsNotifier(),
);
