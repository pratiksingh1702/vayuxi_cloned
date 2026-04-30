import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio.dart';
import 'network_mode.dart';

class NetworkMetricsState {
  final bool probing;
  final bool healthOk;
  final int? lastLatencyMs;
  final double? avgLatencyMs;
  final double? downloadKbps;
  final double? uploadKbps;
  final DateTime? lastCheckedAt;
  final String? lastError;

  const NetworkMetricsState({
    required this.probing,
    required this.healthOk,
    required this.lastLatencyMs,
    required this.avgLatencyMs,
    required this.downloadKbps,
    required this.uploadKbps,
    required this.lastCheckedAt,
    required this.lastError,
  });

  const NetworkMetricsState.initial()
      : probing = false,
        healthOk = true,
        lastLatencyMs = null,
        avgLatencyMs = null,
        downloadKbps = null,
        uploadKbps = null,
        lastCheckedAt = null,
        lastError = null;

  NetworkMetricsState copyWith({
    bool? probing,
    bool? healthOk,
    int? lastLatencyMs,
    double? avgLatencyMs,
    double? downloadKbps,
    double? uploadKbps,
    DateTime? lastCheckedAt,
    String? lastError,
  }) {
    return NetworkMetricsState(
      probing: probing ?? this.probing,
      healthOk: healthOk ?? this.healthOk,
      lastLatencyMs: lastLatencyMs ?? this.lastLatencyMs,
      avgLatencyMs: avgLatencyMs ?? this.avgLatencyMs,
      downloadKbps: downloadKbps ?? this.downloadKbps,
      uploadKbps: uploadKbps ?? this.uploadKbps,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastError: lastError ?? this.lastError,
    );
  }
}

final networkMetricsProvider =
    StateNotifierProvider<NetworkMetricsNotifier, NetworkMetricsState>((ref) {
  return NetworkMetricsNotifier(ref);
});

class NetworkMetricsNotifier extends StateNotifier<NetworkMetricsState> {
  NetworkMetricsNotifier(this._ref)
      : super(const NetworkMetricsState.initial()) {
    _start();
  }

  static const Duration probeInterval = Duration(seconds: 15);
  static const Duration probeTimeout = Duration(seconds: 8);
  static const int latencyWindowSize = 5;
  static const bool enableUploadProbe = true;
  static const int uploadProbeBytes = 16 * 1024;

  final Ref _ref;
  Timer? _timer;
  final List<int> _latencyWindow = [];

  void _start() {
    _probe();
    _timer = Timer.periodic(probeInterval, (_) => _probe());
  }

  Future<void> _probe() async {
    if (state.probing) return;
    state = state.copyWith(probing: true);

    final uri = Uri.parse(DioClient.healthUrl);
    final client = HttpClient()..connectionTimeout = probeTimeout;
    final sw = Stopwatch()..start();

    bool healthOk = false;
    int? latencyMs;
    double? downloadKbps;
    double? uploadKbps;
    String? error;

    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      int bytes = 0;
      await for (final chunk in response) {
        bytes += chunk.length;
      }
      sw.stop();

      latencyMs = sw.elapsedMilliseconds;
      healthOk = response.statusCode >= 200 && response.statusCode < 300;

      if (latencyMs > 0 && bytes > 0) {
        downloadKbps = (bytes * 8) / (latencyMs / 1000) / 1000;
      }
    } catch (e) {
      sw.stop();
      error = e.toString();
    } finally {
      client.close(force: true);
    }

    if (enableUploadProbe) {
      uploadKbps = await _measureUpload(uri);
    }

    if (latencyMs != null) {
      _latencyWindow.add(latencyMs);
      if (_latencyWindow.length > latencyWindowSize) {
        _latencyWindow.removeAt(0);
      }
      final avgLatency = _latencyWindow.reduce((a, b) => a + b) /
          _latencyWindow.length;

      state = state.copyWith(
        probing: false,
        healthOk: healthOk,
        lastLatencyMs: latencyMs,
        avgLatencyMs: avgLatency,
        downloadKbps: downloadKbps,
        uploadKbps: uploadKbps,
        lastCheckedAt: DateTime.now(),
        lastError: error,
      );

      _ref
          .read(networkModeProvider.notifier)
          .recordLatency(Duration(milliseconds: latencyMs));

      if (!healthOk) {
        _ref
            .read(networkModeProvider.notifier)
            .recordNetworkError('health check failed');
      }
      return;
    }

    state = state.copyWith(
      probing: false,
      healthOk: false,
      lastCheckedAt: DateTime.now(),
      lastError: error ?? 'health check failed',
      uploadKbps: uploadKbps,
    );
  }

  Future<double?> _measureUpload(Uri uri) async {
    final client = HttpClient()..connectionTimeout = probeTimeout;
    final payload = List<int>.filled(uploadProbeBytes, 0);
    final sw = Stopwatch()..start();

    try {
      final request = await client.postUrl(uri);
      request.headers
          .set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
      request.add(payload);
      final response = await request.close();
      await response.drain();
      sw.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final elapsedMs = sw.elapsedMilliseconds;
      if (elapsedMs == 0) return null;
      return (payload.length * 8) / (elapsedMs / 1000) / 1000;
    } catch (_) {
      sw.stop();
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
