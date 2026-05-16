# Daily Workflow Mode — Full Implementation Plan

> **For AI Agent**: This document is a complete, self-contained implementation guide. Read every section before writing a single line of code. The goal is zero existing UI regressions and a fully scalable workflow engine.

---

## Table of Contents

1. [Overview & Goals](#overview--goals)
2. [Core Architectural Decisions](#core-architectural-decisions)
3. [File Structure](#file-structure)
4. [Data Models](#data-models)
5. [WorkflowController](#workflowcontroller)
6. [WorkflowPreferences (Persistence)](#workflowpreferences-persistence)
7. [WorkflowRegistry (Step Definitions)](#workflowregistry-step-definitions)
8. [Gate Screen (Intro)](#gate-screen-intro)
9. [ModuleScreenV2 Changes](#modulescreenv2-changes)
10. [Per-Screen Navigation Change](#per-screen-navigation-change)
11. [Completion Return](#completion-return)
12. [Future Extensibility](#future-extensibility)
13. [What Must NOT Change](#what-must-not-change)
14. [Implementation Checklist](#implementation-checklist)

---

## Overview & Goals

### What this feature is

A **guided sequential entry mode** for daily data entry. Instead of a user randomly tapping modules one by one, they tap a "+" FAB, see a gate screen explaining the full flow, tap **Start**, and are walked through:

1. Attendance → 2. DPR Entry → 3. Expense → 4. Inventory

After saving on each screen, the app automatically navigates to the next step. After the last step, the app returns to `ModuleScreenV2`.

### What this feature is NOT

- It is NOT a new set of screens.
- It is NOT an overlay or extra buttons added to existing entry screens.
- It is NOT a breaking change to the normal single-module entry flow.

### Key constraint

> **The only change to existing entry screens is: if a workflow is currently active, after a successful save, push the next route instead of popping. That is the ONLY modification to those files.**

---

## Core Architectural Decisions

### Decision 1: WorkflowController is a global Riverpod StateNotifier

All workflow state lives in one place. Any screen that needs to know "am I inside a workflow?" just reads this provider. No prop-drilling, no static variables.

### Decision 2: Existing screens detect workflow mode via a provider

Each entry screen (attendance, DPR, expense, inventory) watches `workflowControllerProvider`. After a successful save, it checks:

```dart
final wf = ref.read(workflowControllerProvider);
if (wf.isActive) {
  await ref.read(workflowControllerProvider.notifier).advance(context);
} else {
  context.pop(); // existing behaviour, untouched
}
```

This means **no new buttons, no overlays, no UI additions to entry screens**. The only change is the post-save navigation branch.

### Decision 3: WorkflowStep is a config object, not a hardcoded list

Steps are defined in a `WorkflowRegistry` file. Adding a new step = adding one object to a list. No changes to controller logic needed.

### Decision 4: The gate screen is a full dedicated route

Not a bottom sheet. A proper screen pushed via `context.push('/workflow-gate')`. This makes it easy to add animations, per-step ETAs, and role-based customisation later.

### Decision 5: Persistence via SharedPreferences on every state change

If user kills the app mid-workflow, on next open the controller reads saved state and offers resume. This uses the same SharedPreferences pattern as existing `ModulePreferences`.

### Decision 6: `advance()` is the single method all screens call

It encapsulates: mark current step done → save to prefs → push next route or return to module screen. Screens don't know what comes next. The controller decides.

---

## File Structure

```
lib/
└── features/
    └── workflow/
        ├── domain/
        │   ├── workflow_step.dart          ← data model for one step
        │   ├── workflow_state.dart         ← immutable state class
        │   ├── workflow_controller.dart    ← StateNotifier
        │   └── workflow_preferences.dart  ← SharedPreferences persistence
        ├── registry/
        │   ├── workflow_registry.dart      ← all step lists live here
        │   └── daily_entry_workflow.dart   ← daily entry step definitions
        └── screens/
            └── workflow_gate_screen.dart   ← the intro/gate screen
```

All other changes are additions to existing files (ModuleScreenV2, each entry screen's save handler). No existing files are deleted or restructured.

---

## Data Models

### File: `lib/features/workflow/domain/workflow_step.dart`

```dart
import 'package:flutter/material.dart';

/// A single step in a workflow.
/// 
/// Designed to be immutable and config-driven.
/// Adding a new step = adding a new WorkflowStep instance to a registry list.
class WorkflowStep {
  /// Human-readable title shown in the gate screen and progress tracker.
  final String title;

  /// Short description shown in the gate screen step list.
  final String description;

  /// The GoRouter route to push when this step becomes active.
  final String route;

  /// Icon shown in the progress tracker and gate screen.
  final IconData icon;

  /// Color used for the icon background in progress tracker.
  final Color color;

  /// If true, a "Skip" option is shown during this step.
  final bool isOptional;

  /// Estimated time in minutes, shown in the gate screen.
  final int estimatedMinutes;

  const WorkflowStep({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
    this.isOptional = false,
    this.estimatedMinutes = 2,
  });
}
```

---

### File: `lib/features/workflow/domain/workflow_state.dart`

```dart
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
```

---

## WorkflowController

### File: `lib/features/workflow/domain/workflow_controller.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'workflow_state.dart';
import 'workflow_step.dart';
import 'workflow_preferences.dart';
import '../../../features/modules/all_Modules/site_Details/providers/siteProvider.dart';
// import your other existing providers as needed

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

  /// Called by each entry screen AFTER a successful save.
  /// Marks current step as complete, then pushes the next route OR
  /// navigates back to ModuleScreenV2 if this was the last step.
  ///
  /// [context] is the BuildContext of the calling screen.
  Future<void> advance(BuildContext context) async {
    if (!state.isActive) return;

    final completed = [...state.completedStepIndices, state.currentStepIndex];
    final nextIndex = state.currentStepIndex + 1;
    final isLastStep = nextIndex >= state.steps.length;

    if (isLastStep) {
      // All steps done — reset state and return to module screen
      final finalState = state.copyWith(
        completedStepIndices: completed,
        isActive: false,
      );
      state = finalState;
      await WorkflowPreferences.clear();
      // Pop all pushed routes back to ModuleScreenV2
      // ModuleScreenV2 will detect completion and show a summary toast
      if (context.mounted) context.go('/modules'); // adjust to your actual home route
    } else {
      // Advance to next step
      final nextState = state.copyWith(
        completedStepIndices: completed,
        currentStepIndex: nextIndex,
      );
      state = nextState;
      await WorkflowPreferences.save(nextState);

      // Push the next step's route, passing the same site/team context
      final selectedSite = _ref.read(siteDropdownValueProvider);
      final selectedTeam = _ref.read(teamDropdownValueProvider);

      if (context.mounted) {
        context.push(state.steps[nextIndex].route, extra: {
          'selectedSite': selectedSite,
          'selectedTeam': selectedTeam,
        });
      }
    }
  }

  /// Called when user explicitly taps "Skip" on an optional step.
  Future<void> skipCurrentStep(BuildContext context) async {
    if (!state.isActive) return;
    if (!state.currentStep!.isOptional) return; // guard: cannot skip required steps

    final skipped = [...state.skippedStepIndices, state.currentStepIndex];
    final nextIndex = state.currentStepIndex + 1;
    final isLastStep = nextIndex >= state.steps.length;

    if (isLastStep) {
      final finalState = state.copyWith(
        skippedStepIndices: skipped,
        isActive: false,
      );
      state = finalState;
      await WorkflowPreferences.clear();
      if (context.mounted) context.go('/modules');
    } else {
      final nextState = state.copyWith(
        skippedStepIndices: skipped,
        currentStepIndex: nextIndex,
      );
      state = nextState;
      await WorkflowPreferences.save(nextState);

      final selectedSite = _ref.read(siteDropdownValueProvider);
      final selectedTeam = _ref.read(teamDropdownValueProvider);

      if (context.mounted) {
        context.push(state.steps[nextIndex].route, extra: {
          'selectedSite': selectedSite,
          'selectedTeam': selectedTeam,
        });
      }
    }
  }

  /// Called when user explicitly cancels the workflow from the progress banner.
  Future<void> cancelWorkflow(BuildContext context) async {
    state = WorkflowState.empty;
    await WorkflowPreferences.clear();
    if (context.mounted) context.go('/modules');
  }

  /// Called from ModuleScreenV2.didChangeDependencies() (or initState).
  /// If a saved workflow exists (app was killed mid-flow), offer resume.
  Future<void> tryRestoreSession() async {
    final saved = await WorkflowPreferences.load();
    if (saved != null && saved.isActive) {
      state = saved;
    }
  }
}
```

---

## WorkflowPreferences (Persistence)

### File: `lib/features/workflow/domain/workflow_preferences.dart`

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'workflow_state.dart';
import 'workflow_step.dart';
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
```

---

## WorkflowRegistry (Step Definitions)

### File: `lib/features/workflow/registry/workflow_registry.dart`

```dart
import '../domain/workflow_step.dart';
import 'daily_entry_workflow.dart';

/// Central lookup table for all workflow step lists.
///
/// To add a new workflow (e.g. 'setup'):
///   1. Create setup_workflow.dart with the step list.
///   2. Add one entry to the map below.
///   3. Nothing else changes.
class WorkflowRegistry {
  static const String dailyEntryId = 'daily_entry';
  static const String setupId      = 'setup';          // future

  static final Map<String, List<WorkflowStep>> _registry = {
    dailyEntryId: DailyEntryWorkflow.steps,
    // setupId: SetupWorkflow.steps,   ← uncomment when ready
  };

  /// Returns the step list for [workflowId], or null if unknown.
  static List<WorkflowStep>? stepsFor(String workflowId) {
    return _registry[workflowId];
  }
}
```

---

### File: `lib/features/workflow/registry/daily_entry_workflow.dart`

```dart
import 'package:flutter/material.dart';
import '../domain/workflow_step.dart';

/// Step definitions for the Daily Entry workflow.
///
/// ORDER MATTERS — steps are executed top to bottom.
///
/// To reorder, add, or remove a step: edit this list only.
/// No other file needs to change.
class DailyEntryWorkflow {
  static const List<WorkflowStep> steps = [
    WorkflowStep(
      title: 'Attendance',
      description: 'Mark present/absent for all workers on site',
      route: '/site-list/attendance',
      icon: Icons.how_to_reg_rounded,
      color: Colors.green,
      isOptional: false,
      estimatedMinutes: 2,
    ),
    WorkflowStep(
      title: 'DPR Entry',
      description: 'Log daily progress for the current activity',
      route: '/site-list/dpr',
      icon: Icons.description_rounded,
      color: Colors.indigo,
      isOptional: false,
      estimatedMinutes: 3,
    ),
    WorkflowStep(
      title: 'Expense',
      description: 'Record any site expenses for today',
      route: '/site-list/add-exp',
      icon: Icons.receipt_long_rounded,
      color: Colors.orange,
      isOptional: true,
      estimatedMinutes: 1,
    ),
    WorkflowStep(
      title: 'Inventory',
      description: 'Update material usage and stock levels',
      route: '/site-list/inv-entry',
      icon: Icons.inventory_2_rounded,
      color: Colors.teal,
      isOptional: true,
      estimatedMinutes: 2,
    ),
  ];
}
```

> **To add a 5th step in the future**: add a `WorkflowStep(...)` entry to this list. Done.

---

## Gate Screen (Intro)

### File: `lib/features/workflow/screens/workflow_gate_screen.dart`

This is a **full screen**, not a bottom sheet. Push it from ModuleScreenV2 via:

```dart
context.push('/workflow-gate', extra: {'workflowId': WorkflowRegistry.dailyEntryId});
```

You must also register this route in your GoRouter config.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/workflow_step.dart';
import '../domain/workflow_controller.dart';
import '../registry/workflow_registry.dart';

class WorkflowGateScreen extends ConsumerWidget {
  final String workflowId;

  const WorkflowGateScreen({super.key, required this.workflowId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs      = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final steps   = WorkflowRegistry.stepsFor(workflowId) ?? [];
    final totalETA = steps.fold<int>(0, (sum, s) => sum + s.estimatedMinutes);

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      // ── AppBar with back arrow ─────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const SizedBox(height: 8),
              Text(
                "Daily Entry Workflow",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Complete all required entries in one guided session.",
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              // ETA chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Estimated time: $totalETA–${totalETA + 2} mins",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ── Step list ─────────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: steps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, i) {
                    final step = steps[i];
                    final isLast = i == steps.length - 1;
                    return _GateStepRow(
                      step: step,
                      stepNumber: i + 1,
                      isLast: isLast,
                      cs: cs,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // ── Start button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // Start workflow in controller
                    await ref
                        .read(workflowControllerProvider.notifier)
                        .startWorkflow(
                          steps: steps,
                          workflowId: workflowId,
                        );
                    if (context.mounted) {
                      // Go to the gate screen closes, then push first step
                      context.pop(); // close gate screen
                      // ModuleScreenV2 will detect isActive and push first step
                      // OR push directly here — see note below
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Start Workflow",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal widget: one row in the gate step list ──────────────────────────
class _GateStepRow extends StatelessWidget {
  final WorkflowStep step;
  final int stepNumber;
  final bool isLast;
  final ColorScheme cs;

  const _GateStepRow({
    required this.step,
    required this.stepNumber,
    required this.isLast,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: number + connector line ──────────────────────────────
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: step.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: step.color.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Icon(step.icon, size: 18, color: step.color),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: cs.outlineVariant.withOpacity(0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // ── Right: text ──────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (step.isOptional) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Optional",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "~${step.estimatedMinutes} min",
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.primary.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## ModuleScreenV2 Changes

These are **additive only**. Nothing is removed from the existing file.

### 1. Add provider watch at top of build()

```dart
// In the build() method, alongside the existing ref.watch calls:
final workflowState = ref.watch(workflowControllerProvider);
```

### 2. Add tryRestoreSession in initState

```dart
@override
void initState() {
  super.initState();
  // ... existing initState code ...
  
  // Restore any in-progress workflow from a previous app session
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(workflowControllerProvider.notifier).tryRestoreSession();
  });
}
```

### 3. Register the workflow gate route in GoRouter

In your GoRouter config (wherever your routes are defined), add:

```dart
GoRoute(
  path: '/workflow-gate',
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>? ?? {};
    final workflowId = extra['workflowId'] as String? ?? 'daily_entry';
    return WorkflowGateScreen(workflowId: workflowId);
  },
),
```

### 4. Add the FAB to the Stack in build()

Find the `Stack` inside `ShowCaseWidget.builder`. Add this as a new layer AFTER the toast overlay (Layer 4) and BEFORE the access overlay (Layer 5):

```dart
// Layer 4.5: Workflow FAB — only on Daily tab, only when no workflow is active
if (_currentIndex == 0 &&
    !workflowState.isActive &&
    _overlayType == null)
  Positioned(
    bottom: 92 + MediaQuery.of(context).padding.bottom,
    left: 20,
    child: _buildWorkflowFab(t, cs),
  ),
```

### 5. Add the FAB builder method

```dart
Widget _buildWorkflowFab(Translator t, ColorScheme cs) {
  return GestureDetector(
    onTap: () {
      context.push('/workflow-gate', extra: {
        'workflowId': WorkflowRegistry.dailyEntryId,
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            "Start Daily Entry",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 6. Add progress banner inside _buildFloatingDock

In `_buildFloatingDock`, **above** the `_buildNavBar(...)` call, add:

```dart
// Workflow progress banner — slides in when workflow is active
AnimatedSize(
  duration: const Duration(milliseconds: 350),
  curve: Curves.easeOutCubic,
  child: workflowState.isActive
      ? _buildWorkflowProgressBanner(workflowState, cs, isDark)
      : const SizedBox.shrink(),
),
```

### 7. Add progress banner builder method

```dart
Widget _buildWorkflowProgressBanner(
    WorkflowState ws, ColorScheme cs, bool isDark) {
  return Container(
    decoration: BoxDecoration(
      color: isDark
          ? cs.surfaceContainerHigh.withOpacity(0.96)
          : Colors.white.withOpacity(0.97),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      border: Border(
        top: BorderSide(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
        left: BorderSide(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
        right: BorderSide(color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.14),
          blurRadius: 24,
          offset: const Offset(0, -6),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Row: label + cancel ──────────────────────────────────────────
        Row(
          children: [
            Text(
              ws.stepLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ws.currentStep?.title ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref
                  .read(workflowControllerProvider.notifier)
                  .cancelWorkflow(context),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── Progress bar ─────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ws.progressFraction,
            minHeight: 5,
            backgroundColor: cs.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        ),
        const SizedBox(height: 10),
        // ── Step dots ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ws.steps.asMap().entries.map((entry) {
            final i    = entry.key;
            final step = entry.value;
            final done    = ws.completedStepIndices.contains(i);
            final skipped = ws.skippedStepIndices.contains(i);
            final isCurrent = i == ws.currentStepIndex && ws.isActive;

            Color dotColor;
            IconData dotIcon;
            if (done)         { dotColor = Colors.green;    dotIcon = Icons.check_rounded; }
            else if (skipped) { dotColor = cs.outlineVariant; dotIcon = Icons.remove_rounded; }
            else if (isCurrent){ dotColor = cs.primary;     dotIcon = step.icon; }
            else              { dotColor = cs.surfaceContainerHigh; dotIcon = step.icon; }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isCurrent ? 32 : 26,
                  height: isCurrent ? 32 : 26,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    dotIcon,
                    size: isCurrent ? 16 : 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isCurrent
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: isCurrent
                        ? cs.onSurface
                        : cs.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}
```

### 8. Handle workflow navigation post-start

After `startWorkflow()` completes and the gate screen pops, ModuleScreenV2 needs to push the first step's route. Do this by listening to the workflow state in `didUpdateWidget` or via a `ref.listen` in the build method:

```dart
// In the build() method, after the provider watches but BEFORE return:
ref.listen<WorkflowState>(workflowControllerProvider, (prev, next) {
  // When workflow becomes active for the first time (from gate screen),
  // push the first route.
  if (next.isActive &&
      (prev == null || !prev.isActive) &&
      next.currentStepIndex == 0 &&
      next.steps.isNotEmpty) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final selectedSite = ref.read(siteDropdownValueProvider);
      final selectedTeam = ref.read(teamDropdownValueProvider);
      context.push(next.steps[0].route, extra: {
        'selectedSite': selectedSite,
        'selectedTeam': selectedTeam,
      });
    });
  }

  // When workflow ends (isActive flips to false after last step),
  // show a completion toast.
  if (prev != null &&
      prev.isActive &&
      !next.isActive &&
      next.completedStepIndices.isNotEmpty) {
    _showToast("✓ Daily entry complete!");
  }
});
```

---

## Per-Screen Navigation Change

This is the **only change required in each of the 4 entry screens**.

### Pattern (apply identically to all 4 screens)

Find the **save/submit button handler** in each screen. Currently it ends with something like:

```dart
// Existing post-save navigation (current behaviour)
if (context.mounted) context.pop();
```

Replace that single line with this branch:

```dart
// NEW: Check if we are inside a workflow session
final workflowState = ref.read(workflowControllerProvider);
if (workflowState.isActive) {
  // Workflow mode: advance to the next step (controller handles navigation)
  await ref.read(workflowControllerProvider.notifier).advance(context);
} else {
  // Normal mode: existing behaviour — just pop
  if (context.mounted) context.pop();
}
```

### For optional steps only: also add a Skip option

If the screen corresponds to an optional step (`WorkflowStep.isOptional == true`), you may expose a "Skip" text button in the **AppBar actions** area (not in the form body):

```dart
// In AppBar actions — ONLY if this screen is an optional step in a workflow
Consumer(
  builder: (context, ref, _) {
    final wf = ref.watch(workflowControllerProvider);
    if (!wf.isActive || !(wf.currentStep?.isOptional ?? false)) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () => ref
          .read(workflowControllerProvider.notifier)
          .skipCurrentStep(context),
      child: const Text("Skip"),
    );
  },
),
```

This is the **maximum UI change** allowed on entry screens. No other additions.

### Files to modify

| File (find your actual path) | Change location |
|---|---|
| Attendance screen | Post-save handler |
| DPR screen | Post-save handler |
| Expense screen | Post-save handler |
| Inventory entry screen | Post-save handler |

---

## Completion Return

When `advance()` is called on the last step, the controller sets `isActive = false` and calls `context.go('/modules')` (your main module screen route).

The `ref.listen` block in `ModuleScreenV2` (see section above) detects the `isActive` flip and calls `_showToast("✓ Daily entry complete!")`.

No separate completion screen is needed. The existing toast system handles feedback.

> **Future enhancement**: If you want a full completion summary sheet later, add it in `advance()` before calling `context.go()`. The architecture supports it without any structural changes.

---

## Future Extensibility

### Adding a 5th step to Daily Entry

Open `daily_entry_workflow.dart`. Add one `WorkflowStep(...)` to the `steps` list. Done.

### Adding a Setup workflow

1. Create `lib/features/workflow/registry/setup_workflow.dart` with a `steps` list.
2. In `WorkflowRegistry`, uncomment `setupId: SetupWorkflow.steps`.
3. In ModuleScreenV2, add a FAB on the Setup tab (index == 1) that pushes `/workflow-gate` with `workflowId: WorkflowRegistry.setupId`.
4. In each Setup screen's save handler, apply the same two-line branch as above.

### Role-based workflows

Since steps are just a `List<WorkflowStep>`, you can pass different lists based on user role:

```dart
final steps = userRole == 'admin'
    ? AdminDailyWorkflow.steps
    : DailyEntryWorkflow.steps;
await controller.startWorkflow(steps: steps, workflowId: 'daily_entry');
```

### Conditional steps

To conditionally include a step at runtime:

```dart
static List<WorkflowStep> stepsForType(String workType) {
  return [
    ...baseSteps,
    if (workType == 'structure_work') pmEntryStep,
  ];
}
```

Call this in `WorkflowGateScreen.build()` instead of reading `DailyEntryWorkflow.steps` directly.

---

## What Must NOT Change

The following existing behaviours must remain completely intact:

| Behaviour | Why |
|---|---|
| Normal `context.pop()` after saving (non-workflow mode) | The single-entry flow must work exactly as before |
| All existing module card UI in ModuleScreenV2 | Only the FAB and progress banner are added |
| Access control / subscription checks | Not touched by workflow system |
| Tour / showcase system | Not touched |
| Dropdown row (site, team, type, entry mode) | Not touched |
| Daily stats section | Not touched |
| The attach/detach module card feature | Not touched |
| All existing routes and route parameters | No route is modified, only one new route added |

---

## Implementation Checklist

For the AI agent to work through in order:

- [ ] Create `lib/features/workflow/domain/workflow_step.dart`
- [ ] Create `lib/features/workflow/domain/workflow_state.dart`
- [ ] Create `lib/features/workflow/domain/workflow_preferences.dart`
- [ ] Create `lib/features/workflow/domain/workflow_controller.dart`
- [ ] Create `lib/features/workflow/registry/workflow_registry.dart`
- [ ] Create `lib/features/workflow/registry/daily_entry_workflow.dart`
- [ ] Create `lib/features/workflow/screens/workflow_gate_screen.dart`
- [ ] Register `/workflow-gate` route in GoRouter config
- [ ] Add `workflowControllerProvider` watch in `ModuleScreenV2.build()`
- [ ] Add `tryRestoreSession()` call in `ModuleScreenV2.initState()`
- [ ] Add `ref.listen` block in `ModuleScreenV2.build()` for first-step push and completion toast
- [ ] Add `_buildWorkflowFab()` method to `ModuleScreenV2`
- [ ] Add FAB to Stack in `ModuleScreenV2.build()` (Daily tab only, workflow not active)
- [ ] Add `_buildWorkflowProgressBanner()` method to `ModuleScreenV2`
- [ ] Add progress banner to `_buildFloatingDock()` in `ModuleScreenV2`
- [ ] Modify post-save handler in Attendance screen
- [ ] Modify post-save handler in DPR screen
- [ ] Modify post-save handler in Expense screen
- [ ] Modify post-save handler in Inventory entry screen
- [ ] Add optional "Skip" AppBar action to Expense screen (isOptional = true)
- [ ] Add optional "Skip" AppBar action to Inventory entry screen (isOptional = true)
- [ ] Verify: single-entry flow (no workflow) still works unchanged
- [ ] Verify: workflow flow navigates Attendance → DPR → Expense → Inventory → ModuleScreen
- [ ] Verify: app kill mid-workflow → reopen → state is restored
- [ ] Verify: "Cancel" from progress banner resets state and returns to module screen