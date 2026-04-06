import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../model/teamModel.dart';
import '../provider/teamProvider.dart';
import '../provider/teamService.dart';

import 'addTeam.dart';
import 'editTeam.dart';

class TeamListPage extends ConsumerStatefulWidget {
  const TeamListPage({super.key});

  @override
  ConsumerState<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends ConsumerState<TeamListPage> {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedTeamIds = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);
    await ref.read(teamProvider.notifier).fetchTeams(type: type!, siteId: siteId!);
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTeams();
    });
  }


  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTeamIds.clear();
      }
    });
  }

  /// Toggle individual team selection
  void _toggleTeamSelection(String teamId) {
    setState(() {
      if (_selectedTeamIds.contains(teamId)) {
        _selectedTeamIds.remove(teamId);
      } else {
        _selectedTeamIds.add(teamId);
      }
    });
  }

  /// Select all teams
  void _selectAllTeams(List<TeamModel> teams)
  {
    setState(() {
      for (var team in teams) {
        _selectedTeamIds.add(team.id);
      }
    });
  }

  /// Delete selected teams
  Future<void> _deleteSelectedTeams() async {
    if (_selectedTeamIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No teams selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Teams'),
        content: Text(
          'Are you sure you want to delete ${_selectedTeamIds.length} selected teams?\n\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await TeamApi.bulkDeleteTeams(teamIds: _selectedTeamIds.toList());

      // Refresh teams list
      await _refreshTeams();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully deleted ${_selectedTeamIds.length} teams',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _selectedTeamIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to bulk delete: $e');
      final message = extractBackendError(e);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk delete failed: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final site = ref.read(currentSiteProvider);

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFEAF3FB),
      appBar: CustomAppBar(
        title: _isSelectionMode
            ? '${_selectedTeamIds.length} Selected'
            : "Team Details",
      ),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: "Add",
              color: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                  context.push(Routes.addTeam);
                },
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            // ✅ loading only when no cached data
            if (teamState.isLoading && !teamState.hasData) {
              return const ShimmerList(
                type: ShimmerListType.grid,
                crossAxisCount: 2,
                itemCount: 6,
              );
            }

            // ✅ show error only if no data
            if (!teamState.hasData && teamState.error != null) {
              return Center(child: Text("Error: ${teamState.error}"));
            }

            final teams = teamState.teams;

            return Column(
              children: [
                // ✅ optional: show sync error as snackbar-like banner
                if (teamState.error != null && teamState.hasData)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(
                      teamState.error!,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),

                // Top action bar with selection controls
                if (teams.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (_isSelectionMode) ...[
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _toggleSelectionMode,
                              tooltip: 'Cancel',
                            ),
                            TextButton(
                              onPressed: () => _selectAllTeams(teams),
                              child: const Text('Select All'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.delete_sweep, size: 18),
                              label: const Text('Delete'),
                              onPressed:
                              _selectedTeamIds.isEmpty ? null : _deleteSelectedTeams,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(
                                Icons.delete_sweep,
                                color: Colors.red,
                              ),
                              onPressed: teams.isEmpty ? null : _toggleSelectionMode,
                              tooltip: 'Select Teams to Delete',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LiquidPullToRefresh(
                      onRefresh: _refreshTeams,
                      child: CustomScrollbar(
                        controller: _scrollController,
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: teams.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (context, index) {
                            final team = teams[index];
                            final isSelected = _selectedTeamIds.contains(team.id);
                            return _buildTeamCard(team, isSelected, site);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

      ),
    );
  }

  Widget _buildTeamCard(team, bool isSelected, site) {
    return Stack(
      children: [
        Opacity(
          opacity: _isSelectionMode && !isSelected ? 0.5 : 1.0,
          child: GestureDetector(
            onTap: _isSelectionMode
                ? () => _toggleTeamSelection(team.id)
                : () {
              context.push(Routes.editTeam, extra: {
                'site': site!,
                'team': team,
              });
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
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const ShimmerImage(
                                        height: 80,
                                        width: 80,
                                        shape: BoxShape.circle,
                                      );
                                    },
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

                  // Delete button (only show when not in selection mode)
                  if (!_isSelectionMode)
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
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Selection checkbox overlay
        if (_isSelectionMode)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleTeamSelection(team.id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.red : Colors.white,
                  border: Border.all(
                    color: Colors.red,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
                    : null,
              ),
            ),
          ),
      ],
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