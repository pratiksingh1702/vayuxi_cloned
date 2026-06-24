import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/common_functions.dart';
import '../../../../../core/utlis/app_toasts.dart';
import '../../../../../core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/shimmer.dart';
import '../../../../../core/utlis/widgets/sidebar.dart';
import '../../../../../core/utlis/widgets/custom_scrollbar.dart';
import '../../../../../typeProvider/type_provider.dart';
import '../../site_Details/providers/site_current_provider.dart';
import '../../../../tour/core/tour_models.dart';
import '../../../../tour/core/tour_package_adapter.dart';
import 'package:untitled2/features/tour/core/screen_owned_tour_mixin.dart';
import '../../../../tour/definitions/manpower_team_module_tours.dart';
import '../../../../tour/providers/tour_providers.dart';
import 'package:untitled2/features/tour/widgets/no_cutout_tour_target.dart';
import '../model/teamModel.dart';
import '../provider/teamProvider.dart';
import '../provider/teamService.dart';

import 'addTeam.dart';
import '../../../../../core/utlis/widgets/empty_module_state.dart';

enum TeamSortOption { latestFirst, nameAsc, nameDesc }

class TeamListPage extends ConsumerStatefulWidget {
  const TeamListPage({super.key});

  @override
  ConsumerState<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends ConsumerState<TeamListPage>
    with ScreenOwnedTourMixin<TeamListPage> {
  // Selection mode state
  bool _isSelectionMode = false;
  Set<String> _selectedTeamIds = {};
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TeamSortOption _sortOption = TeamSortOption.latestFirst;
  bool? _defaultTeamFilter;
  static const TourPackageAdapter _tourPackageAdapter = TourPackageAdapter();
  String? _lastShowcasedTourStepId;
  final GlobalKey _addTourKey = GlobalKey(debugLabel: 'team_list_add');
  final GlobalKey _deleteModeTourKey =
      GlobalKey(debugLabel: 'team_list_delete_mode');
  final GlobalKey _firstTeamTourKey =
      GlobalKey(debugLabel: 'team_list_first_team');
  final GlobalKey _emptyTourKey = GlobalKey(debugLabel: 'team_list_empty');

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<TeamModel> _visibleTeams(List<TeamModel> teams) {
    final query = _searchQuery.trim().toLowerCase();
    final visible = teams.where((team) {
      final matchesSearch =
          query.isEmpty || team.teamName.toLowerCase().contains(query);
      final matchesType = _defaultTeamFilter == null ||
          team.isDefaultTeam == _defaultTeamFilter;
      return matchesSearch && matchesType;
    }).toList();

    visible.sort((a, b) {
      switch (_sortOption) {
        case TeamSortOption.nameAsc:
          return a.teamName.toLowerCase().compareTo(b.teamName.toLowerCase());
        case TeamSortOption.nameDesc:
          return b.teamName.toLowerCase().compareTo(a.teamName.toLowerCase());
        case TeamSortOption.latestFirst:
          return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      }
    });
    return visible;
  }

  bool get _hasActiveFilters =>
      _defaultTeamFilter != null || _sortOption != TeamSortOption.latestFirst;

  String _csvCell(Object? value) =>
      '"${(value ?? '').toString().replaceAll('"', '""')}"';

  Future<void> _downloadTeams(List<TeamModel> teams) async {
    if (teams.isEmpty) {
      AppToast.info('No team records to download');
      return;
    }
    try {
      final rows = <List<Object?>>[
        ['Team Name', 'Team Type', 'Members', 'Created At'],
        ...teams.map((team) => [
              team.isDefaultTeam ? 'Default Team' : team.teamName,
              team.isDefaultTeam ? 'Default' : 'Standard',
              team.teamMemberIds.length,
              team.createdAt ?? '',
            ]),
      ];
      final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/team-list-${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        text: 'Team list export',
      );
    } catch (e) {
      debugPrint('Team export failed: $e');
      AppToast.error('Failed to export team list');
    }
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter & Sort',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _defaultTeamFilter = null;
                            _sortOption = TeamSortOption.latestFirst;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TeamSortOption>(
                    value: _sortOption,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: const [
                      DropdownMenuItem(
                        value: TeamSortOption.latestFirst,
                        child: Text('Latest first'),
                      ),
                      DropdownMenuItem(
                        value: TeamSortOption.nameAsc,
                        child: Text('Name A-Z'),
                      ),
                      DropdownMenuItem(
                        value: TeamSortOption.nameDesc,
                        child: Text('Name Z-A'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => _sortOption = value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<bool?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(value: false, label: Text('Created')),
                      ButtonSegment(value: true, label: Text('Default')),
                    ],
                    selected: {_defaultTeamFilter},
                    onSelectionChanged: (selection) {
                      setSheetState(() => _defaultTeamFilter = selection.first);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshTeams() async {
    final type = ref.read(typeProvider);
    final siteId = ref.read(selectedSiteIdProvider);
    await ref
        .read(teamProvider.notifier)
        .fetchTeams(type: type!, siteId: siteId!);
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
  void _selectAllTeams(List<TeamModel> teams) {
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
        SnackBar(
          content: Text('No teams selected'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
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
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _syncTeamListTour(
    BuildContext showcaseContext, {
    required bool hasTeams,
  }) {
    final definition = AppTourDefinition(
      id: '${ManpowerTeamModuleTours.teamId}_list_${hasTeams ? 'records' : 'empty'}',
      title: 'Team List',
      description: 'Learn how to manage teams.',
      icon: Icons.groups_rounded,
      steps: [
        const AppTourStep(
          id: 'team_list_intro',
          title: 'Team List',
          body: 'This screen shows the teams created for the selected site.',
          progressLabel: 'Team list',
          useSpotlight: false,
        ),
        AppTourStep(
          id: 'team_list_add',
          title: 'Add Team',
          body: 'Use this button to create a new team.',
          targetKey: _addTourKey,
          progressLabel: 'Add',
          tooltipBottomOffset: 96,
          autoScrollToTarget: true,
        ),
        if (hasTeams) ...[
          AppTourStep(
            id: 'team_list_delete_mode',
            title: 'Delete Teams',
            body: 'Use this button to select teams and delete them in bulk.',
            targetKey: _deleteModeTourKey,
            progressLabel: 'Delete',
          ),
          AppTourStep(
            id: 'team_list_first_team',
            title: 'Team Card',
            body:
                'Each card is one team. Tap it to open and update team details.',
            targetKey: _firstTeamTourKey,
            progressLabel: 'Card',
            autoScrollToTarget: true,
          ),
        ] else
          AppTourStep(
            id: 'team_list_empty',
            title: 'No Teams Yet',
            body:
                'When no team is created, this area tells you to add the first team.',
            targetKey: _emptyTourKey,
            progressLabel: 'Empty',
          ),
      ],
    );

    bindScreenOwnedTour(
        tourId: definition.id, showcaseContext: showcaseContext);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;
      final state = ref.read(appTourControllerProvider);
      final controller = ref.read(appTourControllerProvider.notifier);
      if (state.status != AppTourStatus.running) {
        await controller.maybeStartRuntimeTour(
          definition,
          policyTourId: ManpowerTeamModuleTours.teamId,
        );
      }
      final step = controller.currentStep;
      final activeTour = controller.activeTour;
      if (activeTour == null || activeTour.id != definition.id) {
        if (_lastShowcasedTourStepId != null) {
          _tourPackageAdapter.dismiss(showcaseContext);
          _lastShowcasedTourStepId = null;
        }
        return;
      }
      final stepKey = step == null ? null : '${activeTour.id}:${step.id}';
      if (step == null) return;
      if (_lastShowcasedTourStepId == stepKey) return;
      _lastShowcasedTourStepId = stepKey;
      // No-cutout tour overlay handles target presentation.
    });
  }

  Widget _tourTarget(GlobalKey key, Widget child) {
    return NoCutoutTourTarget(targetKey: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);
    final site = ref.read(currentSiteProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.watch(appTourControllerProvider);
    return ShowCaseWidget(
      builder: (showcaseContext) {
        return Scaffold(
          drawer: const CustomDrawer(),
          backgroundColor: colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: _isSelectionMode
                ? '${_selectedTeamIds.length} Selected'
                : "Team Details",
          ),
          body: BottomButtonWrapper(
            customButtons: [
              CustomButton(
                button: _tourTarget(
                  _addTourKey,
                  RoundedButton(
                    text: "Add",
                    color: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AddTeamScreen(returnResultOnSave: true)),
                      );
                      if (mounted) _refreshTeams();
                    },
                  ),
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
                  return Center(
                    child: Text(
                      "Team data is empty",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  );
                }

                final teams = teamState.teams;
                final visibleTeams = _visibleTeams(teams);
                _syncTeamListTour(showcaseContext, hasTeams: teams.isNotEmpty);

                return Column(
                  children: [
                    if (teams.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (value) =>
                                      setState(() => _searchQuery = value),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Search teams...',
                                    prefixIcon: const Icon(Icons.search_rounded,
                                        size: 20),
                                    suffixIcon: _searchQuery.isEmpty
                                        ? null
                                        : IconButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                            icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18),
                                          ),
                                    filled: true,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _toolbarButton(
                              tooltip: 'Filter and sort',
                              icon: Icons.tune_rounded,
                              active: _hasActiveFilters,
                              onPressed: _showFilters,
                            ),
                            const SizedBox(width: 6),
                            _toolbarButton(
                              tooltip: 'Download Sheet',
                              icon: Icons.download_rounded,
                              onPressed: () => _downloadTeams(visibleTeams),
                            ),
                            const SizedBox(width: 6),
                            ..._selectionControls(visibleTeams),
                          ],
                        ),
                      ),
                    if (teams.isNotEmpty && visibleTeams.isEmpty)
                      Expanded(
                        child: EmptyModuleState(
                          title: 'No Teams Found',
                          subtitle: 'Try adjusting your search or filters.',
                          icon: Icons.search_off_rounded,
                          actionLabel: 'Clear Filters',
                          onAction: () => setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _defaultTeamFilter = null;
                            _sortOption = TeamSortOption.latestFirst;
                          }),
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: teams.isEmpty
                              ? _tourTarget(
                                  _emptyTourKey,
                                  EmptyModuleState(
                                    title: "No Teams Created",
                                    subtitle:
                                        "Create your first team to organize manpower",
                                    icon: Icons.groups_rounded,
                                    actionLabel: "Add Team",
                                    onAction: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AddTeamScreen(
                                              returnResultOnSave: true),
                                        ),
                                      );
                                      if (mounted) _refreshTeams();
                                    },
                                  ),
                                )
                              : LiquidPullToRefresh(
                                  onRefresh: _refreshTeams,
                                  child: CustomScrollbar(
                                    controller: _scrollController,
                                    child: GridView.builder(
                                      controller: _scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemCount: visibleTeams.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 16,
                                        crossAxisSpacing: 16,
                                        childAspectRatio: 0.9,
                                      ),
                                      itemBuilder: (context, index) {
                                        final team = visibleTeams[index];
                                        final isSelected =
                                            _selectedTeamIds.contains(team.id);
                                        return _buildTeamCard(
                                          team,
                                          isSelected,
                                          site,
                                          cardTourKey: index == 0
                                              ? _firstTeamTourKey
                                              : null,
                                        );
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
      },
    );
  }

  Widget _toolbarButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool active = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? cs.primary : cs.outlineVariant,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null
                ? cs.onSurfaceVariant
                : active
                    ? cs.onPrimary
                    : cs.primary,
          ),
        ),
      ),
    );
  }

  List<Widget> _selectionControls(List<TeamModel> visibleTeams) {
    final allSelected = visibleTeams.isNotEmpty &&
        visibleTeams.every((team) => _selectedTeamIds.contains(team.id));
    if (!_isSelectionMode) {
      return [
        _tourTarget(
          _deleteModeTourKey,
          _toolbarButton(
            tooltip: 'Select Teams',
            icon: Icons.checklist_rounded,
            onPressed: visibleTeams.isEmpty ? null : _toggleSelectionMode,
          ),
        ),
      ];
    }
    return [
      SizedBox(
        height: 40,
        child: TextButton(
          onPressed: visibleTeams.isEmpty
              ? null
              : () {
                  if (allSelected) {
                    setState(() => _selectedTeamIds
                        .removeAll(visibleTeams.map((team) => team.id)));
                  } else {
                    _selectAllTeams(visibleTeams);
                  }
                },
          child: Text(allSelected ? 'Deselect' : 'Select All'),
        ),
      ),
      _toolbarButton(
        tooltip: 'Delete Selected',
        icon: Icons.delete_sweep_rounded,
        active: _selectedTeamIds.isNotEmpty,
        onPressed: _selectedTeamIds.isEmpty ? null : _deleteSelectedTeams,
      ),
      const SizedBox(width: 4),
      _toolbarButton(
        tooltip: 'Cancel',
        icon: Icons.close_rounded,
        onPressed: _toggleSelectionMode,
      ),
    ];
  }

  Widget _buildTeamCard(
    team,
    bool isSelected,
    site, {
    GlobalKey? cardTourKey,
  }) {
    final cs = Theme.of(context).colorScheme;

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

    final card = Stack(
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
              color: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.45),
                ),
              ),
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
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onError,
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
                  color: isSelected
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .shadow
                          .withOpacity(0.16),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onError,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
    return cardTourKey == null ? card : _tourTarget(cardTourKey, card);
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
            onPressed: () => context.pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => context.pop(true),
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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
