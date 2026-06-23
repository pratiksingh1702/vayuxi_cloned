import 'workflow_step.dart';

/// The complete immutable state of the workflow engine.
class WorkflowState {
  /// Whether a workflow session is currently in progress.
  final bool isActive;

  /// Index of the step currently being filled (0-based).
  final int currentStepIndex;

  /// Indices of steps the user has successfully saved.
  final List<int> completedStepIndices;

  /// Indices of steps the user explicitly skipped.
  final List<int> skippedStepIndices;

  /// The ordered list of steps for this workflow session.
  /// Set when startWorkflow() is called. Empty when no session is active.
  final List<WorkflowStep> steps;

  /// Identifier for which workflow is active (e.g. 'daily_entry', 'setup').
  /// Used for persistence keys and future analytics.
  final String workflowId;

  const WorkflowState({
    this.isActive = false,
    this.currentStepIndex = 0,
    this.completedStepIndices = const [],
    this.skippedStepIndices = const [],
    this.steps = const [],
    this.workflowId = '',
  });

  /// True when every step is either completed or skipped.
  bool get isComplete {
    if (steps.isEmpty) return false;
    return (completedStepIndices.length + skippedStepIndices.length) >=
        steps.length;
  }

  /// Progress from 0.0 to 1.0 for the LinearProgressIndicator.
  double get progressFraction {
    if (steps.isEmpty) return 0.0;
    return (completedStepIndices.length + skippedStepIndices.length) /
        steps.length;
  }

  /// The step currently being shown to the user. Null if workflow is not active.
  WorkflowStep? get currentStep {
    if (!isActive || steps.isEmpty) return null;
    if (currentStepIndex >= steps.length) return null;
    return steps[currentStepIndex];
  }

  /// Human-readable label: "Step 2 of 4"
  String get stepLabel {
    if (!isActive) return '';
    return 'Step ${currentStepIndex + 1} of ${steps.length}';
  }

  WorkflowState copyWith({
    bool? isActive,
    int? currentStepIndex,
    List<int>? completedStepIndices,
    List<int>? skippedStepIndices,
    List<WorkflowStep>? steps,
    String? workflowId,
  }) {
    return WorkflowState(
      isActive: isActive ?? this.isActive,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      completedStepIndices: completedStepIndices ?? this.completedStepIndices,
      skippedStepIndices: skippedStepIndices ?? this.skippedStepIndices,
      steps: steps ?? this.steps,
      workflowId: workflowId ?? this.workflowId,
    );
  }

  /// Returns a blank/reset state. Used after workflow ends or is cancelled.
  static const empty = WorkflowState();
}
