import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'workflow_state.dart';
import 'workflow_step.dart';
import 'workflow_preferences.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';

/// Global provider. Consumed by:
///   - ModuleScreenV2 (to show FAB, progress banner)
///   - Each entry screen (to decide post-save navigation)
///   - WorkflowGateScreen (to call startWorkflow)
final workflowControllerProvider =
    StateNotifierProvider<WorkflowController, WorkflowState>(
  (ref) => WorkflowController(ref),
);

class WorkflowController extends StateNotifier<WorkflowState> {
  final Ref _ref;

  WorkflowController(this._ref) : super(WorkflowState.empty);

  // ─── Public API (what other files call) ────────────────────────────────────

  /// Called by WorkflowGateScreen when user taps "Start Workflow".
  /// [steps] comes from WorkflowRegistry.
  /// [workflowId] is a stable string key like 'daily_entry'.
  Future<void> startWorkflow({
    required List<WorkflowStep> steps,
    required String workflowId,
  }) async {
    final newState = WorkflowState(
      isActive: true,
      currentStepIndex: 0,
      completedStepIndices: [],
      skippedStepIndices: [],
      steps: steps,
      workflowId: workflowId,
    );
    state = newState;
    await WorkflowPreferences.save(newState);
  }

  Future<void> advance(BuildContext context) async {
    if (!state.isActive) return;

    final completed = [...state.completedStepIndices, state.currentStepIndex];
    final nextIndex = state.currentStepIndex + 1;
    final isLastStep = nextIndex >= state.steps.length;

    if (isLastStep) {
      // All steps done — update state to show all finished but keep active until they hit "Finish"
      final finalState = state.copyWith(
        completedStepIndices: completed,
      );
      state = finalState;
      await WorkflowPreferences.save(finalState);
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.settings.name == 'workflow-gate');
      }
    } else {
      // Advance to next step index but stay on Hub
      final nextState = state.copyWith(
        completedStepIndices: completed,
        currentStepIndex: nextIndex,
      );
      state = nextState;
      await WorkflowPreferences.save(nextState);

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.settings.name == 'workflow-gate');
      }
    }
  }

  /// Called when user explicitly taps "Skip" on an optional step.
  Future<void> skipCurrentStep() async {
    if (!state.isActive) return;
    if (state.currentStep == null) return;

    final skipped = [...state.skippedStepIndices, state.currentStepIndex];
    final nextIndex = state.currentStepIndex + 1;

    final nextState = state.copyWith(
      skippedStepIndices: skipped,
      currentStepIndex: nextIndex,
    );
    state = nextState;
    await WorkflowPreferences.save(nextState);
  }

  /// Called when user explicitly cancels the workflow from the progress banner.
  Future<void> cancelWorkflow(BuildContext context) async {
    state = WorkflowState.empty;
    await WorkflowPreferences.clear();
    if (context.mounted) context.go('/select-module');
  }

  /// Called from ModuleScreenV2.didChangeDependencies() (or initState).
  /// If a saved workflow exists (app was killed mid-flow), offer resume.
  Future<void> tryRestoreSession() async {
    final saved = await WorkflowPreferences.load();
    if (saved != null && saved.isActive) {
      state = saved;
    }
  }

  /// Called when user clicks "Finish" on the Gate Screen after all steps addressed.
  Future<void> finishWorkflow(BuildContext context) async {
    state = WorkflowState.empty;
    await WorkflowPreferences.clear();
    if (context.mounted) context.go('/select-module');
  }
}
