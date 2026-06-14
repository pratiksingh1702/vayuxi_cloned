// lib/features/tour/domain/voice_assistant_service.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// VOICE ASSISTANT SERVICE
// Wraps flutter_tts so the TourController can call a simple API.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

// ── Provider ─────────────────────────────────────────────────────────────────

final voiceAssistantProvider = Provider<VoiceAssistantService>((ref) {
  final service = VoiceAssistantService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Service ───────────────────────────────────────────────────────────────────

class VoiceAssistantService {
  final FlutterTts _tts = FlutterTts();

  bool _isMuted = false;
  int _speakToken = 0;
  Future<void>? _hindiConfigFuture;
  bool _hindiReady = false;
  bool get isMuted => _isMuted;

  VoiceAssistantService() {
    _hindiConfigFuture = _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    await _configureHindiVoice();
  }

  Future<void> prepareHindi() {
    _hindiConfigFuture ??= _configureHindiVoice();
    return _hindiConfigFuture!;
  }

  Future<void> _configureHindiVoice() async {
    try {
      try {
        await _tts.setEngine('com.google.android.tts');
      } catch (_) {
        // Engine selection is Android-only and depends on device support.
      }
      await _tts.setLanguage('hi-IN');
      final voices = await _tts.getVoices;
      final hindiVoice = _bestHindiVoice(voices);
      if (hindiVoice != null) {
        await _tts.setVoice(hindiVoice);
        debugPrint('Tour TTS Hindi voice selected: $hindiVoice');
      }
      await _tts.setSpeechRate(0.34);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _hindiReady = true;
    } catch (_) {
      await _tts.setLanguage('hi-IN');
      await _tts.setSpeechRate(0.34);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _hindiReady = true;
    }
  }

  Map<String, String>? _bestHindiVoice(dynamic voices) {
    if (voices is! Iterable) return null;

    final normalized = voices
        .whereType<Map>()
        .map((voice) => voice.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ))
        .toList();

    bool isHindi(Map<String, String> voice) {
      final locale = (voice['locale'] ?? '').toLowerCase();
      final name = (voice['name'] ?? '').toLowerCase();
      return locale == 'hi-in' ||
          locale.startsWith('hi_') ||
          locale.startsWith('hi-') ||
          name.contains('hindi') ||
          name.contains('hi-in');
    }

    int score(Map<String, String> voice) {
      final locale = (voice['locale'] ?? '').toLowerCase();
      final name = (voice['name'] ?? '').toLowerCase();
      final networkRequired =
          (voice['networkConnectionRequired'] ?? '').toLowerCase() == 'true';
      final quality = (voice['quality'] ?? '').toLowerCase();
      var value = 0;
      if (locale == 'hi-in') value += 100;
      if (name.contains('hindi')) value += 40;
      if (name.contains('hi-in')) value += 35;
      if (networkRequired) value += 28;
      if (name.contains('network')) value += 24;
      if (quality.contains('very_high')) value += 22;
      if (quality.contains('high')) value += 16;
      if (name.contains('natural')) value += 14;
      if (name.contains('female')) value += 12;
      if (name.contains('google')) value += 8;
      if (name.contains('local')) value -= 6;
      return value;
    }

    final hindiVoices = normalized.where(isHindi).toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    if (hindiVoices.isEmpty) return null;

    final selected = hindiVoices.first;
    final name = selected['name'];
    final locale = selected['locale'];
    if (name == null || locale == null) return null;
    return {'name': name, 'locale': locale};
  }

  /// Speak [text] immediately, cancelling any current speech.
  Future<void> speak(String text) async {
    if (_isMuted) return;
    final token = ++_speakToken;
    await _tts.stop();
    if (token != _speakToken) return;
    await _tts.setLanguage('en-US');
    if (token != _speakToken) return;
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);
    if (token != _speakToken) return;
    await _tts.speak(text);
  }

  Future<void> speakHindi(String text) async {
    final cleanText = text.trim();
    if (_isMuted || cleanText.isEmpty) return;
    final token = ++_speakToken;
    await _tts.stop();
    if (token != _speakToken) return;
    if (!_hindiReady) {
      await prepareHindi();
    }
    if (token != _speakToken) return;
    await _tts.speak(cleanText);
  }

  /// Replay the last text (caller must pass the text again).
  Future<void> replay(String text) => speak(text);

  /// Stop any current speech.
  Future<void> stop() async {
    _speakToken++;
    await _tts.stop();
  }

  /// Toggle mute on/off. Returns new muted state.
  Future<bool> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) await stop();
    return _isMuted;
  }

  Future<void> dispose() async => _tts.stop();
}
