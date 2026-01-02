import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../provider/teamProvider.dart';
import 'addTeam.dart';
import 'editTeam.dart';

class TeamListPage extends ConsumerStatefulWidget {
  const TeamListPage({super.key});

  @override
  ConsumerState<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends ConsumerState<TeamListPage> {
  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);
    await ref.read(teamProvider.notifier).getTeams(type!, siteId!);
  }

  @override
  void initState() {
    super.initState();
    _refreshTeams();
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final site = ref.read(currentSiteProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB), // soft blue background
      appBar: const CustomAppBar(title: "Team Details"),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Add",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>AddTeamScreen() ),
                );
              },
            ),
          ),
        ],
        child: teamState.when(
          data: (teams) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Teams Grid
                Expanded(
                  child: GridView.builder(
                    itemCount: teams.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      print(team.teamName);
                      print(team.teamLeadImage);
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditTeamScreen(site: site!, team: team),
                            ),
                          );
                        },
                        child: Card(
                          color: Colors.white,

                          child: Stack(
                            children: [Center(
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
                                          "assets/images/default.jpg",
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                        : Image.asset(
                                      "assets/images/default.jpg",
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
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    _confirmDeleteTeam(context, team.id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),]
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("Error: $err")),
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