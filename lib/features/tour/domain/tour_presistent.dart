// lib/features/tour/domain/tour_presistent.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// TOUR PERSISTENCE — module-aware, per-step-index storage
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';

class TourPersistence {
  // ── Key helpers ────────────────────────────────────────────────────────────
  static const _kGlobalCompleted = 'tour_global_completed';

  static String _moduleKey(String moduleId)        => 'tour_module_${moduleId}_done';
  static String _moduleIndexKey(String moduleId)   => 'tour_module_${moduleId}_step';
  static String _mutedKey()                        => 'tour_voice_muted';

  Future<SharedPreferences> get _sp async => SharedPreferences.getInstance();

  // ── Global ─────────────────────────────────────────────────────────────────

  Future<bool> isGlobalCompleted() async {
    final sp = await _sp;
    return sp.getBool(_kGlobalCompleted) ?? false;
  }

  Future<void> markGlobalCompleted() async {
    final sp = await _sp;
    await sp.setBool(_kGlobalCompleted, true);
  }

  Future<void> markAllCompleted() async {
    final sp = await _sp;
    const moduleIds = [
      'work_category_entry',
      'site',
      'rate',
      'manpower',
      'team',
      'dpr',
    ];

    await sp.setBool(_kGlobalCompleted, true);
    await sp.setBool('tour_setup_clicked', true);

    for (final moduleId in moduleIds) {
      await sp.setBool(_moduleKey(moduleId), true);
      await sp.remove(_moduleIndexKey(moduleId));
    }
  }

  // ── Per-module ─────────────────────────────────────────────────────────────

  /// Whether a specific module's tour is fully completed.
  Future<bool> isModuleDone(String moduleId) async {
    final sp = await _sp;
    return sp.getBool(_moduleKey(moduleId)) ?? false;
  }

  /// Mark a module as fully completed.
  Future<void> markModuleDone(String moduleId) async {
    final sp = await _sp;
    await sp.setBool(_moduleKey(moduleId), true);
    // Clear step index — no longer needed.
    await sp.remove(_moduleIndexKey(moduleId));
  }

  /// Save partial progress: last completed step index.
  Future<void> saveModuleStepIndex(String moduleId, int stepIndex) async {
    final sp = await _sp;
    await sp.setInt(_moduleIndexKey(moduleId), stepIndex);
  }

  /// Resume from last saved step index (returns 0 if not set).
  Future<int> getModuleStepIndex(String moduleId) async {
    final sp = await _sp;
    return sp.getInt(_moduleIndexKey(moduleId)) ?? 0;
  }

  // ── Voice mute ─────────────────────────────────────────────────────────────

  Future<bool> isMuted() async {
    final sp = await _sp;
    return sp.getBool(_mutedKey()) ?? false;
  }

  Future<void> setMuted(bool muted) async {
    final sp = await _sp;
    await sp.setBool(_mutedKey(), muted);
  }

  // ── Legacy checkpoint helpers (kept for backward compat) ──────────────────
  //
  // The old system used individual booleans per checkpoint.
  // We delegate to the new module-based system so nothing breaks.

  Future<bool> isCompleted() => isGlobalCompleted();
  Future<void> markCompleted() => markGlobalCompleted();

  Future<bool> isSiteDone()      => isModuleDone('site');
  Future<void> markSiteDone()    => markModuleDone('site');

  Future<bool> isRateDone()      => isModuleDone('rate');
  Future<void> markRateDone()    => markModuleDone('rate');

  Future<bool> isManpowerDone()  => isModuleDone('manpower');
  Future<void> markManpowerDone()=> markModuleDone('manpower');

  Future<bool> isTeamDone()      => isModuleDone('team');
  Future<void> markTeamDone()    => markModuleDone('team');

  Future<bool> isDprDone()       => isModuleDone('dpr');
  Future<void> markDprDone()     => markModuleDone('dpr');

  Future<bool> isSetupClicked() async {
    final sp = await _sp;
    return sp.getBool('tour_setup_clicked') ?? false;
  }
  Future<void> markSetupClicked() async {
    final sp = await _sp;
    await sp.setBool('tour_setup_clicked', true);
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> reset() async {
    final sp = await _sp;
    final keys = sp.getKeys().where((k) => k.startsWith('tour_')).toList();
    for (final k in keys) {
      await sp.remove(k);
    }
  }

  Future<void> resetModule(String moduleId) async {
    final sp = await _sp;
    await sp.remove(_moduleKey(moduleId));
    await sp.remove(_moduleIndexKey(moduleId));
  }
}
