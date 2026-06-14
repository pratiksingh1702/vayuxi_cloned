import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../core/api/dio.dart';
import '../models/boq_model.dart';
import '../service/boq_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IMPORTANT: Replace DioClient.dio with your actual import path
// ─────────────────────────────────────────────────────────────────────────────

// ── Service Provider ─────────────────────────────────────────────────────────

final boqApiServiceProvider = Provider<BoqApiService>((ref) {
  return BoqApiService(DioClient.dio);
  throw UnimplementedError('Wire up DioClient.dio here');
});

// ── Type Provider ─────────────────────────────────────────────────────────────

class TypeNotifier extends StateNotifier<String?> {
  TypeNotifier() : super(null);
  void set(String? type) => state = type;
  void clear() => state = null;
}

final typeProvider = StateNotifierProvider<TypeNotifier, String?>((ref) {
  return TypeNotifier();
});

// ── BOQ List ─────────────────────────────────────────────────────────────────

class BoqListParams {
  final String siteId;
  final String? status;
  final int page;

  const BoqListParams({
    required this.siteId,
    this.status,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) =>
      other is BoqListParams &&
          other.siteId == siteId &&
          other.status == status &&
          other.page == page;

  @override
  int get hashCode => Object.hash(siteId, status, page);
}

final boqListParamsProvider = StateProvider<BoqListParams?>((ref) => null);

final boqListProvider = FutureProvider.autoDispose
    .family<({List<BoqListItem> boqs, BoqPagination pagination}), BoqListParams>(
      (ref, params) async {
    final service = ref.watch(boqApiServiceProvider);
    return service.getBoqs(
      siteId: params.siteId,
      status: params.status,
      page: params.page,
    );
  },
);

// ── BOQ Detail ────────────────────────────────────────────────────────────────

class BoqDetailParams {
  final String siteId;
  final String boqId;
  const BoqDetailParams({required this.siteId, required this.boqId});

  @override
  bool operator ==(Object other) =>
      other is BoqDetailParams &&
          other.siteId == siteId &&
          other.boqId == boqId;

  @override
  int get hashCode => Object.hash(siteId, boqId);
}

final boqDetailProvider = FutureProvider.autoDispose
    .family<BoqDetail, BoqDetailParams>((ref, params) async {
  final service = ref.watch(boqApiServiceProvider);
  return service.getBoqDetail(siteId: params.siteId, boqId: params.boqId);
});

// ── BOQ Progress ──────────────────────────────────────────────────────────────

final boqProgressProvider = FutureProvider.autoDispose
    .family<BoqProgress, BoqDetailParams>((ref, params) async {
  final service = ref.watch(boqApiServiceProvider);
  return service.getBoqProgress(siteId: params.siteId, boqId: params.boqId);
});

// ── Upload State ──────────────────────────────────────────────────────────────

enum UploadStatus { idle, uploading, success, error }

class UploadState {
  final UploadStatus status;
  final BoqListItem? result;
  final BoqUploadSummary? summary;
  final String? errorMessage;

  const UploadState({
    required this.status,
    this.result,
    this.summary,
    this.errorMessage,
  });

  const UploadState.idle()
      : status = UploadStatus.idle,
        result = null,
        summary = null,
        errorMessage = null;

