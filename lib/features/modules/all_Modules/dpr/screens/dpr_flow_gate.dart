import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/dprTeamPage.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/mechanichal_stepper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/screens/step_insulation_screen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/dpr/screens/dpr_structure_flow_gate.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

class DprFlowGate extends ConsumerWidget {
  final SiteModel site;

  const DprFlowGate({super.key, required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(typeProvider);
    final teamsCount = site.counts.teams;

    // Structure work has its own dedicated flow
    if (type == 'structure_work') {
      return DprStructureFlowGate(site: site);
    }

    // If site has no teams, skip team screen and open DPR directly.
    if (teamsCount == 0) {
      return _buildDirectScreen(type);
    }

    // Only show team screen when backend count says teams exist.
    return DprTeamScreen(site: site);
  }

  Widget _buildDirectScreen(String? type) {
    if (type == "mechanical_work") {
      return MechanichalStepperScreen(
        siteId: site.id,
        teamId: "",
        teamName: null,
      );
    }

    if (type == "insulation_work") {
      return StepInsulationScreen(
        siteId: site.id,
        teamId: "",
        name: site.siteName,
        teamName: null,
      );
    }

    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
