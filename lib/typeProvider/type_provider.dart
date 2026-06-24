import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/typeProvider/work_type.dart';

const String selectedWorkTypePreferenceKey = 'selected_work_type';

final typeProvider = StateNotifierProvider<TypeNotifier, String?>((ref) {
  return TypeNotifier();
});

class TypeNotifier extends StateNotifier<String?> {
  TypeNotifier() : super(null) {
    _restoreType();
  }

  Future<void> setType(String type) async {
    state = type;
    await _persistType(type);
  }

  Future<void> _restoreType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(selectedWorkTypePreferenceKey);
    if (WorkType.fromApiValue(savedType) != null) {
      state = savedType;
    }
  }

  Future<void> _persistType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedWorkTypePreferenceKey, type);
  }

  static Future<String?> readSavedType() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(selectedWorkTypePreferenceKey);
    return WorkType.fromApiValue(savedType) == null ? null : savedType;
  }
}

final workTypeProvider = Provider<WorkType?>((ref) {
  return WorkType.fromApiValue(ref.watch(typeProvider));
});