  UploadState copyWith({
    UploadStatus? status,
    BoqListItem? result,
    BoqUploadSummary? summary,
    String? errorMessage,
  }) =>
      UploadState(
        status: status ?? this.status,
        result: result ?? this.result,
        summary: summary ?? this.summary,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class UploadBoqNotifier extends StateNotifier<UploadState> {
  final BoqApiService _service;

  UploadBoqNotifier(this._service) : super(const UploadState.idle());

  /// Upload Excel BOQ.
  ///
  /// [timelineJsonString] — pass `_TimelineState.toApiJsonString()`.
  /// The service sends it as a raw JSON string field in multipart form-data,
  /// which matches what the API expects (Phase 3, endpoint 16).
  Future<void> uploadExcel({
    required String siteId,
    required PlatformFile file,
    required String type,
    String? boqName,
    String? timelineJsonString,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading);
    try {
      final result = await _service.uploadBoqExcel(
        siteId: siteId,
        file: file,
        type: type,
        boqName: boqName,
        timelineJsonString: timelineJsonString,
      );
      state = UploadState(
        status: UploadStatus.success,
        result: result.boq,
        summary: result.summary,
      );
    } catch (e) {
      state = UploadState(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create manual mechanical BOQ.
  ///
  /// [timeline] — pass `_TimelineState.toApiPayload()` (a Map or null).
  /// Sent as a JSON object in the request body.
  Future<void> createManualMechanical({
    required String siteId,
    required String boqName,
    List<Map<String, dynamic>>? items,
    double? directTotalInchDia,
    double? directTotalInchMtr,
    Map<String, dynamic>? timeline,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading);
    try {
      final result = await _service.createManualMechanicalBoq(
        siteId: siteId,
        boqName: boqName,
        items: items,
        directTotalInchDia: directTotalInchDia,
        directTotalInchMtr: directTotalInchMtr,
        timeline: timeline,
      );
      state = UploadState(status: UploadStatus.success, result: result);
    } catch (e) {
      state = UploadState(
          status: UploadStatus.error, errorMessage: e.toString());
    }
  }

  /// Create manual insulation BOQ.
  ///
  /// [timeline] — pass `_TimelineState.toApiPayload()` (a Map or null).
  Future<void> createManualInsulation({
    required String siteId,
    required String boqName,
    List<Map<String, dynamic>>? items,
    double? directTotalRMT,
    double? directTotalArea,
    Map<String, dynamic>? timeline,
  }) async {
    state = state.copyWith(status: UploadStatus.uploading);
    try {
      final result = await _service.createManualInsulationBoq(
        siteId: siteId,
        boqName: boqName,
        items: items,
        directTotalRMT: directTotalRMT,
        directTotalArea: directTotalArea,
        timeline: timeline,
      );
      state = UploadState(status: UploadStatus.success, result: result);
    } catch (e) {
      state = UploadState(
          status: UploadStatus.error, errorMessage: e.toString());
    }
  }

  void reset() => state = const UploadState.idle();
}

final uploadBoqProvider =
StateNotifierProvider.autoDispose<UploadBoqNotifier, UploadState>((ref) {
  return UploadBoqNotifier(ref.watch(boqApiServiceProvider));
});

// ── Notification Preferences ──────────────────────────────────────────────────

final notificationPreferencesProvider =
FutureProvider.autoDispose<NotificationPreferences>((ref) async {
  final service = ref.watch(boqApiServiceProvider);
  return service.getNotificationPreferences();
});

final notificationHistoryProvider =
FutureProvider.autoDispose<List<NotificationHistoryItem>>((ref) async {
  final service = ref.watch(boqApiServiceProvider);
  return service.getNotificationHistory();
});

final notificationStatsProvider =
FutureProvider.autoDispose<NotificationStats>((ref) async {
  final service = ref.watch(boqApiServiceProvider);
  return service.getNotificationStats();
});

// ── Saving Notification Preferences State ────────────────────────────────────

class SavePrefsNotifier extends StateNotifier<AsyncValue<void>> {
  final BoqApiService _service;
  SavePrefsNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> save(Map<String, dynamic> globalSettings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
            () => _service.updateNotificationPreferences(
            globalSettings: globalSettings));
  }

  Future<void> sendTest() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.sendTestNotification());
  }
}

final savePrefsProvider =
StateNotifierProvider.autoDispose<SavePrefsNotifier, AsyncValue<void>>(
        (ref) => SavePrefsNotifier(ref.watch(boqApiServiceProvider)));

// ── Status Update Notifier ────────────────────────────────────────────────────

class BoqStatusNotifier extends StateNotifier<AsyncValue<void>> {
  final BoqApiService _service;
  BoqStatusNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> updateStatus({
    required String siteId,
    required String boqId,
    required String status,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
            () => _service.updateBoqStatus(
            siteId: siteId, boqId: boqId, status: status));
  }

  Future<void> delete({
    required String siteId,
    required String boqId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
            () => _service.deleteBoq(siteId: siteId, boqId: boqId));
  }
}

final boqStatusProvider =
StateNotifierProvider.autoDispose<BoqStatusNotifier, AsyncValue<void>>(
        (ref) => BoqStatusNotifier(ref.watch(boqApiServiceProvider)));