import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/tour/domain/tour_presistent.dart';
import 'package:untitled2/features/tour/domain/tour_registery.dart';
import 'package:untitled2/features/tour/domain/tour_step_model.dart';
enum TourCheckpoint {
  site,
  rate,
  manpower,
  team,
  dpr, // 👈 NEW
}


class TourState {
  final TourStatus status;
  final bool buddyVisible;
  final int index;

  const TourState({
    required this.status,
    required this.buddyVisible,
    required this.index,
  });

  TourState copyWith({
    TourStatus? status,
    bool? buddyVisible,
    int? index,
  }) {
    return TourState(
      status: status ?? this.status,
      buddyVisible: buddyVisible ?? this.buddyVisible,
      index: index ?? this.index,
    );
  }

  static const idle = TourState(status: TourStatus.idle, buddyVisible: true, index: 0);
}

final tourPersistenceProvider = Provider<TourPersistence>((ref) {
  return TourPersistence();
});

final tourControllerProvider =
StateNotifierProvider<TourController, TourState>((ref) {
  return TourController(ref);
});

class TourController extends StateNotifier<TourState> {
  final Ref ref;

  TourController(this.ref) : super(TourState.idle);

  List<TourStep> get steps => TourRegistry.onboarding;

  bool get isRunning => state.status == TourStatus.running;
  bool get isPaused => state.status == TourStatus.paused;

  TourStep? get currentStep {
    if (!isRunning) return null;
    if (state.index < 0 || state.index >= steps.length) return null;
    return steps[state.index];
  }

  Future<void> autoStartIfFirstTime() async {
    final completed = await ref.read(tourPersistenceProvider).isCompleted();
    print("🫡🫡🫡🫡 checking/*/");
    if (!completed) {
      start();
    }



  }

  void start() {
    print("🫡🫡🫡🫡 running");
    state = state.copyWith(status: TourStatus.running, index: 0, buddyVisible: true);
  }

  void pause() {
    if (!isRunning) return;
    state = state.copyWith(status: TourStatus.paused);
  }

  void resume() {
    if (!isPaused) return;
    state = state.copyWith(status: TourStatus.running);
  }

  void hideBuddy() => state = state.copyWith(buddyVisible: false);
  void showBuddy() => state = state.copyWith(buddyVisible: true);

  Future<void> skip() async {
    await finish();
  }
  void syncToRoute(String currentRoute) {
    if (!isRunning) return;

    final idx = steps.indexWhere((s) => _matchRoute(s.route, currentRoute));
    if (idx == -1) return;

    if (idx != state.index) {
      state = state.copyWith(index: idx);
      debugPrint("✅ Tour synced to route=$currentRoute step=${steps[idx].id}");
    }
  }

  bool _matchRoute(String stepRoute, String currentRoute) {
    if (stepRoute == currentRoute) return true;

    // /site-list/:module matches /site-list/site
    final sp = stepRoute.split('/');
    final cp = currentRoute.split('/');
    if (sp.length != cp.length) return false;

    for (int i = 0; i < sp.length; i++) {
      if (sp[i].startsWith(':')) continue;
      if (sp[i] != cp[i]) return false;
    }
    return true;
  }


  Future<void> finish() async {
    state = state.copyWith(status: TourStatus.completed, index: 0);
    await ref.read(tourPersistenceProvider).markCompleted();
    // set back to idle after done
    state = TourState.idle;
  }

  void goToStepIndex(int idx) {
    if (idx < 0 || idx >= steps.length) return;
    state = state.copyWith(status: TourStatus.running, index: idx);
  }

  Future<void> next() async {
    if (!isRunning) return;

    final nextIndex = state.index + 1;
    if (nextIndex >= steps.length) {
      await finish();
      return;
    }
    state = state.copyWith(index: nextIndex);
  }

  Future<void> replay() async {
    await ref.read(tourPersistenceProvider).reset();
    start();
  }
  Future<TourCheckpoint?> nextCheckpoint() async {
    final persistence = ref.read(tourPersistenceProvider);

    if (await persistence.isCompleted()) return null;

    if (!await persistence.isSiteDone()) return TourCheckpoint.site;
    if (!await persistence.isRateDone()) return TourCheckpoint.rate;
    if (!await persistence.isManpowerDone()) return TourCheckpoint.manpower;
    if (!await persistence.isTeamDone()) return TourCheckpoint.team;

    // if reached here => all completed
    await persistence.markCompleted();
    return null;
  }

}
