import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tour_analytics.dart';
import 'tour_models.dart';
import 'tour_storage.dart';
import '../definitions/module_screen_tours.dart';

class AppTourController extends StateNotifier<AppTourState> {
  final List<AppTourDefinition> _definitions;
  final Set<String> _allowedTourIds;
  final AppTourStorage _storage;
  final AppTourAnalytics _analytics;
  AppTourDefinition? _runtimeTour;

  AppTourController({
    required List<AppTourDefinition> definitions,
    required Set<String> allowedTourIds,
    required AppTourStorage storage,
    required AppTourAnalytics analytics,
  })  : _definitions = definitions,
        _allowedTourIds = allowedTourIds,
        _storage = storage,
        _analytics = analytics,
        super(AppTourState.idle);

  AppTourDefinition? get activeTour {
    final activeId = state.activeTourId;
    if (activeId == null) return null;
    if (_runtimeTour?.id == activeId) return _runtimeTour;
    for (final tour in _definitions) {
      if (tour.id == activeId) return tour;
    }
    return null;
  }

  AppTourStep? get currentStep {
    final tour = activeTour;
    if (tour == null) return null;
    if (state.stepIndex < 0 || state.stepIndex >= tour.steps.length) {
      return null;
    }
    return tour.steps[state.stepIndex];
  }

  Future<bool> maybeStartWelcome() {
    return maybeStartTour(ModuleScreenTours.welcomeId);
  }

  Future<bool> maybeStartTabTour(int tabIndex) {
    return maybeStartTour(ModuleScreenTours.tabTourId(tabIndex));
  }

  Future<bool> maybeStartRuntimeTour(
    AppTourDefinition definition, {
    required String policyTourId,
  }) async {
    if (state.status == AppTourStatus.running) return false;
    if (!_allowedTourIds.contains(policyTourId)) return false;
    if (await _storage.isDone(definition.id)) return false;
    _runtimeTour = definition;
    await _startDefinition(definition, AppTourTrigger.automatic);
    return true;
  }

  Future<bool> maybeStartTour(String tourId) async {
    if (state.status == AppTourStatus.running) return false;
    if (!_allowedTourIds.contains(tourId)) return false;
    if (await _storage.isDone(tourId)) return false;
    await _startTour(tourId, AppTourTrigger.automatic);
    return true;
  }

  Future<void> replayTour(String tourId) async {
    if (!_allowedTourIds.contains(tourId)) return;
    await _storage.resetTour(tourId);
    await _startTour(tourId, AppTourTrigger.replay);
  }

  Future<void> resetAllAndStart() async {
    final firstTourId = _definitions.first.id;
    await _storage.resetAllPhase1();
    await _startTour(firstTourId, AppTourTrigger.replay);
  }

  Future<void> _startTour(String tourId, AppTourTrigger trigger) async {
    final definition = _definitions.firstWhere((tour) => tour.id == tourId);
    _runtimeTour = null;
    await _startDefinition(definition, trigger);
  }

  Future<void> _startDefinition(
    AppTourDefinition definition,
    AppTourTrigger trigger,
  ) async {
    final savedIndex = await _storage.stepIndex(definition.id);
    final index = savedIndex >= definition.steps.length ? 0 : savedIndex;
    state = AppTourState(
      status: AppTourStatus.running,
      activeTourId: definition.id,
      stepIndex: index,
      trigger: trigger,
    );
    _analytics.started(definition.id);
    final step = currentStep;
    if (step != null) {
      _analytics.stepped(definition.id, step.id, index);
    }
  }

  Future<void> next() async {
    final tour = activeTour;
    if (tour == null) return;
    final nextIndex = state.stepIndex + 1;
    if (nextIndex >= tour.steps.length) {
      await finish();
      return;
    }
    await _storage.saveStepIndex(tour.id, nextIndex);
    state = state.copyWith(stepIndex: nextIndex);
    final step = currentStep;
    if (step != null) {
      _analytics.stepped(tour.id, step.id, nextIndex);
    }
  }

  Future<void> back() async {
    final tour = activeTour;
    if (tour == null || state.stepIndex == 0) return;
    final previousIndex = state.stepIndex - 1;
    await _storage.saveStepIndex(tour.id, previousIndex);
    state = state.copyWith(stepIndex: previousIndex);
  }

  Future<void> skip() async {
    final tour = activeTour;
    final step = currentStep;
    if (tour != null && step != null) {
      _analytics.skipped(tour.id, step.id);
    }
    await finish();
  }

  Future<void> finish() async {
    final tour = activeTour;
    if (tour == null) {
      state = AppTourState.idle;
      return;
    }
    await _storage.markDone(tour.id);
    _analytics.completed(tour.id);
    state = AppTourState(
      status: AppTourStatus.completed,
      activeTourId: tour.id,
      stepIndex: tour.steps.length - 1,
      trigger: state.trigger,
    );
    state = AppTourState.idle;
  }

  void cancelActiveTour({String? onlyTourId}) {
    final tour = activeTour;
    if (tour == null) {
      state = AppTourState.idle;
      return;
    }
    if (onlyTourId != null && tour.id != onlyTourId) return;
    if (_runtimeTour?.id == tour.id) {
      _runtimeTour = null;
    }
    state = AppTourState.idle;
  }
}
