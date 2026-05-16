import 'package:flutter/material.dart';
import '../domain/workflow_step.dart';

/// Step definitions for the Daily Entry workflow.
/// ORDER MATTERS — steps are executed top to bottom.
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
