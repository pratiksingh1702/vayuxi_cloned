// features/auth/onboarding/service/onboarding_service.dart
//
// OFFLINE-FIRST STRATEGY
// ──────────────────────
// getStatus()     → tries API, falls back to SharedPreferences cache.
// getQuestions()  → tries API, falls back to SharedPreferences cache.
// submitAnswers() → requires network (mutating call); throws clearly if offline.
//
// Cache keys:
//   onboarding_status_cache    → JSON string of the status map
//   onboarding_questions_cache → JSON string of the questions list

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/dio.dart';

class OnboardingService {
  // ── Cache keys ─────────────────────────────────────────────────────────────
  static const _kStatusKey    = 'onboarding_status_cache';
  static const _kQuestionsKey = 'onboarding_questions_cache';

  // ── GET /api/v1/trial-onboarding/status ────────────────────────────────────
  //
  // Returns the status map: { isCompleted, trialActivated, ... }
  // On network failure, returns the last cached value.
  // Throws only when both network AND cache are unavailable.
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await DioClient.dio.get('/trial-onboarding/status');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final status = Map<String, dynamic>.from(data['status']);

        // Persist for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kStatusKey, jsonEncode(status));

        return status;
      }
      throw Exception(data['message'] ?? 'Failed to fetch onboarding status');
    } catch (e) {
      // Network or server error → try cache
      print('OnboardingService.getStatus: API failed ($e), checking cache…');

      final prefs  = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kStatusKey);

      if (cached != null) {
        print('OnboardingService.getStatus: returning cached status');
        return Map<String, dynamic>.from(jsonDecode(cached));
      }

      // Nothing cached either — rethrow so callers can handle it
      rethrow;
    }
  }

  // ── GET /api/v1/trial-onboarding/questions ─────────────────────────────────
  //
  // Returns the list of onboarding questions.
  // Falls back to cache when offline.
  static Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final response = await DioClient.dio.get('/trial-onboarding/questions');
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final questions = List<Map<String, dynamic>>.from(data['questions']);

        // Persist for offline use
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kQuestionsKey, jsonEncode(questions));

        return questions;
      }
      throw Exception(data['message'] ?? 'Failed to fetch questions');
    } catch (e) {
      print('OnboardingService.getQuestions: API failed ($e), checking cache…');

      final prefs  = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kQuestionsKey);

      if (cached != null) {
        print('OnboardingService.getQuestions: returning cached questions');
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }

      rethrow;
    }
  }

  // ── POST /api/v1/trial-onboarding/submit ───────────────────────────────────
  //
  // Submitting answers is a mutating call — it cannot be done offline.
  // Throws a clear, user-friendly error if the request fails.
  static Future<String> submitAnswers(
      List<Map<String, dynamic>> answers) async {
    try {
      final response = await DioClient.dio.post(
        '/trial-onboarding/submit',
        data: {'answers': answers},
      );
      final data = response.data as Map<String, dynamic>;

      if (data['success'] == true) {
        final referralCode = data['data']['referralCode'] as String;

        // After a successful submit the onboarding is complete.
        // Update the status cache immediately so getStatus() returns fresh
        // data even before the next API call.
        await _patchStatusCache(isCompleted: true);

        return referralCode;
      }
      throw Exception(data['message'] ?? 'Failed to submit answers');
    } catch (e) {
      // Re-wrap with a friendlier message if it looks like a network error
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection refused') ||
          msg.contains('Network is unreachable') ||
          msg.contains('Failed host lookup')) {
        throw Exception(
            'No internet connection. Please connect and try again.');
      }
      rethrow;
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  /// Merge a partial update into the cached status map.
  static Future<void> _patchStatusCache(
      {bool? isCompleted, bool? trialActivated}) async {
    final prefs  = await SharedPreferences.getInstance();
    final cached = prefs.getString(_kStatusKey);

    Map<String, dynamic> status =
    cached != null ? Map<String, dynamic>.from(jsonDecode(cached)) : {};

    if (isCompleted  != null) status['isCompleted']    = isCompleted;
    if (trialActivated != null) status['trialActivated'] = trialActivated;

    await prefs.setString(_kStatusKey, jsonEncode(status));
  }

  /// Call this on logout so stale onboarding data is not shown to the next user.
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStatusKey);
    await prefs.remove(_kQuestionsKey);
  }
}