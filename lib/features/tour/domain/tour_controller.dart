// lib/features/tour/domain/tour_controller.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// TOUR CONTROLLER — the Engine's state machine
// ─────────────────────────────────────────────────────────────────────────────
//
// Responsibilities:
//  • Holds the active TourModule and current step index.
//  • Listens for TourEvents emitted from anywhere in the app.
//  • Auto-advances when the correct event arrives (task-driven).
//  • Triggers TTS via VoiceAssistantService on step change.
//  • Manages a hint timer: if user is idle too long, shows hint.
//  • Persists per-module progress via TourPersistence.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tour_module.dart';
import 'tour_presistent.dart';
import 'tour_step_model.dart';
import 'voice_assistant_service.dart';

export 'tour_step_model.dart' show TourStatus, TourStep, BuddyWaitMode;

// ─────────────────────────────────────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────────────────────────────────────

class TourState {
  final TourStatus status;
  final bool buddyVisible;
  final int stepIndex;
  final bool showHint;
  final bool isMuted;
  final String? activeModuleId;

  const TourState({
    required this.status,
    required this.buddyVisible,
    required this.stepIndex,
    required this.showHint,
    required this.isMuted,
    this.activeModuleId,
  });

  static const idle = TourState(
    status: TourStatus.idle,
    buddyVisible: false,
    stepIndex: 0,
    showHint: false,
    isMuted: false,
  );

