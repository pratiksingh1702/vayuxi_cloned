import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/requestQueue.dart';
import 'package:untitled2/core/api/requestQueueModel.dart';
import 'package:untitled2/core/api/sync_job.dart';
import 'package:untitled2/features/noti_system/updates/domain/services/notification_ingestion_service.dart';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../utlis/common_functions.dart';
import 'dio.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(ref);
});

class SyncManager {
  final Ref ref;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<InternetConnectionStatus>? _internetSub;

  bool _isRetrying = false;
  Timer? _periodicTimer;

  void _loadExistingQueue() {
    final items = RequestQueue.getAll();
    for (final r in items) {
      final label = buildTaskLabel(r.method, r.path);
      ref.read(syncJobsProvider.notifier).addQueued(r.id, label);
    }
  }

  SyncManager(this.ref) {
    Future.microtask(() {
      _loadExistingQueue();
    });

    _init();
  }

  void _init() {
    /// Connectivity hint
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) {
      _triggerCheck("connectivity change");
    });

    /// Real internet
    _internetSub = InternetConnectionChecker.I.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        _triggerCheck("internet connected");
      }
    });

    /// Safety retry (VERY IMPORTANT)
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _triggerCheck("periodic");
    });

    /// Initial
    Future.microtask(() => _triggerCheck("initial"));
  }

  /// App resume
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerCheck("resume");
    }
  }

  Future<void> _triggerCheck(String source) async {
    if (_isRetrying) return;
    if (RequestQueue.count == 0) {
      print("😴 No pending requests → skip");
      return;
    }
    print("🔎 Retry trigger from: $source");

    final hasInternet = await InternetConnectionChecker.I.hasConnection;
    if (!hasInternet) {
      print("📵 No internet");
      return;
    }

    final serverOk = await _canReachServer();
    if (!serverOk) {
      print("❌ Server unreachable");
      return;
    }

    await _retryQueuedRequests();
  }

  Future<bool> _canReachServer() async {
    try {
      final res = await DioClient.dio.get("/site");
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<FormData> _buildFormData(QueuedRequest req) async {
    final formData = FormData.fromMap(req.data ?? {});
    if (req.files != null) {
      for (var f in req.files!) {
        final file = File(f['path']!);
        if (!await file.exists()) continue;

        formData.files.add(
          MapEntry(
            f['key']!,
            await MultipartFile.fromFile(
              f['path']!,
              filename: f['filename'],
            ),
          ),
        );
      }
    }
    return formData;
  }

  Future<void> _retryQueuedRequests() async {
    if (_isRetrying) return;
    _isRetrying = true;

    try {
      final requests = RequestQueue.getAll();

      if (requests.isEmpty) {
        return;
      }

      for (final req in requests) {
        final label = buildTaskLabel(req.method, req.path);
        ref.read(syncJobsProvider.notifier).start(req.id, label);
        await NotificationIngestionService.persistSyncRunning(req);

        try {
          dynamic requestData;
          Options options = Options(method: req.method);

          if (req.contentType == "form") {
            requestData = await _buildFormData(req);
            options.headers = {'Content-Type': 'multipart/form-data'};
          } else {
            requestData = req.data;
            if (requestData is Map && requestData["__isList"] == true) {
              requestData = requestData["data"];
            }
            options.headers = {'Content-Type': 'application/json'};
          }

          final res = await DioClient.dio.request(
            req.path,
            data: requestData,
            queryParameters: req.query,
            options: options,
          );

          if (res.statusCode != null &&
              res.statusCode! >= 200 &&
              res.statusCode! < 300) {
            await RequestQueue.remove(req.id);
            ref.read(syncJobsProvider.notifier).success(req.id);
            await NotificationIngestionService.persistSyncSuccess(req);

            if (RequestQueue.count == 0) {
              ref.read(syncJobsProvider.notifier).allDone();
            }

            print("✅ Success: ${req.id}");
          } else {
            ref.read(syncJobsProvider.notifier).failed(req.id, "Server error");

            await RequestQueue.remove(req.id);
            print("❌ Failed: ${req.id}");

            // ❗ keep in queue → retry later
          }
        } catch (e) {
          final msg = e.toString().toLowerCase();

          if (msg.contains("already exists")) {
            await RequestQueue.remove(req.id);
            ref.read(syncJobsProvider.notifier).success(req.id);
            await NotificationIngestionService.persistSyncSuccess(req);
            print("⚠️ Already exists: ${req.id}");
            continue;
          }

          ref.read(syncJobsProvider.notifier).failed(req.id, e.toString());
          await NotificationIngestionService.persistSyncRetryFailed(
            req,
            e.toString(),
          );
          print("❌ Error: ${req.id}");

          // ❗ keep in queue
        }
      }
    } finally {
      _isRetrying = false;
    }
  }

  Future<void> retryNow() async {
    await _triggerCheck("manual");
  }

  Future<void> retry() async {
    await _retryQueuedRequests();
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _internetSub?.cancel();
    _periodicTimer?.cancel();
  }
}
