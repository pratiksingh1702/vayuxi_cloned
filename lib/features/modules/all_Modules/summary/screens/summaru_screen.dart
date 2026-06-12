import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/core/utlis/widgets/custom_scrollbar.dart';
import 'package:untitled2/core/utlis/widgets/empty_module_state.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/profit_loss_fusion.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../data/model_enums.dart';
import '../data/provider.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final Map<String, int> _monthMap = const {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  late List<String> _yearOptions;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yearOptions = List.generate(
      now.year - 2024,
      (i) => (now.year - i).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentType = ref.watch(typeProvider);
    if (_isPebSummaryType(currentType)) {
      return _PebWorkSummaryView(
        monthMap: _monthMap,
        yearOptions: _yearOptions,
      );
    }

    final filter = ref.watch(summaryFilterProvider);
    final notifier = ref.read(summaryFilterProvider.notifier);
    final summaryAsync = ref.watch(summaryDataProvider);
    final monthNames = _monthMap.keys.toList();
    final selectedMonthName = monthNames[filter.month - 1];

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: "Profit and Loss Summary"),
      body: Column(
        children: [
          // ── Filter Bar ──────────────────────────────────────────
          _FilterBar(
            filter: filter,
            notifier: notifier,
            monthMap: _monthMap,
            yearOptions: _yearOptions,
            selectedMonthName: selectedMonthName,
          ),

          // ── Content ─────────────────────────────────────────────
          Expanded(
            child: summaryAsync.when(
              loading: () => const _ShimmerList(),
              error: (e, _) =>
                  _ErrorView(onRetry: () => ref.refresh(summaryDataProvider)),
              data: (sites) {
                if (sites.isEmpty) return const _EmptyView();
                return CustomScrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: sites.length,
                    itemBuilder: (ctx, i) => _SiteTile(
                      site: sites[i],
                      filter: filter,
                      monthName: selectedMonthName,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

bool _isPebSummaryType(String? type) =>
    type == 'erection_work' ||
    type == 'structure_work' ||
    type == 'fabrication_work';

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final SummaryFilter filter;
  final SummaryFilterNotifier notifier;
  final Map<String, int> monthMap;
  final List<String> yearOptions;
  final String selectedMonthName;

  const _FilterBar({
    required this.filter,
    required this.notifier,
    required this.monthMap,
    required this.yearOptions,
    required this.selectedMonthName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final monthNames = monthMap.keys.toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Filter type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SummaryFilterType.values.map((type) {
                final isSelected = filter.filterType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => notifier.setFilterType(type),
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerLow,
                    checkmarkColor: colorScheme.onPrimary,
                    elevation: isSelected ? 2 : 0,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Date selectors based on filter type
          if (filter.filterType == SummaryFilterType.monthly)
            Row(children: [
              Expanded(
                  child: _dropdown(
                context: context,
                value: selectedMonthName,
                items: monthNames,
                onChanged: (v) => notifier.setMonth(monthMap[v]!),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown(
                context: context,
                value: filter.year,
                items: yearOptions,
                onChanged: (v) => notifier.setYear(v!),
              )),
            ])
          else if (filter.filterType == SummaryFilterType.yearly)
            _dropdown(
              context: context,
              value: filter.year,
              items: yearOptions,
              onChanged: (v) => notifier.setYear(v!),
            )
          else ...[
            // daily or weekly — show date picker + year
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filter.date,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) notifier.setDate(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${filter.date.day}/${filter.date.month}/${filter.date.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown(
                context: context,
                value: filter.year,
                items: yearOptions,
                onChanged: (v) => notifier.setYear(v!),
              )),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _dropdown({
    required BuildContext context,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Site Tile ────────────────────────────────────────────────────────────────

class _SiteTile extends StatelessWidget {
  final SiteSummaryModel site;
  final SummaryFilter filter;
  final String monthName;

  const _SiteTile({
    required this.site,
    required this.filter,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = site.profitPercentage;
    final isProfit = pct >= 0;
    final hasData = site.hasData;
    final trendColor = isProfit ? colorScheme.tertiary : colorScheme.error;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colorScheme.surface,
      elevation: 2,
      child: ListTile(
        title: Text(
          site.siteName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              hasData
                  ? "${isProfit ? 'Profit' : 'Loss'}: ${pct.toStringAsFixed(2)}%"
                  : "No transactions",
              style: TextStyle(
                color: !hasData
                    ? colorScheme.onSurfaceVariant
                    : isProfit
                        ? colorScheme.tertiary
                        : colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!hasData)
              Text(
                "No transactions for selected period",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: !hasData
            ? Icon(
                Icons.remove_circle_outline,
                color: colorScheme.onSurfaceVariant,
              )
            : Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: trendColor,
                size: 28,
              ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FinancialReportScreen(
              site: site,
              initialFilter: filter,
              monthName: monthName,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Erection / Fabrication Summary Analysis ────────────────────────────────

class _PebWorkSummaryView extends ConsumerStatefulWidget {
  final Map<String, int> monthMap;
  final List<String> yearOptions;

  const _PebWorkSummaryView({
    required this.monthMap,
    required this.yearOptions,
  });

  @override
  ConsumerState<_PebWorkSummaryView> createState() =>
      _PebWorkSummaryViewState();
}

class _PebWorkSummaryViewState extends ConsumerState<_PebWorkSummaryView> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(summaryFilterProvider);
    final notifier = ref.read(summaryFilterProvider.notifier);
    final summaryAsync = ref.watch(pebWorkSummaryProvider);
    final monthNames = widget.monthMap.keys.toList();
    final selectedMonthName = monthNames[filter.month - 1];
    final type = ref.watch(typeProvider);
    final title = type == 'fabrication_work'
        ? 'Fabrication Summary & Analysis'
        : 'Erection Summary & Analysis';

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: title),
      body: Column(
        children: [
          _FilterBar(
            filter: filter,
            notifier: notifier,
            monthMap: widget.monthMap,
            yearOptions: widget.yearOptions,
            selectedMonthName: selectedMonthName,
          ),
          Expanded(
            child: summaryAsync.when(
              loading: () => const _PebSummaryLoading(),
              error: (e, _) => _PebSummaryError(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.invalidate(pebWorkSummaryProvider),
              ),
              data: (summary) => RefreshIndicator(
                onRefresh: () async =>
                    ref.refresh(pebWorkSummaryProvider.future),
                child: CustomScrollbar(
                  controller: _controller,
                  child: ListView(
                    controller: _controller,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    children: [
                      _PebOverviewSection(summary: summary),
                      const SizedBox(height: 12),
                      _PebTrendSection(points: summary.plannedVsActual),
                      const SizedBox(height: 12),
                      _PebStageSection(stages: summary.stages),
                      const SizedBox(height: 12),
                      _PebGanttSection(rows: summary.gantt),
                      const SizedBox(height: 12),
                      _PebDelaySection(rows: summary.delayAnalysis),
                      const SizedBox(height: 12),
                      _PebTeamSection(teams: summary.teams),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PebOverviewSection extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PebOverviewSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final overview = summary.overview;
    final markSummary = summary.markSummary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Project Overview',
          subtitle: 'Planned vs actual progress for selected period',
        ),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _MetricCard(
              title: 'Overall Progress',
              value:
                  '${overview.overallProgressPercentage.toStringAsFixed(0)}%',
              icon: Icons.analytics_rounded,
              color: const Color(0xFF2563EB),
              progress: overview.overallProgressPercentage / 100,
            ),
            _MetricCard(
              title: 'BOQ Marks',
              value: '${overview.totalBoqMarks}',
              subtitle: '${overview.totalBoqWeightMt.toStringAsFixed(2)} MT',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF0F766E),
            ),
            _MetricCard(
              title: 'Assigned',
              value: '${overview.totalAssigned}',
              subtitle: '${markSummary.unassignedMarks} unassigned',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF7C3AED),
            ),
            _MetricCard(
              title: 'Delay Risk',
              value: '${overview.delayedStages}',
              subtitle: '${overview.totalPending} pending',
              icon: Icons.schedule_rounded,
              color: const Color(0xFFDC2626),
            ),
          ],
        ),
      ],
    );
  }
}

class _PebTrendSection extends StatelessWidget {
  final List<PebTrendPoint> points;

  const _PebTrendSection({required this.points});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Progressive Analysis',
            subtitle: 'Planned vs actual quantity trend',
            compact: true,
          ),
          if (points.isEmpty)
            const _EmptyMiniState(text: 'No planned or actual progress found')
          else
            ...points.take(8).map((point) {
              final maxQty = [
                point.cumulativePlannedQty,
                point.cumulativeActualQty,
                1.0,
              ].reduce((a, b) => a > b ? a : b);
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(point.period,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          'A ${_fmt(point.actualQty)} / P ${_fmt(point.plannedQty)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DualProgressBar(
                      planned: point.cumulativePlannedQty / maxQty,
                      actual: point.cumulativeActualQty / maxQty,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PebStageSection extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _PebStageSection({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage Wise Progress',
            subtitle: 'Assigned, in progress, complete and pending marks',
            compact: true,
          ),
          if (stages.isEmpty)
            const _EmptyMiniState(text: 'No work stages found')
          else
            ...stages.map((stage) => _StageProgressTile(stage: stage)),
        ],
      ),
    );
  }
}

class _PebGanttSection extends StatelessWidget {
  final List<PebGanttRow> rows;

  const _PebGanttSection({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Gantt Timeline',
            subtitle: 'Planned timeline compared with actual execution',
            compact: true,
          ),
          if (rows.isEmpty)
            const _EmptyMiniState(text: 'No timeline available')
          else
            ...rows.map((row) => _TimelineTile(row: row)),
        ],
      ),
    );
  }
}

class _PebDelaySection extends StatelessWidget {
  final List<PebDelayRow> rows;

  const _PebDelaySection({required this.rows});

  @override
  Widget build(BuildContext context) {
    final delayed = rows.where((row) => row.delayDays > 0).toList();
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Delay Analysis',
            subtitle: 'Planned end, actual end and pending status',
            compact: true,
          ),
          if (rows.isEmpty)
            const _EmptyMiniState(text: 'No delay data available')
          else if (delayed.isEmpty)
            const _EmptyMiniState(text: 'No delay found for selected period')
          else
            ...delayed.map((row) => _DelayTile(row: row)),
        ],
      ),
    );
  }
}

class _PebTeamSection extends StatelessWidget {
  final List<PebTeamSummary> teams;

  const _PebTeamSection({required this.teams});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Team Productivity',
            subtitle: 'Team-wise assignment and completion performance',
            compact: true,
          ),
          if (teams.isEmpty)
            const _EmptyMiniState(text: 'No team data found')
          else
            ...teams.map((team) => _TeamTile(team: team)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? progress;

  const _MetricCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (progress != null)
                Text(
                  '${((progress ?? 0) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _StageProgressTile extends StatelessWidget {
  final PebStageSummary stage;

  const _StageProgressTile({required this.stage});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(stage.status);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stage.stageName,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusChip(
                  label: _statusLabel(stage.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (stage.progressPercentage / 100).clamp(0, 1),
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniCount(label: 'Assign', value: stage.assigned),
              _MiniCount(label: 'In Progress', value: stage.inProgress),
              _MiniCount(label: 'Complete', value: stage.completed),
              _MiniCount(label: 'Pending', value: stage.pending),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final PebGanttRow row;

  const _TimelineTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.stageName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${row.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _statusColor(row.status),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DateLine(
            label: 'Planned',
            start: row.plannedStartDate,
            end: row.plannedEndDate,
          ),
          _DateLine(
            label: 'Actual',
            start: row.actualStartDate,
            end: row.actualEndDate,
          ),
        ],
      ),
    );
  }
}

class _DelayTile extends StatelessWidget {
  final PebDelayRow row;

  const _DelayTile({required this.row});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.stageName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '${row.pending} pending • ${row.inProgress} in progress',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${row.delayDays}d',
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final PebTeamSummary team;

  const _TeamTile({required this.team});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primaryContainer,
            child: Text(
              team.teamName.isEmpty ? 'T' : team.teamName[0].toUpperCase(),
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.teamName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 7,
                    value: (team.productivityPercentage / 100).clamp(0, 1),
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${team.productivityPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              Text(
                '${team.completed}/${team.assigned}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Widget child;

  const _SummaryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 2 : 10, top: compact ? 0 : 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 16 : 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCount extends StatelessWidget {
  final String label;
  final int value;

  const _MiniCount({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DualProgressBar extends StatelessWidget {
  final double planned;
  final double actual;

  const _DualProgressBar({required this.planned, required this.actual});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _SingleBar(
          label: 'Planned',
          value: planned,
          color: const Color(0xFF7C3AED),
          background: cs.surfaceContainerHighest,
        ),
        const SizedBox(height: 6),
        _SingleBar(
          label: 'Actual',
          value: actual,
          color: const Color(0xFF16A34A),
          background: cs.surfaceContainerHighest,
        ),
      ],
    );
  }
}

class _SingleBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color background;

  const _SingleBar({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: const TextStyle(fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: value.clamp(0, 1),
              backgroundColor: background,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  final String label;
  final String start;
  final String end;

  const _DateLine({
    required this.label,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              '${_shortDate(start)} → ${_shortDate(end)}',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMiniState extends StatelessWidget {
  final String text;

  const _EmptyMiniState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          text,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PebSummaryLoading extends StatelessWidget {
  const _PebSummaryLoading();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Shimmer.fromColors(
          baseColor: cs.surfaceContainerHighest,
          highlightColor: cs.surfaceContainerLow,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _PebSummaryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PebSummaryError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined,
                size: 58, color: cs.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'completed':
      return const Color(0xFF16A34A);
    case 'completed_late':
    case 'delayed':
      return const Color(0xFFDC2626);
    case 'in_progress':
      return const Color(0xFFF59E0B);
    case 'planned':
      return const Color(0xFF2563EB);
    default:
      return const Color(0xFF64748B);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return 'Complete';
    case 'completed_late':
      return 'Late';
    case 'delayed':
      return 'Delayed';
    case 'in_progress':
      return 'In Progress';
    case 'planned':
      return 'Planned';
    default:
      return 'Not Planned';
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String _shortDate(String value) {
  if (value.isEmpty || value == 'null') return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.length > 10 ? value.substring(0, 10) : value;
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/'
      '${parsed.year}';
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: 6,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: colorScheme.surface,
        elevation: 2,
        child: Shimmer.fromColors(
          baseColor: colorScheme.surfaceContainerHighest,
          highlightColor: colorScheme.surfaceContainerLow,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 16,
                width: 160,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 180,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends ConsumerWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyModuleState(
      title: "No Sites Available",
      subtitle: "Add sites to start tracking project profitability",
      icon: Icons.business_center_rounded,
      actionLabel: "Add Site",
      onAction: () => ref.refresh(summaryDataProvider),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            "Failed to load data",
            style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
