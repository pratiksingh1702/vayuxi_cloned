import 'package:flutter_riverpod/flutter_riverpod.dart';
enum SyncStatus {
  idle,
  running,
  success,
  failed,
}

class SyncState {
  final SyncStatus status;
  final String? currentRequestId;
  final int pendingCount;
  final String? message;

  const SyncState({
    this.status = SyncStatus.idle,
    this.currentRequestId,
    this.pendingCount = 0,
    this.message,
  });

  SyncState copyWith({
    SyncStatus? status,
    String? currentRequestId,
    int? pendingCount,
    String? message,
  }) {
    return SyncState(
      status: status ?? this.status,
      currentRequestId: currentRequestId ?? this.currentRequestId,
      pendingCount: pendingCount ?? this.pendingCount,
      message: message,
    );
  }
}


class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  void setIdle(int count) {
    state = SyncState(
      status: SyncStatus.idle,
      pendingCount: count,
    );
  }

  void start(String id, int count) {
    state = SyncState(
      status: SyncStatus.running,
      currentRequestId: id,
      pendingCount: count,
    );
  }

  void success(String id, int count) {
    state = SyncState(
      status: SyncStatus.success,
      currentRequestId: id,
      pendingCount: count,
    );
  }

  void failed(String id, String msg, int count) {
    state = SyncState(
      status: SyncStatus.failed,
      currentRequestId: id,
      pendingCount: count,
      message: msg,
    );
  }
}

final syncProvider =
StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});
