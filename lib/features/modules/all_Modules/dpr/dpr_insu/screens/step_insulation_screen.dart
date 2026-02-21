import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/insu_step_provider.dart';
import 'floor_selection.dart';

class StepInsulationScreen extends ConsumerWidget {
  final String siteId;
  final String teamId;
  final String name;
  final String? teamName;

  const StepInsulationScreen({
    Key? key,
    required this.siteId,
    required this.teamId,
    required this.name,
    this.teamName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Always start with floor selection
    return FloorSelectionScreen(
      siteId: siteId,
      teamId: teamId,
      name: name,
      teamName: teamName ?? '',
    );
  }
}