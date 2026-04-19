import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/mechanichal_stepper.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';
import '../../../../../core/utlis/widgets/image_clipped.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
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
  bool _isNavigatingAway = false;

  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    final notifier = ref.read(teamProvider.notifier);
    final siteId = widget.site.id;

    if (type == "mechanical_work") {
      await notifier.fetchMechanicalCombined(siteId: siteId);
    } else if (type == "insulation_work") {
      await notifier.fetchInsulationCombined(siteId: siteId);
    } else {
      await notifier.fetchTeams(type: type!, siteId: siteId);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshTeams();
      _tryAutoSkipWhenTeamsEmpty();
    });
  }

  void _tryAutoSkipWhenTeamsEmpty() {
    if (_isNavigatingAway || !mounted) return;

    final teamState = ref.read(teamProvider);
    if (teamState.isLoading) return;
    if (teamState.teams.isNotEmpty) return;

    _isNavigatingAway = true;
    final type = ref.read(typeProvider);

    // Clear team selection when bypassing team screen.
    ref.read(selectedTeamIdProvider.notifier).state = "";
    ref.read(selectedTeamProvider.notifier).clear();

    if (type == "mechanical_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MechanichalStepperScreen(
            siteId: widget.site.id,
            teamId: '',
            teamName: null,
          ),
        ),
      );
    } else if (type == "insulation_work") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StepInsulationScreen(
            siteId: widget.site.id,
            teamId: '',
            name: widget.site.siteName,
            teamName: null,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final cs = Theme.of(context).colorScheme;

    if (!_isNavigatingAway && !teamState.isLoading && teamState.teams.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryAutoSkipWhenTeamsEmpty();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    Widget teamIconAvatar() {
      return Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.groups_rounded,
          color: cs.onSurfaceVariant,
          size: 36,
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      drawer: const CustomDrawer(),
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
                return Center(
                  child: CircularProgressIndicator(color: cs.primary),
                );
              }
              //
              // If loading fails and no cached data exists, keep UI neutral.
              if (!teamState.hasData && teamState.error != null) {
                return Column(
                  children: [
                    Expanded(child: Center(child: Text("No teams available"))),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: RoundedButton(
                        text: "Back",
                        color: cs.surfaceContainerHigh,
                        textColor: cs.onSurface,
                        onPressed: () => context.pop(),
                        width: double.infinity,
                      ),
                    ),
                  ],
                );
              }

              final teams = teamState.teams;

              if (teams.isEmpty) {
                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          "No teams available",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: RoundedButton(
                        text: "Back",
                        color: cs.surfaceContainerHigh,
                        textColor: cs.onSurface,
                        onPressed: () => context.pop(),
                        width: double.infinity,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: LiquidPullToRefresh(
                      onRefresh: _refreshTeams,
                      height: 200,
                      backgroundColor: cs.primary,
                      color: cs.onPrimary,
                      animSpeedFactor: 2.0,
                      showChildOpacityTransition: true,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                              final isDefault = team.isDefaultTeam == true;

                              // 🔥 If default team → force empty ID
                              final effectiveTeamId = isDefault ? "" : team.id;
                              print("effectiveteam $effectiveTeamId");

                              ref.read(selectedTeamIdProvider.notifier).state =
                                  effectiveTeamId;

                              final type = ref.read(typeProvider);

                              if (type == "mechanical_work") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MechanichalStepperScreen(
                                      siteId: widget.site.id,
                                      teamId: effectiveTeamId,
                                      teamName: team.teamName,
                                    ),
                                  ),
                                );
                              } else if (type == "insulation_work") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StepInsulationScreen(
                                      siteId: widget.site.id,
                                      teamId: effectiveTeamId,
                                      name: widget.site.siteName ?? "",
                                      teamName: team.teamName,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: cs.outlineVariant.withOpacity(0.65),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.shadow.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
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
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return teamIconAvatar();
                                            },
                                          )
                                        : teamIconAvatar(),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    team.isDefaultTeam
                                        ? 'Default team'
                                        : team.teamName ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: cs.onSurface,
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
                      color: cs.surfaceContainerHigh,
                      textColor: cs.onSurface,
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
