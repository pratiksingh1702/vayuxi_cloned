import '../domain/workflow_step.dart';
import 'daily_entry_workflow.dart';

/// Central lookup table for all workflow step lists.
class WorkflowRegistry {
  static const String dailyEntryId = 'daily_entry';

  static final Map<String, List<WorkflowStep>> _registry = {
    dailyEntryId: DailyEntryWorkflow.steps,
  };

  /// Returns the step list for [workflowId], or null if unknown.
  static List<WorkflowStep>? stepsFor(String workflowId) {
    return _registry[workflowId];
  }
}
