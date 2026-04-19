import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'insulation_stepper.dart';

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
    return InsulationStepperScreen(
      siteId: siteId,
      teamId: teamId,
      siteName: name,
      teamName: teamName ?? '',
    );
  }
}
