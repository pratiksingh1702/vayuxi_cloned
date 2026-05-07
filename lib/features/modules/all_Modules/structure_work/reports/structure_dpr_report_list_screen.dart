import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';
import 'package:untitled2/core/utlis/widgets/date_picker.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/features/modules/all_Modules/team/offline/state/team_State.dart';
import '../dpr/models/dpr_structure_model.dart';
import '../dpr/providers/dpr_structure_provider.dart';
import '../dpr/screens/dpr_structure_create_screen.dart';

class StructureDprReportListScreen extends ConsumerStatefulWidget {
  final String siteId;
  const StructureDprReportListScreen({super.key, required this.siteId});

  @override
  ConsumerState<StructureDprReportListScreen> createState() =>
      _StructureDprReportListScreenState();
}

class _StructureDprReportListScreenState
    extends ConsumerState<StructureDprReportListScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  Set<String> _selectedTeamIds = {};
  String? _selectedTeamId;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await _fetchTeams();
        await _fetchDPRs();
      } finally {
        if (mounted) {
          setState(() => _isBootstrapping = false);
        }
      }
    });
  }

  Future<void> _fetchTeams() async {
    await ref.read(teamProvider.notifier).fetchTeams(
          type: 'structure_work',
          siteId: widget.siteId,
        );
  }

  Future<void> _fetchDPRs() async {
    await ref.read(dprStructureProvider.notifier).fetchDPRList(widget.siteId);
  }

  void _applyFilters() {
    ref.read(dprStructureProvider.notifier).setFilters(
          startDate: _selectedStartDate,
          endDate: _selectedEndDate,
        );
    _fetchDPRs();
  }

  void _clearFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedTeamId = null;
      _selectedTeamIds.clear();
    });
    ref.read(dprStructureProvider.notifier).setFilters(clear: true);
    _fetchDPRs();
  }

  Future<void> _showDatePicker({required bool isStartDate}) async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        title: isStartDate ? "Select Start Date" : "Select End Date",
        primaryColor: const Color(0xFF7B3F00),
        accentColor: Colors.brown,
        backgroundColor: Colors.white,
      ),
    );

    if (selected != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = selected;
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(selected)) {
            _selectedEndDate = null;
          }
        } else {
          _selectedEndDate = selected;
        }
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dprStructureProvider);
    final teamState = ref.watch(teamProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If we are still loading teams, show loader
    if (_isBootstrapping && teamState.isLoading) {
      return Scaffold(
        appBar: PremiumAppBar(title: 'Loading...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Selection Guard: If teams exist and none selected, show team picker
    if (teamState.teams.isNotEmpty &&
        _selectedTeamId == null &&
        _selectedTeamIds.isEmpty) {
      return _buildTeamSelectionScreen(teamState, cs, isDark);
    }

    final filteredDprs = state.dprs.where((dpr) {
      if (_selectedTeamIds.isEmpty && _selectedTeamId == null) return true;
      if (_selectedTeamId != null && dpr.teamId == _selectedTeamId) return true;
      return _selectedTeamIds.contains(dpr.teamId);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF8F9FA),
      appBar: PremiumAppBar(
        title: 'Structure DPR Reports',
        onDrawerPressed: () => context.pop(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
      ),
      body: Column(
        children: [
          _buildFilterSection(cs),
          _buildTeamChips(teamState, cs),
          const SizedBox(height: 8),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDprs.isEmpty
                    ? _EmptyState(cs: cs)
                    : RefreshIndicator(
                        onRefresh: _fetchDPRs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDprs.length,
                          itemBuilder: (context, index) {
                            final dpr = filteredDprs[index];
                            return _DPRReportCard(
                              dpr: dpr,
                              onTap: () {
                                context.push(
                                  '${Routes.structureDprCreate}/${widget.siteId}',
                                  extra: {
                                    'siteName': dpr.siteName ?? '',
                                    'initialDpr': dpr,
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelectionScreen(
      TeamState teamState, ColorScheme cs, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? cs.surface : const Color(0xFFF8F9FA),
      appBar: PremiumAppBar(
        title: 'Select Team',
        onDrawerPressed: () => context.pop(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: teamState.teams.length,
        itemBuilder: (context, index) {
          final team = teamState.teams[index];
          return InkWell(
            onTap: () => setState(() => _selectedTeamId = team.id),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? cs.surfaceContainerHigh : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B3F00).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded,
                        color: Color(0xFF7B3F00), size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    team.teamName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _DateButton(
              label: 'From',
              date: _selectedStartDate,
              onTap: () => _showDatePicker(isStartDate: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DateButton(
              label: 'To',
              date: _selectedEndDate,
              onTap: () => _showDatePicker(isStartDate: false),
            ),
          ),
          if (_selectedStartDate != null ||
              _selectedEndDate != null ||
              _selectedTeamIds.isNotEmpty ||
              _selectedTeamId != null)
            IconButton(
              onPressed: _clearFilters,
              icon: Icon(Icons.close_rounded, color: cs.error),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamChips(TeamState teamState, ColorScheme cs) {
    if (teamState.teams.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: teamState.teams.length,
        itemBuilder: (context, index) {
          final team = teamState.teams[index];
          final isSelected =
              _selectedTeamIds.contains(team.id) || _selectedTeamId == team.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(team.teamName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTeamIds.add(team.id);
                  } else {
                    _selectedTeamIds.remove(team.id);
                    if (_selectedTeamId == team.id) _selectedTeamId = null;
                  }
                });
              },
              selectedColor: const Color(0xFF7B3F00).withOpacity(0.2),
              checkmarkColor: const Color(0xFF7B3F00),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF7B3F00) : cs.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? const Color(0xFF7B3F00) : cs.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color:
                  date != null ? const Color(0xFF7B3F00) : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          date != null ? FontWeight.bold : FontWeight.normal,
                      color: date != null ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DPRReportCard extends StatelessWidget {
  final DPRStructure dpr;
  final VoidCallback onTap;

  const _DPRReportCard({required this.dpr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dpr.dprName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM').format(dpr.date ?? DateTime.now()),
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'DPR No: ${dpr.dprNumber}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Stat(
                        label: 'Qty',
                        value: dpr.totalQtyUsed.toStringAsFixed(0)),
                    _Stat(
                        label: 'Weight',
                        value:
                            '${(dpr.totalNetWeight / 1000).toStringAsFixed(2)} MT'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(dpr.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dpr.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(dpr.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined,
              size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'No DPRs found for this period',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
