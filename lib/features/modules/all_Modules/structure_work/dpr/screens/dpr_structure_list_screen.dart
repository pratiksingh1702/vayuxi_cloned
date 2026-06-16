import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../models/dpr_structure_model.dart';
import '../providers/dpr_structure_provider.dart';
import 'dpr_structure_create_screen.dart';
import 'dpr_structure_detail_screen.dart';

const _kBrown = Color(0xFF7B3F00);

class DprStructureListScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  const DprStructureListScreen(
      {super.key, required this.siteId, required this.siteName});

  @override
  ConsumerState<DprStructureListScreen> createState() =>
      _DprStructureListScreenState();
}

class _DprStructureListScreenState extends ConsumerState<DprStructureListScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  int _filterIndex = 0; // 0=All,1=Today,2=Week,3=Month
  final List<String> _filterLabels = ['All', 'Today', 'Week', 'Month'];
  String? _selectedStage;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(0);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _applyFilter(int index) {
    setState(() {
      _filterIndex = index;
      _selectedStage = null;
    });
    final notifier = ref.read(dprStructureProvider.notifier);
    DateTime? start, end;
    final now = DateTime.now();
    switch (index) {
      case 1:
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 2:
        start = now.subtract(const Duration(days: 7));
        end = now;
        break;
      case 3:
        start = DateTime(now.year, now.month, 1);
        end = now;
        break;
      default:
        break;
    }
    notifier.setFilters(startDate: start, endDate: end, clear: index == 0);
    notifier.fetchDPRList(widget.siteId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dprStructureProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stageGroups = _groupDprsByStage(state.dprs);
    final selectedStageDprs = _selectedStage == null
        ? <DPRStructure>[]
        : stageGroups[_selectedStage] ?? <DPRStructure>[];

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: _selectedStage == null ? 'Structure DPR' : _selectedStage!,
        onDrawerPressed: () {
          if (_selectedStage != null) {
            setState(() => _selectedStage = null);
          } else {
            context.pop();
          }
        },
        drawerIcon: Icons.arrow_back_ios_new_rounded,
      ),
      body: Column(
        children: [
          // Header Stats Card
          _buildHeaderDashboard(state, cs, isDark),

          // Filter Row
          if (_selectedStage == null) _buildFilterBar(cs),
          if (_selectedStage != null)
            _buildStageDetailHeader(selectedStageDprs, cs, isDark),

          // List
          Expanded(
            child: state.isLoading
                ? const _DPRShimmerList()
                : state.error != null && state.dprs.isEmpty
                    ? _ErrorView(
                        message: state.error!,
                        onRetry: () => ref
                            .read(dprStructureProvider.notifier)
                            .fetchDPRList(widget.siteId))
                    : state.dprs.isEmpty
                        ? const _EmptyDPRState()
                        : RefreshIndicator(
                            color: _kBrown,
                            onRefresh: () => ref
                                .read(dprStructureProvider.notifier)
                                .fetchDPRList(widget.siteId),
                            child: _selectedStage == null
                                ? ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 120),
                                    itemCount: stageGroups.length,
                                    itemBuilder: (ctx, i) {
                                      final entry =
                                          stageGroups.entries.elementAt(i);
                                      return _DPRStageCard(
                                        stageName: entry.key,
                                        dprs: entry.value,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          setState(
                                              () => _selectedStage = entry.key);
                                        },
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 8, 16, 120),
                                    itemCount: selectedStageDprs.length,
                                    itemBuilder: (ctx, i) {
                                      final dpr = selectedStageDprs[i];
                                      return _DPRCard(
                                        dpr: dpr,
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DprStructureDetailScreen(
                                                dprId: dpr.id,
                                                siteId: widget.siteId,
                                                dpr: dpr,
                                              ),
                                            ),
                                          );
                                        },
                                        onDelete: () =>
                                            _confirmDelete(ctx, dpr),
                                      );
                                    },
                                  ),
                          ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => FloatingActionButton.extended(
          backgroundColor: _kBrown,
          elevation: 6 + _pulseCtrl.value * 3,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DprStructureCreateScreen(
                siteId: widget.siteId,
                siteName: widget.siteName,
                onSuccess: () => ref
                    .read(dprStructureProvider.notifier)
                    .fetchDPRList(widget.siteId),
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add DPR',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildHeaderDashboard(
      DPRStructureState state, ColorScheme cs, bool isDark) {
    final totalWeight =
        state.dprs.fold<double>(0, (p, c) => p + c.totalNetWeight);
    final totalQty = state.dprs.fold<double>(0, (p, c) => p + c.totalQtyUsed);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kBrown,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _kBrown.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8)),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/header_bg.webp'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.siteName,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Text('Structural Progress',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.analytics_outlined,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _DashboardStat(
                  label: 'Total Weight',
                  value: '${(totalWeight / 1000).toStringAsFixed(2)} MT',
                  icon: Icons.monitor_weight_outlined),
              const SizedBox(width: 24),
              _DashboardStat(
                  label: 'DPR Entries',
                  value: state.dprs.length.toString(),
                  icon: Icons.description_outlined),
              const SizedBox(width: 24),
              _DashboardStat(
                  label: 'Total Qty',
                  value: totalQty.toStringAsFixed(0),
                  icon: Icons.inventory_2_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme cs) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterLabels.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, i) {
          final isSelected = _filterIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: GestureDetector(
              onTap: () => _applyFilter(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kBrown : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _kBrown
                        : cs.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  _filterLabels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageDetailHeader(
      List<DPRStructure> dprs, ColorScheme cs, bool isDark) {
    final markCount = _uniqueMarkCount(dprs);
    final weight =
        dprs.fold<double>(0, (sum, dpr) => sum + _totalWeightKg(dpr));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StageHeaderMetric(
              label: 'Members',
              value: '${dprs.length}',
              icon: Icons.groups_rounded,
            ),
          ),
          Expanded(
            child: _StageHeaderMetric(
              label: 'Mark Nos',
              value: '$markCount',
              icon: Icons.tag_rounded,
            ),
          ),
          Expanded(
            child: _StageHeaderMetric(
              label: 'Weight',
              value: '${weight.toStringAsFixed(2)} kg',
              icon: Icons.scale_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, DPRStructure dpr) async {
    final cs = Theme.of(ctx).colorScheme;
    final ok = await showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (b) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.delete_sweep_rounded, color: cs.error, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Delete DPR Entry',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Are you sure you want to delete "${dpr.dprName}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(b, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(b, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      HapticFeedback.heavyImpact();
      final success = await ref
          .read(dprStructureProvider.notifier)
          .deleteDPR(widget.siteId, dpr.id);
      if (mounted) {
        final error = ref.read(dprStructureProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'DPR deleted' : (error ?? 'Delete failed')),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }
}

class _DashboardStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _DashboardStat(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _DPRStageCard extends StatelessWidget {
  final String stageName;
  final List<DPRStructure> dprs;
  final VoidCallback onTap;

  const _DPRStageCard({
    required this.stageName,
    required this.dprs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markCount = _uniqueMarkCount(dprs);
    final totalQty = dprs.fold<double>(0, (sum, dpr) => sum + dpr.totalQtyUsed);
    final totalWeight =
        dprs.fold<double>(0, (sum, dpr) => sum + _totalWeightKg(dpr));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kBrown.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.account_tree_rounded,
                        color: _kBrown, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stageName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _StageChip(label: '${dprs.length} Members'),
                            _StageChip(label: '$markCount Mark Nos'),
                            _StageChip(
                                label: '${totalQty.toStringAsFixed(0)} Qty'),
                            _StageChip(
                                label: '${totalWeight.toStringAsFixed(2)} kg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;

  const _StageChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StageHeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StageHeaderMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: _kBrown),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DPRCard extends StatelessWidget {
  final DPRStructure dpr;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DPRCard(
      {required this.dpr, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markText = _markSummary(dpr.items);
    final totalWeightKg = _totalWeightKg(dpr);
    final statusColor = dpr.status == 'approved'
        ? Colors.green
        : dpr.status == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onDelete,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kBrown.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.architecture_rounded,
                            color: _kBrown, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dpr.dprName,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text('Mark No: $markText',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _kBrown.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${totalWeightKg.toStringAsFixed(2)} kg',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: _kBrown,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(dpr.status.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DPRStatItem(
                        label: 'Weight',
                        value: totalWeightKg.toStringAsFixed(2),
                        unit: 'kg',
                        icon: Icons.scale_outlined,
                      ),
                      _DPRStatItem(
                        label: 'Quantity',
                        value: dpr.totalQtyUsed.toStringAsFixed(0),
                        unit: 'Units',
                        icon: Icons.inventory_2_outlined,
                      ),
                      _DPRStatItem(
                        label: 'Date',
                        value: DateFormat('dd MMM')
                            .format(dpr.date ?? DateTime.now()),
                        unit: DateFormat('yyyy')
                            .format(dpr.date ?? DateTime.now()),
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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

Map<String, List<DPRStructure>> _groupDprsByStage(List<DPRStructure> dprs) {
  final grouped = <String, List<DPRStructure>>{};
  for (final dpr in dprs) {
    final stage = _stageName(dpr);
    grouped.putIfAbsent(stage, () => <DPRStructure>[]).add(dpr);
  }
  return grouped;
}

String _stageName(DPRStructure dpr) {
  final name = dpr.dprName.trim();
  return name.isEmpty ? 'Structure DPR' : name;
}

int _uniqueMarkCount(List<DPRStructure> dprs) {
  final marks = <String>{};
  for (final dpr in dprs) {
    for (final item in dpr.items) {
      final mark = item.assemblyMark.trim();
      if (mark.isNotEmpty) marks.add(mark.toLowerCase());
    }
  }
  return marks.length;
}

double _totalWeightKg(DPRStructure dpr) {
  if (dpr.totalNetWeight > 0) return dpr.totalNetWeight;
  return dpr.items.fold<double>(
    0,
    (sum, item) => sum + (item.totalNetWeight ?? 0),
  );
}

class _DPRStatItem extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  const _DPRStatItem(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DPRShimmerList extends StatelessWidget {
  const _DPRShimmerList();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 160,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _EmptyDPRState extends StatelessWidget {
  const _EmptyDPRState();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _kBrown.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.note_add_outlined, size: 48, color: _kBrown),
          ),
          const SizedBox(height: 24),
          const Text('No DPR Entries Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Keep track of your structural work progress by adding your first DPR.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: cs.error),
            const SizedBox(height: 24),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Loading',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