  TourState copyWith({
    TourStatus? status,
    bool? buddyVisible,
    int? stepIndex,
    bool? showHint,
    bool? isMuted,
    String? activeModuleId,
  }) {
    return TourState(
      status: status ?? this.status,
      buddyVisible: buddyVisible ?? this.buddyVisible,
      stepIndex: stepIndex ?? this.stepIndex,
      showHint: showHint ?? this.showHint,
      isMuted: isMuted ?? this.isMuted,
      activeModuleId: activeModuleId ?? this.activeModuleId,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGACY CHECKPOINT ENUM (kept for any code that still references it)
// ─────────────────────────────────────────────────────────────────────────────
enum TourCheckpoint { site, rate, manpower, team, dpr }

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final tourPersistenceProvider = Provider<TourPersistence>((ref) {
  return TourPersistence();
});

final tourControllerProvider =
    StateNotifierProvider<TourController, TourState>((ref) {
  return TourController(ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class TourController extends StateNotifier<TourState> {
  final Ref _ref;

  TourModule? _activeModule;
  Timer? _hintTimer;

  TourController(this._ref) : super(TourState.idle);

  // ── Accessors ──────────────────────────────────────────────────────────────

  TourModule? get activeModule => _activeModule;

  bool get isRunning => state.status == TourStatus.running;
  bool get isPaused => state.status == TourStatus.paused;

  List<TourStep> get steps => _activeModule?.steps ?? const [];
  int get totalSteps => steps.length;

  TourStep? get currentStep {
    if (!isRunning && !isPaused) return null;
    if (state.stepIndex < 0 || state.stepIndex >= steps.length) return null;
    return steps[state.stepIndex];
  }

  // ── Start / Stop ───────────────────────────────────────────────────────────

  /// Start a specific module's tour.
  /// Resumes from where the user left off (if partially completed).
  Future<void> startModule(TourModule module) async {
    _cancelHintTimer();
    _activeModule = module;

    final persistence = _ref.read(tourPersistenceProvider);

    // Don't restart a completed module (unless replayed).
    if (await persistence.isModuleDone(module.id)) {
      debugPrint('🎓 TourController: module ${module.id} already completed');
      return;
    }

    // Restore mute preference.
    final muted = await persistence.isMuted();

    // Resume from partial progress.
    final savedIndex = await persistence.getModuleStepIndex(module.id);
    final resumeIndex = (savedIndex < module.steps.length) ? savedIndex : 0;

    debugPrint('🔍 TourController.startModule: module=${module.id}, savedIndex=$savedIndex, resumeIndex=$resumeIndex, totalSteps=${module.steps.length}');

    state = TourState(
      status: TourStatus.running,
      buddyVisible: true,
      stepIndex: resumeIndex,
      showHint: false,
      isMuted: muted,
      activeModuleId: module.id,
    );

    debugPrint(
        '▶️ TourController: started module=${module.id} step=$resumeIndex step_id=${module.steps[resumeIndex].id} route=${module.steps[resumeIndex].route}');
    await _onStepActivated();
  }

  /// Start a module only if it hasn't been completed yet.
  Future<void> startModuleIfNeeded(TourModule module) async {
    final persistence = _ref.read(tourPersistenceProvider);
    if (await persistence.isModuleDone(module.id)) return;
    await startModule(module);
  }

  Future<void> pause() async {
    if (!isRunning) return;
    _cancelHintTimer();
    await _ref.read(voiceAssistantProvider).stop();
    state = state.copyWith(status: TourStatus.paused);
  }

  Future<void> resume() async {
    if (!isPaused) return;
    state = state.copyWith(status: TourStatus.running);
    await _onStepActivated();
  }

  // ── Event System ───────────────────────────────────────────────────────────

  /// Called by any screen/service when a user-task is completed.
  ///
  /// Example:
  /// ```dart
  /// ref.read(tourControllerProvider.notifier).onEvent(TourEvents.addSiteTapped);
  /// ```
  Future<void> onEvent(String eventId) async {
    if (!isRunning) return;

    final step = currentStep;
    if (step == null) return;

    debugPrint(
        '📡 TourController: received event=$eventId, required=${step.requiredEvent}');

    if (step.requiredEvent == eventId) {
      debugPrint('✅ TourController: event matched — advancing');
      await _advance();
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Called by GlobalTourOverlay or manually — skips current step.
  Future<void> next() async {
    if (!isRunning) return;
    await _advance();
  }

  Future<void> _advance() async {
    _cancelHintTimer();
    final nextIndex = state.stepIndex + 1;

    if (nextIndex >= steps.length) {
      await _finishModule();
      return;
    }

    // Save partial progress.
    await _ref
        .read(tourPersistenceProvider)
        .saveModuleStepIndex(_activeModule!.id, nextIndex);

    state = state.copyWith(stepIndex: nextIndex, showHint: false);
    debugPrint('⏭ TourController: moved to step $nextIndex');
    await _onStepActivated();
  }

  Future<void> back() async {
    if (!isRunning) return;
    _cancelHintTimer();
    final prevIndex = state.stepIndex - 1;
    if (prevIndex < 0) return;

    await _ref
        .read(tourPersistenceProvider)
        .saveModuleStepIndex(_activeModule!.id, prevIndex);

    state = state.copyWith(stepIndex: prevIndex, showHint: false);
    await _onStepActivated();
  }

  // ── Skip / Finish ──────────────────────────────────────────────────────────

  Future<void> skip() async {
    _cancelHintTimer();
    await _ref.read(voiceAssistantProvider).stop();
    await _finishModule();
  }

  Future<void> _finishModule() async {
    if (_activeModule == null) return;

    await _ref.read(tourPersistenceProvider).markModuleDone(_activeModule!.id);

    await _ref.read(voiceAssistantProvider).stop();
    state = state.copyWith(
      status: TourStatus.completed,
      buddyVisible: false,
      showHint: false,
    );

    debugPrint('🎉 TourController: module ${_activeModule!.id} completed!');

    // Tiny delay, then go idle so GlobalTourOverlay shows completion screen.
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if all known modules are completed → mark global done.
    final persistence = _ref.read(tourPersistenceProvider);
    final siteOk = await persistence.isModuleDone('site');
    if (siteOk) {
      // Add more module checks as you build them out.
      await persistence.markGlobalCompleted();
    }

    state = TourState.idle;
    _activeModule = null;
  }

  // ── Replay ─────────────────────────────────────────────────────────────────

  Future<void> replayModule(TourModule module) async {
    await _ref.read(tourPersistenceProvider).resetModule(module.id);
    await startModule(module);
  }

  /// Hard reset all tour flags and runtime state, then start module from step 0.
  Future<void> resetAllAndStartModule(TourModule module) async {
    debugPrint('🔄 TourController: RESET ALL - clearing all tour state');
    _cancelHintTimer();
    await _ref.read(voiceAssistantProvider).stop();

    _activeModule = null;
    state = TourState.idle;

    await _ref.read(tourPersistenceProvider).reset();
    await _ref.read(tourPersistenceProvider).saveModuleStepIndex(module.id, 0);

    debugPrint('🔄 TourController: saved step=0 for module=${module.id}, now calling startModule');
    await startModule(module);
  }

  /// Hard reset only one module and runtime state, then start from step 0.
  Future<void> resetModuleAndStartFromBeginning(TourModule module) async {
    debugPrint('🔄 TourController: RESET MODULE ${module.id} - clearing module-specific state');
    _cancelHintTimer();
    await _ref.read(voiceAssistantProvider).stop();

    _activeModule = null;
    state = TourState.idle;

    await _ref.read(tourPersistenceProvider).resetModule(module.id);
    final afterReset = await _ref.read(tourPersistenceProvider).getModuleStepIndex(module.id);
    debugPrint('🔄 TourController: after resetModule, stepIndex=$afterReset');
    
    await _ref.read(tourPersistenceProvider).saveModuleStepIndex(module.id, 0);
    final afterSave = await _ref.read(tourPersistenceProvider).getModuleStepIndex(module.id);
    debugPrint('🔄 TourController: after saveModuleStepIndex(0), stepIndex=$afterSave');

    debugPrint('🔄 TourController: now calling startModule');
    await startModule(module);
  }

  // ── Voice ──────────────────────────────────────────────────────────────────

  Future<void> replayVoice() async {
    final step = currentStep;
    if (step == null) return;
    await _ref.read(voiceAssistantProvider).replay(step.ttsText);
  }

  Future<bool> toggleMute() async {
    final voice = _ref.read(voiceAssistantProvider);
    final newMuted = await voice.toggleMute();
    await _ref.read(tourPersistenceProvider).setMuted(newMuted);
    state = state.copyWith(isMuted: newMuted);
    return newMuted;
  }

  // ── Buddy visibility ───────────────────────────────────────────────────────

  void hideBuddy() => state = state.copyWith(buddyVisible: false);
  void showBuddy() => state = state.copyWith(buddyVisible: true);

  // ── Route Sync (GoRouter listener) ────────────────────────────────────────

  /// Called by GoRouter listener on every route change.
  /// If tour is running and user ended up on the right screen, show Buddy.
  /// If on wrong screen, keep Buddy hidden so it doesn't stack confusingly.
  void syncToRoute(String currentRoute) {
    if (!isRunning) return;
    final step = currentStep;
    if (step == null) return;

    final onCorrectRoute = _matchRoute(step.route, currentRoute);
    if (onCorrectRoute && !state.buddyVisible) {
      state = state.copyWith(buddyVisible: true);
    } else if (!onCorrectRoute && state.buddyVisible) {
      state = state.copyWith(buddyVisible: false);
    }
  }

  bool _matchRoute(String stepRoute, String currentRoute) {
    if (stepRoute == currentRoute) return true;
    final sp = stepRoute.split('/');
    final cp = currentRoute.split('/');
    if (sp.length != cp.length) return false;
    for (int i = 0; i < sp.length; i++) {
      if (sp[i].startsWith(':')) continue;
      if (sp[i] != cp[i]) return false;
    }
    return true;
  }

  // ── Internal: step activation ──────────────────────────────────────────────

  Future<void> _onStepActivated() async {
    final step = currentStep;
    if (step == null) return;

    // Speak the step's message.
    if (!state.isMuted) {
      await _ref.read(voiceAssistantProvider).speak(step.ttsText);
    }

    // Arm the hint timer.
    if (step.hintMessage != null) {
      _startHintTimer(step);
    }
  }

  void _startHintTimer(TourStep step) {
    _cancelHintTimer();
    _hintTimer = Timer(Duration(seconds: step.hintDelaySeconds), () async {
      if (!mounted) return;
      state = state.copyWith(showHint: true);
      if (!state.isMuted && step.hintMessage != null) {
        await _ref.read(voiceAssistantProvider).speak(step.hintMessage!);
      }
      debugPrint('💡 TourController: hint shown for step ${step.id}');
    });
  }

  void _cancelHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = null;
  }

  @override
  void dispose() {
    _cancelHintTimer();
    super.dispose();
  }

  // ── Legacy helpers (for backward compat with module_screen.dart) ──────────

  Future<TourCheckpoint?> nextCheckpoint() async {
    final p = _ref.read(tourPersistenceProvider);
    if (await p.isCompleted()) return null;
    if (!await p.isSiteDone()) return TourCheckpoint.site;
    if (!await p.isRateDone()) return TourCheckpoint.rate;
    if (!await p.isManpowerDone()) return TourCheckpoint.manpower;
    if (!await p.isTeamDone()) return TourCheckpoint.team;
    await p.markCompleted();
    return null;
  }

  Future<void> autoStartIfFirstTime() async {
    final completed =
        await _ref.read(tourPersistenceProvider).isGlobalCompleted();
    if (!completed) {
      // Will be replaced once we move module_screen to modular approach.
      state = state.copyWith(status: TourStatus.running, buddyVisible: true);
    }
  }

  /// Legacy — kept so any existing call site still compiles.
  void start() {
    state = state.copyWith(
      status: TourStatus.running,
      stepIndex: 0,
      buddyVisible: true,
    );
  }

  Future<void> replay() async {
    await _ref.read(tourPersistenceProvider).reset();
    start();
  }
}
