import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/dprTeamPage.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/screens/step_insulation_screen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

class DprFlowGate extends ConsumerWidget {
  final SiteModel site;

  const DprFlowGate({super.key, required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamState = ref.watch(teamProvider);
    final type = ref.watch(typeProvider);

    // 1. If still loading and no data yet, show loader
    if (teamState.isLoading && !teamState.hasData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Data is available (or stopped loading)
    final teams = teamState.teams;

    if (teams.isEmpty) {
      // 🚫 No teams -> Auto-redirect logic
      // We use a PostFrameCallback to avoid navigating during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateDirectly(context, ref, type);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Teams exist -> Show team selection screen
    return DprTeamScreen(site: site);
  }

  void _navigateDirectly(BuildContext context, WidgetRef ref, String? type) {
    // Clear selection for "no team" case
    ref.read(selectedTeamIdProvider.notifier).state = "";

    if (type == "mechanical_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MOCSelectionPage(
            siteId: site.id,
            teamId: "",
            teamName: null,
            onMOCSelected: (_) {},
          ),
        ),
      );
    } else if (type == "insulation_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StepInsulationScreen(
            siteId: site.id,
            teamId: "",
            name: site.siteName,
            teamName: null,
          ),
        ),
      );
    }
  }
}
