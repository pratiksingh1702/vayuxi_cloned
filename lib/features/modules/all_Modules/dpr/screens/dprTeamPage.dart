import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/moc_selection_page.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/repository/siteModel.dart';

import '../../team/provider/teamProvider.dart';
import '../../team/screens/teamsList.dart';
import '../dpr_insu/screens/step_insulation_screen.dart';
import '../providers/dpr.dart';
import 'add_description.dart';

class DprTeamScreen extends ConsumerStatefulWidget {
  final SiteModel site;

  const DprTeamScreen({super.key, required this.site});

  @override
  ConsumerState<DprTeamScreen> createState() => _DprTeamScreenState();
}

class _DprTeamScreenState extends ConsumerState<DprTeamScreen> {
  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    await ref.read(teamProvider.notifier).fetchTeams(type: type!, siteId: widget.site.id);

  }
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final type = ref.read(typeProvider);

      await ref
          .read(teamProvider.notifier)
          .fetchTeams(type: type!, siteId: widget.site.id);

      final teamState = ref.read(teamProvider);
      final teams = teamState.teams;
      print("📦 TOTAL TEAMS: ${teams.length}");

      for (final t in teams) {
        print("👥 TEAM: ${t.teamName}  → members: ${t.teamMemberIds}");
      }



      /// 🚫 NO TEAM → move ahead with empty
      if (teams.isEmpty) {
        ref.read(selectedTeamIdProvider.notifier).state = "";

        _goNext("", "");
        return;
      }

      /// ✅ ONLY ONE TEAM → auto pick
      if (teams.length == 1) {
        final team = teams.first;

        ref.read(selectedTeamIdProvider.notifier).state = team.id;

        _goNext(team.id, team.teamName);
        return;
      }



    });
  }
  void _goNext(String teamId, String? teamName) {
    final type = ref.read(typeProvider);

    if (type == "mechanical_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MOCSelectionPage(
            siteId: widget.site.id,
            teamId: teamId,
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
            siteId: widget.site.id,
            teamId: teamId,
            name: widget.site.siteName ?? "",
            teamName: teamName,
          ),
        ),
      );
    }
  }

  void _navigateWithoutTeam() {
    final type = ref.read(typeProvider);

    // clear team state
    ref.read(selectedTeamIdProvider.notifier).state = "default";
    ref.read(selectedTeamProvider.notifier).clear();

    if (type == "mechanical_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MOCSelectionPage(
            siteId: widget.site.id,
            teamId:"default",
            teamName: null,
            onMOCSelected: (selectedMOC) {},
          ),
        ),
      );
    } else if (type == "insulation_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StepInsulationScreen(
            siteId: widget.site.id,
            teamId: "",
            name: widget.site.siteName ?? "",
            teamName: null,
          ),
        ),
      );
    } else {
      debugPrint("❌ Unknown work type: $type");
    }
  }

  Future<void> _handleTeamAutoNavigation() async {
    final teamState = ref.read(teamProvider);
    final type = ref.read(typeProvider);

    // 🚫 NO TEAMS → SKIP THIS SCREEN
    if (teamState.teams.isEmpty) {
      // clear selection explicitly
      ref.read(selectedTeamIdProvider.notifier).state = "default";
      ref.read(selectedTeamProvider.notifier).clear();
      print("heeeeeeeeeeeeee");

      if (type == "mechanical_work") {
        context.push(
          '/moc-selection',
          extra: {
            'siteId': widget.site.id,
            'teamId': null,
            'teamName': null,
          },
        );
      } else if (type == "insulation_work") {
        context.replace(
          '/step-insulation',
          extra: {
            'siteId': widget.site.id,
            'teamId': null,
            'teamName': null,
          },
        );
      }

      return;
    }
  }


  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);


    return Scaffold(
      backgroundColor: AppColors.lightBlue,

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Select Your Team"),
          ];
        },

        body: CornerClippedScreenSimple(
          child: Builder(
            builder: (context) {
              // ✅ show loader only if no offline data
              if (teamState.isLoading && !teamState.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // ✅ show error only if no cached data
              if (!teamState.hasData && teamState.error != null) {
                return Column(
                  children: [
                    Expanded(child: Center(child: Text("Error: ${teamState.error}"))),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: RoundedButton(
                        text: "Back",
                        color: Colors.white,
                        textColor: Colors.black,
                        onPressed: () => context.pop(),
                        width: double.infinity,
                      ),
                    ),
                  ],
                );
              }

              final teams = teamState.teams;

              return Column(
                children: [
                  // ✅ show sync error but keep UI running
                  if (teamState.error != null && teamState.hasData)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        teamState.error!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),

                  Expanded(
                    child: LiquidPullToRefresh(
                      onRefresh: _refreshTeams,
                      height: 200,
                      backgroundColor: Colors.blue,
                      color: Colors.white,
                      animSpeedFactor: 2.0,
                      showChildOpacityTransition: true,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];

                          return InkWell(
                            onTap: () {
                              ref.read(selectedTeamIdProvider.notifier).state = team.id;

                              final type = ref.read(typeProvider);

                              if (type == "mechanical_work") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MOCSelectionPage(
                                      siteId: widget.site.id,
                                      teamId: team.id,
                                      teamName: team.teamName,
                                      onMOCSelected: (selectedMOC) {},
                                    ),
                                  ),
                                );
                              } else if (type == "insulation_work") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StepInsulationScreen(
                                      siteId: widget.site.id,
                                      teamId: team.id,
                                      name: widget.site.siteName ?? "",
                                      teamName: team.teamName,
                                    ),
                                  ),
                                );
                              } else {
                                debugPrint("❌ Unknown work type: $type");
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
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
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          "assets/images/default.webp",
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                        : Image.asset(
                                      "assets/images/default.webp",
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    team.teamName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: RoundedButton(
                      text: "Back",
                      color: Colors.white,
                      textColor: Colors.black,
                      onPressed: () => context.pop(),
                      width: double.infinity,
                    ),
                  ),
                ],
              );
            },
          ),

        ),
      ),
    );
  }
}