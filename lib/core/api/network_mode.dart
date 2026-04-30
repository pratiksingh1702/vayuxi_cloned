import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkMode {
  online,
  suggestedOffline,
  offline,
}

class NetworkModeState {
  final NetworkMode mode;
  final int slowStreak;
  final int goodStreak;
  final int errorStreak;
  final Duration? lastLatency;
  final String? reason;
  final bool showOfflineBanner;

  const NetworkModeState({
    required this.mode,
    required this.slowStreak,
    required this.goodStreak,
    required this.errorStreak,
    required this.lastLatency,
    required this.reason,
    required this.showOfflineBanner,
  });

  const NetworkModeState.initial()
      : mode = NetworkMode.online,
        slowStreak = 0,
        goodStreak = 0,
        errorStreak = 0,
        lastLatency = null,
        reason = null,
        showOfflineBanner = false;

  bool get isOffline => mode == NetworkMode.offline;
  bool get shouldSuggestOffline => mode == NetworkMode.suggestedOffline;

  NetworkModeState copyWith({
    NetworkMode? mode,
    int? slowStreak,
    int? goodStreak,
    int? errorStreak,
    Duration? lastLatency,
    String? reason,
    bool? showOfflineBanner,
  }) {
    return NetworkModeState(
      mode: mode ?? this.mode,
      slowStreak: slowStreak ?? this.slowStreak,
      goodStreak: goodStreak ?? this.goodStreak,
      errorStreak: errorStreak ?? this.errorStreak,
      lastLatency: lastLatency ?? this.lastLatency,
      reason: reason ?? this.reason,
      showOfflineBanner: showOfflineBanner ?? this.showOfflineBanner,
    );
  }
}

final networkModeProvider =
    StateNotifierProvider<NetworkModeNotifier, NetworkModeState>((ref) {
  return NetworkModeNotifier();
});

class NetworkModeNotifier extends StateNotifier<NetworkModeState> {
  NetworkModeNotifier() : super(const NetworkModeState.initial());

  static const bool forceSlowForTesting = false;
  static const Duration slowLatencyThreshold = Duration(seconds: 4);
  static const Duration goodLatencyThreshold = Duration(seconds: 2);
  static const int slowStreakLimit = 3;
  static const int goodStreakLimit = 2;
  static const int errorStreakLimit = 2;
  static const Duration suggestionDuration = Duration(seconds: 3);
  static const Duration suggestionCooldown = Duration(minutes: 2);
  static const int latencyWindowSize = 5;

  Timer? _suggestionTimer;
  Timer? _offlineBannerTimer;
  DateTime? _nextSuggestionAllowedAt;
  final List<int> _latencyWindow = [];

  void recordLatency(Duration latency) {
    final latencyMs = latency.inMilliseconds;
    _latencyWindow.add(latencyMs);
    if (_latencyWindow.length > latencyWindowSize) {
      _latencyWindow.removeAt(0);
    }
    final avgLatencyMs = _latencyWindow.isEmpty
        ? latencyMs.toDouble()
        : _latencyWindow.reduce((a, b) => a + b) / _latencyWindow.length;
    final isSlow = forceSlowForTesting ||
        avgLatencyMs >= slowLatencyThreshold.inMilliseconds;

    if (state.isOffline) {
      if (avgLatencyMs <= goodLatencyThreshold.inMilliseconds) {
        final nextGood = state.goodStreak + 1;
        state = state.copyWith(
          goodStreak: nextGood,
          lastLatency: latency,
          reason: 'stable latency',
        );
        if (nextGood >= goodStreakLimit) {
          switchToOnline(reason: 'Network stable');
        }
      } else {
        state = state.copyWith(
          goodStreak: 0,
          lastLatency: latency,
        );
      }
      return;
    }

    if (isSlow) {
      final nextSlow = state.slowStreak + 1;
      state = state.copyWith(
        slowStreak: nextSlow,
        goodStreak: 0,
        lastLatency: latency,
        reason: 'high latency',
      );
      if (nextSlow >= slowStreakLimit) {
        _suggestOffline('High latency detected');
      }
      return;
    }

    final nextGood = state.goodStreak + 1;
    state = state.copyWith(
      goodStreak: nextGood,
      slowStreak: 0,
      errorStreak: 0,
      lastLatency: latency,
      reason: 'stable latency',
    );

    if (state.mode == NetworkMode.suggestedOffline &&
        nextGood >= goodStreakLimit) {
      switchToOnline(reason: 'Network stable');
    }
  }

  void recordNetworkError(String reason) {
    if (state.isOffline) return;

    final nextError = state.errorStreak + 1;
    final nextSlow = state.slowStreak + 1;
    state = state.copyWith(
      errorStreak: nextError,
      slowStreak: nextSlow,
      goodStreak: 0,
      reason: reason,
    );

    if (nextError >= errorStreakLimit) {
      _suggestOffline(reason);
    }
  }

  void switchToOffline({String reason = 'Offline mode enabled'}) {
    _cancelSuggestionTimer();
    _cancelOfflineBannerTimer();
    state = state.copyWith(
      mode: NetworkMode.offline,
      goodStreak: 0,
      slowStreak: 0,
      errorStreak: 0,
      reason: reason,
      showOfflineBanner: true,
    );

    _offlineBannerTimer = Timer(suggestionDuration, () {
      if (state.mode == NetworkMode.offline) {
        state = state.copyWith(showOfflineBanner: false);
      }
    });
  }

  void switchToOnline({String reason = 'Online mode enabled'}) {
    _cancelSuggestionTimer();
    _cancelOfflineBannerTimer();
    state = state.copyWith(
      mode: NetworkMode.online,
      goodStreak: 0,
      slowStreak: 0,
      errorStreak: 0,
      reason: reason,
      showOfflineBanner: false,
    );
  }

  void clearSuggestion() {
    if (state.mode == NetworkMode.suggestedOffline) {
      switchToOnline(reason: 'Recovered');
    }
  }

  void _suggestOffline(String reason) {
    if (state.mode != NetworkMode.online) return;
    final now = DateTime.now();
    if (_nextSuggestionAllowedAt != null &&
        now.isBefore(_nextSuggestionAllowedAt!)) {
      return;
    }
    state = state.copyWith(
      mode: NetworkMode.suggestedOffline,
      reason: reason,
      showOfflineBanner: false,
    );

    _nextSuggestionAllowedAt = now.add(suggestionCooldown);
    _cancelSuggestionTimer();
    _suggestionTimer = Timer(suggestionDuration, () {
      if (state.mode == NetworkMode.suggestedOffline) {
        switchToOnline(reason: 'Suggestion expired');
      }
    });
  }

  void _cancelSuggestionTimer() {
    _suggestionTimer?.cancel();
    _suggestionTimer = null;
  }

  void _cancelOfflineBannerTimer() {
    _offlineBannerTimer?.cancel();
    _offlineBannerTimer = null;
  }

  @override
  void dispose() {
    _cancelSuggestionTimer();
    _cancelOfflineBannerTimer();
    super.dispose();
  }
}
