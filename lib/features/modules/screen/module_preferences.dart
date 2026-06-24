import 'package:shared_preferences/shared_preferences.dart';

class ModulePreferences {
  static const String _keyMultipleEntry = 'multiple_entry_mode';

  static Future<void> setMultipleEntry(bool isMultiple) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMultipleEntry, isMultiple);
  }

  static Future<bool> isMultipleEntry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMultipleEntry) ?? false;
  }
}
