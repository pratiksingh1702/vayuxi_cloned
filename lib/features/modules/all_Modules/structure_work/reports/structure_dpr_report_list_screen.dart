import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import 'package:untitled2/core/router/routes.dart';
import 'package:untitled2/features/modules/all_Modules/team/offline/state/team_State.dart';
import '../dpr/models/dpr_structure_model.dart';
import '../dpr/providers/dpr_structure_provider.dart';

class StructureDprReportListScreen extends ConsumerStatefulWidget {
  final String siteId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;

  const StructureDprReportListScreen({
    super.key,
    required this.siteId,
    this.startDate,
    this.endDate,
    this.type,
  });

  @override
  ConsumerState<StructureDprReportListScreen> createState() =>
      _StructureDprReportListScreenState();
}

class _StructureDprReportListScreenState
    extends ConsumerState<StructureDprReportListScreen> {
  Set<String> _selectedTeamIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(dprStructureProvider.notifier).setFilters(
            startDate: _rangeStart,
            endDate: _rangeEnd,
          );
      await _fetchTeams();
      await _fetchDPRs();
    });
  }

  DateTime get _rangeStart {
    final source = widget.startDate ?? DateTime.now();
    return DateTime(source.year, source.month, source.day);
  }

  DateTime get _rangeEnd {
    final source = widget.endDate ?? widget.startDate ?? DateTime.now();
    return DateTime(source.year, source.month, source.day, 23, 59, 59);
  }

  Future<void> _fetchTeams() async {
    await ref.read(teamProvider.notifier).fetchTeams(
          type: 'structure_work',
          siteId: widget.siteId,
        );
  }

  Future<void> _fetchDPRs() async {
    ref.read(dprStructureProvider.notifier).setFilters(
          startDate: _rangeStart,
          endDate: _rangeEnd,
        );
    await ref
        .read(dprStructureProvider.notifier)
        .fetchPebDPRList(widget.siteId, type: widget.type);
  }

  Future<void> _deleteDpr(DPRStructure dpr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete DPR'),
        content: Text(
            'Are you sure you want to delete ${dpr.dprName}?\n\nThis action cannot be undone.'),
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

    if (confirmed == true) {
      final success = await ref
          .read(dprStructureProvider.notifier)
          .deletePebDPR(widget.siteId, dpr.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('DPR deleted successfully'),
              backgroundColor: Colors.red),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete DPR')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dprStructureProvider);
    final teamState = ref.watch(teamProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredDprs = state.dprs.where((dpr) {
      final matchesTeam =
          _selectedTeamIds.isEmpty || _selectedTeamIds.contains(dpr.teamId);
      return matchesTeam;
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
          _buildPeriodBanner(cs, isDark),
          _buildTeamFilter(teamState, cs),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDprs.isEmpty
                    ? _EmptyState(cs: cs)
                    : RefreshIndicator(
                        onRefresh: _fetchDPRs,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: filteredDprs.length,
                          itemBuilder: (context, index) {
                            final dpr = filteredDprs[index];
                            return _DPRReportCard(
                              dpr: dpr,
                              onDelete: () => _deleteDpr(dpr),
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

  Widget _buildPeriodBanner(ColorScheme cs, bool isDark) {
    final fromText = DateFormat('dd MMM yyyy').format(_rangeStart);
    final toText = DateFormat('dd MMM yyyy').format(_rangeEnd);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF7B3F00).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.date_range_rounded,
              color: Color(0xFF7B3F00),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DPR List Period',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$fromText to $toText',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFilter(TeamState teamState, ColorScheme cs) {
    if (teamState.teams.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            "Filter by Teams",
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: teamState.teams.length,
            itemBuilder: (context, index) {
              final team = teamState.teams[index];
              final isSelected = _selectedTeamIds.contains(team.id);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    team.teamName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTeamIds.add(team.id);
                      } else {
                        _selectedTeamIds.remove(team.id);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF7B3F00),
                  checkmarkColor: Colors.white,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF7B3F00)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DPRReportCard extends StatelessWidget {
  final DPRStructure dpr;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DPRReportCard({
    required this.dpr,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const accentColor = Color(0xFF7B3F00);
    final markText = _markSummary(dpr.items);
    final teamName = dpr.teamName?.trim();
    final dateText =
        DateFormat('dd MMM yyyy').format(dpr.date ?? DateTime.now());
    final subtitleText =
        teamName?.isNotEmpty == true ? '$dateText • $teamName' : dateText;
    final totalWeightKg = _totalWeightKg(dpr);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.22 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    color: isDark ? const Color(0xFFD2B48C) : accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dpr.dprName.isEmpty ? 'Structure DPR' : dpr.dprName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.22 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${totalWeightKg.toStringAsFixed(2)} kg',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFD2B48C) : accentColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: accentColor,
                  onPressed: onTap,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniMetric(label: 'Mark No', value: markText),
                _MiniMetric(
                    label: 'Qty', value: dpr.totalQtyUsed.toStringAsFixed(0)),
                _MiniMetric(
                    label: 'Date',
                    value: DateFormat('dd MMM yyyy')
                        .format(dpr.date ?? DateTime.now())),
              ],
            ),
            if (dpr.remarks?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                dpr.remarks!.trim(),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _markSummary(List<DPRStructureItem> items) {
  final marks = items
      .map((item) => item.assemblyMark.trim())
      .where((mark) => mark.isNotEmpty)
      .toSet()
      .toList();
  if (marks.isEmpty) return '-';
  if (marks.length == 1) return marks.first;
  return '${marks.first} +${marks.length - 1}';
}

double _totalWeightKg(DPRStructure dpr) {
  if (dpr.totalNetWeight > 0) return dpr.totalNetWeight;
  return dpr.items.fold<double>(
    0,
    (sum, item) => sum + (item.totalNetWeight ?? 0),
  );
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
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
          Text('No DPRs found for this period',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
        ],
      ),
    );
  }
}
