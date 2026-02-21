import 'package:shared_preferences/shared_preferences.dart';

class TourPersistence {
  static const _kTourCompleted = "tour_completed";

  static const _kSiteDone = "tour_site_done";
  static const _kRateDone = "tour_rate_done";
  static const _kManpowerDone = "tour_manpower_done";
  static const _kTeamDone = "tour_team_done";
  static const _kDprDone = "tour_dpr_done";


  Future<SharedPreferences> get _sp async =>
      await SharedPreferences.getInstance();

  Future<bool> isCompleted() async {
    final sp = await _sp;
    return sp.getBool(_kTourCompleted) ?? false;
  }
  static const _kSetupClicked = "tour_setup_clicked";

  Future<bool> isSetupClicked() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kSetupClicked) ?? false;
  }
  Future<bool> isDprDone() async {
    final sp = await _sp;
    return sp.getBool(_kDprDone) ?? false;
  }
  Future<void> markDprDone() async {
    final sp = await _sp;
    await sp.setBool(_kDprDone, true);
  }

  Future<void> markSetupClicked() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSetupClicked, true);
  }


  Future<void> markCompleted() async {
    final sp = await _sp;
    await sp.setBool(_kTourCompleted, true);
  }

  Future<void> reset() async {
    final sp = await _sp;
    await sp.remove(_kTourCompleted);
    await sp.remove(_kSiteDone);
    await sp.remove(_kRateDone);
    await sp.remove(_kManpowerDone);
    await sp.remove(_kTeamDone);
    await sp.remove(_kDprDone);

  }

  // ---- checkpoints ----

  Future<bool> isSiteDone() async {
    final sp = await _sp;
    return sp.getBool(_kSiteDone) ?? false;
  }

  Future<void> markSiteDone() async {
    final sp = await _sp;
    await sp.setBool(_kSiteDone, true);
  }

  Future<bool> isRateDone() async {
    final sp = await _sp;
    return sp.getBool(_kRateDone) ?? false;
  }

  Future<void> markRateDone() async {
    final sp = await _sp;
    await sp.setBool(_kRateDone, true);
  }

  Future<bool> isManpowerDone() async {
    final sp = await _sp;
    return sp.getBool(_kManpowerDone) ?? false;
  }

  Future<void> markManpowerDone() async {
    final sp = await _sp;
    await sp.setBool(_kManpowerDone, true);
  }

  Future<bool> isTeamDone() async {
    final sp = await _sp;
    return sp.getBool(_kTeamDone) ?? false;
  }

  Future<void> markTeamDone() async {
    final sp = await _sp;
    await sp.setBool(_kTeamDone, true);
  }

  Future<bool> allDone() async {
    return await isSiteDone() &&
        await isRateDone() &&
        await isManpowerDone() &&
        await isTeamDone();
  }
}
