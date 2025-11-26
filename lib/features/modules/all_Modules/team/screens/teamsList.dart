import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/repository/siteModel.dart';
import '../provider/teamProvider.dart';
import 'editTeam.dart';

class TeamListPage extends ConsumerStatefulWidget {
  final SiteModel site;

  const TeamListPage({super.key, required this.site});

  @override
  ConsumerState<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends ConsumerState<TeamListPage> {
  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    await ref.read(teamProvider.notifier).getTeams(type!,widget.site.id);
  }

  @override
  void initState() {
    super.initState();
    _refreshTeams();
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FB), // soft blue background
      appBar: const CustomAppBar(title: "Team Details"),
      body: teamState.when(
        data: (teams) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                    return GestureDetector(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditTeamScreen(site:widget.site, team: team)),
                        );
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
                              child: Image.asset(
                                "assets/images/WhatsApp Image 2025-11-03 at 23.45.34_52e9b781.jpg", // Replace with your image
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

              // Back button
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: RoundedButton(
                        text: "Back",
                        color: Colors.white,
                        textColor: Colors.black,
                        onPressed: () => context.pop()),
                  ),
                  SizedBox(width: 10,),
                  Expanded(
                    child: RoundedButton(
                        text: "Add Team",
                        color: Colors.blue,
                        textColor: Colors.white,
                        onPressed: () => context.push("/add-team", extra:widget.site)),
                  ),

                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
