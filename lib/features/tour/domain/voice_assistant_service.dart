// lib/features/tour/domain/voice_assistant_service.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// VOICE ASSISTANT SERVICE
// Wraps flutter_tts so the TourController can call a simple API.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
  bool get isMuted => _isMuted;

  VoiceAssistantService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);   // slightly slower = clearer
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
  }

  /// Speak [text] immediately, cancelling any current speech.
  Future<void> speak(String text) async {
    if (_isMuted) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Replay the last text (caller must pass the text again).
  Future<void> replay(String text) => speak(text);

  /// Stop any current speech.
  Future<void> stop() async => _tts.stop();

  /// Toggle mute on/off. Returns new muted state.
  Future<bool> toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) await stop();
    return _isMuted;
  }

  Future<void> dispose() async => _tts.stop();
}
