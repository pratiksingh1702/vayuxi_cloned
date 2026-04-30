import 'package:shared_preferences/shared_preferences.dart';

class ModulePreferences {
  static const String _keyCardAttached = 'module_card_attached';
  static const String _keyMultipleEntry = 'multiple_entry_mode';

  static Future<void> setCardAttached(bool isAttached) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCardAttached, isAttached);
  }

  static Future<bool> isCardAttached() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCardAttached) ?? true;
  }

  static Future<void> setMultipleEntry(bool isMultiple) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMultipleEntry, isMultiple);
  }

  static Future<bool> isMultipleEntry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMultipleEntry) ?? false;
  }
}
