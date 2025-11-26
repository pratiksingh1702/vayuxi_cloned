import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/requestQueue.dart';
import 'package:untitled2/core/api/requestQueueModel.dart';
import 'package:untitled2/core/api/syncNotifierProvider.dart';

import 'dio.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  return SyncManager(ref);
});

class SyncManager {
  final Ref ref;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription; // Changed type
  bool _isRetrying = false;

  SyncManager(this.ref) {
    _init();
  }

  void _init() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .distinct()
        .listen((List<ConnectivityResult> results) async { // Changed parameter type
      if (_hasConnection(results)) { // Check if any connection is available
        print("🌐 Connectivity restored. Retrying queued requests...");
        await _retryQueuedRequests();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
  }

  /// Helper to rebuild FormData for file uploads
  Future<FormData> _buildFormData(QueuedRequest req) async {
    print(req.data);
    final formData = FormData.fromMap(req.data!);
    if (req.files != null) {
      for (var f in req.files!) {
        final file = File(f['path']!);
        if (!await file.exists()) continue; // skip if file missing
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
      final requests = await RequestQueue.getAll();
      if (requests.isEmpty) return;

      print("📂 Found ${requests.length} requests in queue");

      // Check current connectivity (updated for List<ConnectivityResult>)
      final connectivityResults = await Connectivity().checkConnectivity();
      if (!_hasConnection(connectivityResults)) {
        print("📵 No connectivity, skipping retry");
        return;
      }

      // Create a copy to avoid modifying while iterating
      final requestsCopy = List<QueuedRequest>.from(requests);

      for (final req in requestsCopy) {
        try {
          print("🔄 Retrying: ${req.method} ${req.path}");

          dynamic requestData;
          Options options = Options(
            method: req.method,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          );

          if (req.contentType == "form") {
            requestData = await _buildFormData(req);
            options.headers = {'Content-Type': 'multipart/form-data'};
          } else {
            requestData = req.data;
            options.headers = {'Content-Type': 'application/json'};
          }


          final res = await DioClient.dio.request(
            req.path,
            data: requestData,
            queryParameters: req.query,
            options: options,
          );
          if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
            print("✅ Success: ${req.path}, status: ${res.statusCode}");
            ref.read(syncNotifierProvider.notifier).state++;
            await RequestQueue.remove(req.id);

            print("😊 Deleted request: ${req.method} ${req.path}");

            // Get and print remaining requests
            final remainingRequests = await RequestQueue.getAll();
            print("📋 Remaining ${remainingRequests.length} requests:");

            if (remainingRequests.isEmpty) {
              print("   🎉 Queue is now empty!");
            } else {
              for (var i = 0; i < remainingRequests.length; i++) {
                final remainingReq = remainingRequests[i];
                print("   ${i + 1}. ${remainingReq.method} ${remainingReq.path}");
                if (remainingReq.data != null) {
                  print("      Data: ${remainingReq.data}");
                }
                if (remainingReq.files != null && remainingReq.files!.isNotEmpty) {
                  print("      Files: ${remainingReq.files!.length}");
                }
              }
            }
          } else {
            print("⚠️ Server error: ${req.path}, status: ${res.statusCode}");
          }
        } on DioException catch (e) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            print("⏰ Timeout for ${req.path}, keeping in queue");
          } else {
            print("⚠️ Retry failed for ${req.path}: ${e.message}");
          }
        } catch (e) {
          print("❌ Unexpected error for ${req.path}: $e");
        }
      }
    } finally {
      _isRetrying = false;
    }
  }

  Future<void> retryNow() async {
    await _retryQueuedRequests();
  }
}