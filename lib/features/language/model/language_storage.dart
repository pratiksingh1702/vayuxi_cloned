import 'package:hive/hive.dart';

import 'download_language.dart';
import 'language_model.dart';

class LanguageStorage {
  final Box metaBox = Hive.box('language_meta');
  final Box<LanguageModule> moduleBox = Hive.box('language_modules');
  final Box<DownloadLanguage> downloadedBox =
  Hive.box<DownloadLanguage>('downloaded_languages');

  bool isLanguageDownloaded(String code) {
    return downloadedBox.containsKey(code);
  }

  Future<void> saveDownloadedLanguage(String code, String version) async {
    await downloadedBox.put(
      code,
      DownloadLanguage(code: code, version: version),
    );
  }

  List<String> getDownloadedLanguages() {
    return downloadedBox.keys.cast<String>().toList();
  }


  // Active language
  String getActiveLanguage() {
    return metaBox.get('activeLanguage', defaultValue: 'en-IN');
  }

  Future<void> setActiveLanguage(String code) async {
    await metaBox.put('activeLanguage', code);
  }

  // Modules
  Future<void> saveModule(
      String languageCode,
      String moduleName,
      Map<String, dynamic> content,
      ) async {
    final key = '$languageCode::$moduleName';
    await moduleBox.put(
      key,
      LanguageModule(
        languageCode: languageCode,
        moduleName: moduleName,
        content: content,
      ),
    );
  }

  LanguageModule? getModule(String languageCode, String moduleName) {
    return moduleBox.get('$languageCode::$moduleName');
  }

  Future<void> removeLanguage(String languageCode) async {
    final keys = moduleBox.keys.where(
          (k) => k.toString().startsWith(languageCode),
    );
    await moduleBox.deleteAll(keys);
    await downloadedBox.delete(languageCode);
  }

}
