import 'package:shared_preferences/shared_preferences.dart';

class AppTourStorage {
  static const _prefix = 'phase1_tour';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _doneKey(String tourId) => '${_prefix}_${tourId}_done';
  String _stepKey(String tourId) => '${_prefix}_${tourId}_step';

  Future<bool> isDone(String tourId) async {
    final prefs = await _prefs;
    return prefs.getBool(_doneKey(tourId)) ?? false;
  }

  Future<void> markDone(String tourId) async {
    final prefs = await _prefs;
    await prefs.setBool(_doneKey(tourId), true);
    await prefs.remove(_stepKey(tourId));
  }

  Future<int> stepIndex(String tourId) async {
    final prefs = await _prefs;
    return prefs.getInt(_stepKey(tourId)) ?? 0;
  }

  Future<void> saveStepIndex(String tourId, int index) async {
    final prefs = await _prefs;
    await prefs.setInt(_stepKey(tourId), index);
  }

  Future<void> resetTour(String tourId) async {
    final prefs = await _prefs;
    await prefs.remove(_doneKey(tourId));
    await prefs.remove(_stepKey(tourId));
  }

  Future<void> resetAllPhase1() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
