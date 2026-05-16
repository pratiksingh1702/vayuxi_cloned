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
