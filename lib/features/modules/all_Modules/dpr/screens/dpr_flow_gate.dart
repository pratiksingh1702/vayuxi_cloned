import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/dprTeamPage.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/screens/step_insulation_screen.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
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

    // 3. If team already selected from module dropdown, skip team screen
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    if (selectedTeamId != null && selectedTeamId.isNotEmpty) {
      TeamModel? selectedTeam;
      try {
        selectedTeam = teams.firstWhere((t) => t.id == selectedTeamId);
      } catch (_) {
        selectedTeam = null;
      }

      if (selectedTeam != null) {
        final effectiveTeamId =
            selectedTeam.isDefaultTeam ? "" : selectedTeam.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateWithSelectedTeam(
            context,
            ref,
            type,
            effectiveTeamId: effectiveTeamId,
            teamName: selectedTeam?.teamName,
          );
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
    }

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

  void _navigateWithSelectedTeam(
    BuildContext context,
    WidgetRef ref,
    String? type, {
    required String effectiveTeamId,
    required String? teamName,
  }) {
    ref.read(selectedTeamIdProvider.notifier).state = effectiveTeamId;

    if (type == "mechanical_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MOCSelectionPage(
            siteId: site.id,
            teamId: effectiveTeamId,
            teamName: teamName,
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
            teamId: effectiveTeamId,
            name: site.siteName,
            teamName: teamName,
          ),
        ),
      );
    }
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
