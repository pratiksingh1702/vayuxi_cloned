import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'workflow_state.dart';
import '../registry/workflow_registry.dart';

/// Persists WorkflowState to SharedPreferences.
/// Uses the same pattern as the existing ModulePreferences.
///
/// Only the indices and workflowId are stored (steps are re-hydrated
/// from WorkflowRegistry using the stored workflowId — no duplication).
class WorkflowPreferences {
  static const _keyIsActive       = 'wf_is_active';
  static const _keyWorkflowId     = 'wf_workflow_id';
  static const _keyCurrentStep    = 'wf_current_step';
  static const _keyCompleted      = 'wf_completed_steps';   // stored as JSON list
  static const _keySkipped        = 'wf_skipped_steps';     // stored as JSON list

  /// Persists the current workflow state. Called on every state transition.
  static Future<void> save(WorkflowState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsActive, s.isActive);
    await prefs.setString(_keyWorkflowId, s.workflowId);
    await prefs.setInt(_keyCurrentStep, s.currentStepIndex);
    await prefs.setString(_keyCompleted, jsonEncode(s.completedStepIndices));
    await prefs.setString(_keySkipped, jsonEncode(s.skippedStepIndices));
  }

  /// Restores a WorkflowState from SharedPreferences.
  /// Returns null if no session was saved or the saved workflowId is unknown.
  static Future<WorkflowState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_keyIsActive) ?? false;
    if (!isActive) return null;

    final workflowId = prefs.getString(_keyWorkflowId) ?? '';
    final steps = WorkflowRegistry.stepsFor(workflowId);
    if (steps == null) return null; // unknown workflow — discard

    final currentStep  = prefs.getInt(_keyCurrentStep) ?? 0;
    final completedRaw = prefs.getString(_keyCompleted) ?? '[]';
    final skippedRaw   = prefs.getString(_keySkipped) ?? '[]';

    final completed = List<int>.from(jsonDecode(completedRaw));
    final skipped   = List<int>.from(jsonDecode(skippedRaw));

    return WorkflowState(
      isActive: true,
      currentStepIndex: currentStep,
      completedStepIndices: completed,
      skippedStepIndices: skipped,
      steps: steps,
      workflowId: workflowId,
    );
  }

  /// Clears all saved workflow data. Called when workflow ends or is cancelled.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsActive);
    await prefs.remove(_keyWorkflowId);
    await prefs.remove(_keyCurrentStep);
    await prefs.remove(_keyCompleted);
    await prefs.remove(_keySkipped);
  }
}
