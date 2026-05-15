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
  DateTime? selectedDate;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  Set<String> _selectedTeamIds = {};
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

  Future<void> pickDate() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => BeautifulDatePicker(
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        title: "Select Date",
        primaryColor: const Color(0xFF7B3F00),
        accentColor: Colors.brown,
        backgroundColor: Colors.white,
      ),
    );

    if (selected == null) return;

    setState(() {
      selectedDate = selected;
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  void pickDateRange() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedStartDate != null && _selectedEndDate != null
          ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7B3F00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedStartDate = pickedRange.start;
        _selectedEndDate = pickedRange.end;
        selectedDate = null;
      });
    }
  }

  void clearDateFilter() {
    setState(() {
      selectedDate = null;
      _selectedStartDate = null;
      _selectedEndDate = null;
    });
  }

  bool _matchesDate(DateTime? date) {
    if (date == null) return false;
    final dprDate = DateTime(date.year, date.month, date.day);

    if (_selectedStartDate != null && _selectedEndDate != null) {
      final start = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
      );
      final end = DateTime(
        _selectedEndDate!.year,
        _selectedEndDate!.month,
        _selectedEndDate!.day,
      );
      return !dprDate.isBefore(start) && !dprDate.isAfter(end);
    }

    if (selectedDate != null) {
      final selected = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
      return dprDate == selected;
    }

    return true;
  }

  Future<void> _deleteDpr(DPRStructure dpr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete DPR'),
        content: Text('Are you sure you want to delete ${dpr.dprName}?\n\nThis action cannot be undone.'),
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
          .deleteDPR(widget.siteId, dpr.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DPR deleted successfully'), backgroundColor: Colors.red),
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
      final matchesDate = _matchesDate(dpr.date);
      final matchesTeam = _selectedTeamIds.isEmpty ||
          _selectedTeamIds.contains(dpr.teamId);
      return matchesDate && matchesTeam;
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: pickDateRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? cs.surfaceContainerHigh : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedStartDate != null ? const Color(0xFF7B3F00) : cs.outlineVariant,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 18, color: _selectedStartDate != null ? const Color(0xFF7B3F00) : Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedStartDate != null ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!) : "Select start date",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _selectedStartDate != null ? FontWeight.w600 : FontWeight.w400,
                                        color: _selectedStartDate != null ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("To", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: pickDateRange,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? cs.surfaceContainerHigh : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedEndDate != null ? const Color(0xFF7B3F00) : cs.outlineVariant,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 18, color: _selectedEndDate != null ? const Color(0xFF7B3F00) : Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedEndDate != null ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!) : "Select end date",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: _selectedEndDate != null ? FontWeight.w600 : FontWeight.w400,
                                        color: _selectedEndDate != null ? (isDark ? Colors.white : Colors.black) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selectedDate != null || (_selectedStartDate != null && _selectedEndDate != null))
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          onPressed: clearDateFilter,
                          icon: Icon(Icons.close_rounded, color: cs.error),
                          style: IconButton.styleFrom(
                            backgroundColor: cs.errorContainer,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickDate,
                        icon: const Icon(Icons.event_available),
                        label: const Text("Single Date"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: const Color(0xFF7B3F00),
                          side: const BorderSide(color: Color(0xFF7B3F00)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: pickDateRange,
                        icon: const Icon(Icons.date_range),
                        label: const Text("Date Range"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B3F00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildTeamFilter(teamState, cs),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDprs.isEmpty
                    ? _EmptyState(cs: cs)
                    : RefreshIndicator(
                        onRefresh: _fetchDPRs,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      color: isSelected ? const Color(0xFF7B3F00) : Colors.grey.shade300,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      color: theme.cardColor,
      child: ListTile(
        leading: Container(
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
        title: Text(
          dpr.dprName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'DPR No: ${dpr.dprNumber}  •  Qty: ${dpr.totalQtyUsed.toStringAsFixed(0)}  •  Wt: ${(dpr.totalNetWeight / 1000).toStringAsFixed(2)} MT',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM dd').format(dpr.date ?? DateTime.now()),
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: cs.error,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
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
          Icon(Icons.assignment_late_outlined, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text('No DPRs found for this period', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
        ],
      ),
    );
  }
}
