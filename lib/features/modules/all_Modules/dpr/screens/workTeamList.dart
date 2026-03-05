import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../../team/provider/teamProvider.dart';
import 'dprTeamDetails.dart';


class WorkTeamListPage extends ConsumerStatefulWidget {
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

  const WorkTeamListPage({super.key,this.selectedEndDate,this.selectedStartDate});

  @override
  ConsumerState<WorkTeamListPage> createState() => _WorkTeamListPageState();
}

class _WorkTeamListPageState extends ConsumerState<WorkTeamListPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);
    final notifier = ref.read(teamProvider.notifier);

    if (type == "mechanical_work") {
      await notifier.fetchMechanicalCombined(siteId: siteId!);
    }
    else if (type == "insulation_work") {
      await notifier.fetchInsulationCombined(siteId: siteId!);
    }
    else {
      // fallback if some other type appears
      await notifier.fetchTeams(type: type!, siteId: siteId!);
    }

  }

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.selectedStartDate;
    _selectedEndDate = widget.selectedEndDate;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshTeams();
      final teamState = ref.read(teamProvider);
      final teams = teamState.teams;

// 🚫 If no teams at all → auto navigate
      if (teams.isEmpty) {
        ref.read(selectedTeamIdProvider.notifier).state = "";
        _goNext("", "");
        return;
      }

      // final teamState = ref.read(teamProvider);
      // final teams = teamState.teams;
      //
      // bool isDefault(String name) =>
      //     name.trim().toLowerCase().contains("default backend team");
      //
      // // 🚫 no teams at all
      // if (teams.isEmpty) {
      //   ref.read(selectedTeamIdProvider.notifier).state = "";
      //   _goNext("", "");
      //   return;
      // }
      //
      // // Filter real teams
      // final realTeams = teams.where((t) => !isDefault(t.teamName)).toList();
      //
      // // 🚫 only default exists
      // if (realTeams.isEmpty) {
      //   ref.read(selectedTeamIdProvider.notifier).state = "";
      //   _goNext("", "");
      //   return;
      // }

      // ✅ At least one real team exists → DO NOT auto navigate
      // User must manually pick
      return;
    });
  }

  void _goNext(String teamId, String teamName) {
    final site = ref.read(currentSiteProvider);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DprWorkScreen(
          siteId: site!.id,
          teamId: teamId,
          name: teamName,
          selectedEndDate: widget.selectedEndDate,
          selectedStartDate: widget.selectedStartDate,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final site = ref.read(currentSiteProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFEAF3FB), // soft blue background
      appBar: const CustomAppBar(title: "Team Details"),
      body: BottomButtonWrapper(
        child: Builder(
          builder: (context) {
            // ✅ show loading ONLY when nothing cached yet
            if (teamState.isLoading && !teamState.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ show error ONLY if no cached data
            if (!teamState.hasData && teamState.error != null) {
              return Center(child: Text("Error: ${teamState.error}"));
            }

            final teams = teamState.teams;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ Optional: show sync error but keep UI working
                  if (teamState.error != null && teamState.hasData)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        teamState.error!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),

                  // Teams Grid
                  Expanded(
                    child: GridView.builder(
                      itemCount: teams.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, index) {
                        final team = teams[index];

                        debugPrint(team.teamName);
                        debugPrint(team.teamLeadImage);

                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedTeamIdProvider.notifier).state = team.id;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DprWorkScreen(
                                  siteId: site!.id,
                                  teamId: team.id,
                                  name: team.teamName,
                                  selectedEndDate: widget.selectedEndDate,
                                  selectedStartDate: widget.selectedStartDate,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.white,
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipOval(
                                        child: team.teamLeadImage != null &&
                                            team.teamLeadImage!.isNotEmpty
                                            ? Image.network(
                                          team.teamLeadImage!,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) {
                                            return Image.asset(
                                              "assets/images/team_def.webp",
                                              height: 80,
                                              width: 80,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        )
                                            : Image.asset(
                                          "assets/images/team_def.webp",
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        team.isDefaultTeam?'Default team':team.teamName ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),

      ),
    );
  }

  Future<void> _confirmDeleteTeam(BuildContext context, String teamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Team"),
        content: const Text(
          "Are you sure you want to delete this team?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteTeam(context, teamId);
    }
  }

  Future<void> _deleteTeam(BuildContext context, String teamId) async {
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);

    if (type == null || siteId == null) return;

    try {
      await ref.read(teamProvider.notifier).deleteTeam(
        siteId: siteId,
        teamId: teamId,
        type: type,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Team deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete team"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}