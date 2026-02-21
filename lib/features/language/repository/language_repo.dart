import 'package:dio/dio.dart';

import '../model/language_storage.dart';
import '../service/language_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageRepository {
  final LanguageApiService api;
  final LanguageStorage storage;

  LanguageRepository(this.api, this.storage);

  String get activeLanguage => storage.getActiveLanguage();

  Future<void> changeLanguage(String userId, String languageCode) async {
    // First check if the language is available offline
    final isDownloaded = storage.isLanguageDownloaded(languageCode);

    if (isDownloaded) {
      // Change language offline without network
      final oldLang = storage.getActiveLanguage();
      await storage.setActiveLanguage(languageCode);

      // Optional: Only remove old language if you want to conserve space
      // await storage.removeLanguage(oldLang);

      return; // Successfully changed offline
    }

    try {
      // If not downloaded, try to sync with server
      await api.setActiveLanguage(userId, languageCode);

      final oldLang = storage.getActiveLanguage();
      await storage.removeLanguage(oldLang);

      await storage.setActiveLanguage(languageCode);
    } catch (e) {
      // Network error - cannot change to undownloaded language
      throw Exception(
        'Cannot change to $languageCode: Language not downloaded and network unavailable.',
      );
    }
  }

  Future<void> downloadAndStoreLanguage(
      String userId,
      String languageCode,
      ) async {
    final res = await api.downloadLanguage(userId, languageCode);

    final data = res.data['data'] as Map<String, dynamic>;

    final version = data['version'] as String;
    final modules = data['modules'] as Map<String, dynamic>;

    await storage.saveDownloadedLanguage(languageCode, version);

    for (final entry in modules.entries) {
      final raw = entry.value as Map<String, dynamic>;
      final content = raw[entry.key] as Map<String, dynamic>;

      await storage.saveModule(
        languageCode,
        entry.key,
        content,
      );
    }
  }

  Future<Map<String, dynamic>> loadModule({
    required String userId,
    required String moduleName,
  }) async {
    final lang = storage.getActiveLanguage();

    // ✅ 1) Try local first
    final local = storage.getModule(lang, moduleName);
    if (local != null) return local.content;

    // ✅ 2) If language is downloaded but module missing => corruption
    if (storage.isLanguageDownloaded(lang)) {
      throw Exception('Offline language corrupted: $moduleName missing for $lang');
    }

    // ✅ 3) Else fetch from server
    try {
      final res = await api.getModule(userId, lang, moduleName);
      final content = res.data['data']['content'][moduleName];

      await storage.saveModule(lang, moduleName, content);
      return content;
    } on DioException catch (e) {
      // ✅ If new user: language not downloaded -> download default english and retry
      if (_isLanguageNotDownloadedError(e)) {
        const defaultLang = "en-IN";

        // download English
        await api.downloadLanguage(userId, defaultLang);
        await api.setActiveLanguage(userId, defaultLang);

        // IMPORTANT: update local storage too
        await storage.setActiveLanguage(defaultLang);


        // retry module
        final res2 = await api.getModule(userId, defaultLang, moduleName);
        final content2 = res2.data['data']['content'][moduleName];

        await storage.saveModule(defaultLang, moduleName, content2);
        return content2;
      }

      rethrow;
    }

  }
  bool _isLanguageNotDownloadedError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = (data['message'] ?? '').toString().toLowerCase();
      return msg.contains('language not downloaded');
    }
    return false;
  }



  // Helper method to check if language change is possible offline
  bool canChangeToLanguageOffline(String languageCode) {
    return storage.isLanguageDownloaded(languageCode);
  }

  // Get list of languages that can be used offline
  List<String> getAvailableOfflineLanguages() {
    return storage.getDownloadedLanguages();
  }
}