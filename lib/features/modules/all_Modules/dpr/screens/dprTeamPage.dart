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
    await ref.read(teamProvider.notifier).getTeams(type!, widget.site.id);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final currentTeam = ref.read(currentTeamProvider);
      print("Selected Team ID: $selectedTeamId");
      print("Current Team: ${currentTeam?.teamName}");

      if (selectedTeamId != null && currentTeam != null) {
        // Team is preselected, navigate to next screen
        context.pushReplacement('/moc-selection', extra: {
          'siteId': widget.site.id,
          'teamId': currentTeam.id,
          'teamName': currentTeam.teamName,
        });
      } else {
        // No team preselected, load teams for selection
        final type = ref.read(typeProvider);
        ref.read(teamProvider.notifier).getTeams(type!, widget.site.id);
      }
    });
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
          child: teamState.when(
            data: (teams) => Column(
              children: [
                // Teams grid with expanded to take available space
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
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) => AddDescriptionScreen(
                            //       siteId: widget.site.id,
                            //       teamId: team.id,
                            //       teamName: team.teamName,
                            //     ),
                            //   ),
                            // );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MOCSelectionPage(
                                  siteId: widget.site.id,
                                  teamId: team.id,
                                  teamName: team.teamName,
                                  onMOCSelected: (selectedMOC) {
                                    print('Selected MOC: ${selectedMOC.name}');
                                  },
                                ),
                              ),
                            );
          
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: team.teamLeadImage != null && team.teamLeadImage!.isNotEmpty
                                      ? Image.network(
                                    team.teamLeadImage!,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        "assets/images/default.webp"
                                        ,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  )
                                      : Image.asset(
                                    "assets/images/default.webp"
                                    ,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                ,
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
                // Back button at the bottom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: RoundedButton(
                    text: "Back",
                    color: Colors.white,
                    textColor: Colors.black,
                    onPressed: () {
                      context.pop();
                    },
                    width: double.infinity,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Column(
              children: [
                Expanded(
                  child: Center(child: Text("Error: $err")),
                ),
                // Back button at the bottom even in error state
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: RoundedButton(
                    text: "Back",
                    color: Colors.white,
                    textColor: Colors.black,
                    onPressed: () {
                      context.pop();
                    },
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}