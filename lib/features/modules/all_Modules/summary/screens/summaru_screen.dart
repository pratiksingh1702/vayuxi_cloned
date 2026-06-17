import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/core/utlis/widgets/custom_scrollbar.dart';
import 'package:untitled2/core/utlis/widgets/card.dart';
import 'package:untitled2/core/utlis/widgets/empty_module_state.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
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
      return _PebSiteSelectionView(
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
  final bool weeklyDateRange;

  const _FilterBar({
    required this.filter,
    required this.notifier,
    required this.monthMap,
    required this.yearOptions,
    required this.selectedMonthName,
    this.weeklyDateRange = false,
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
          else if (filter.filterType == SummaryFilterType.weekly &&
              weeklyDateRange)
            Column(
              children: [
                Row(children: [
                  Expanded(
                    child: _datePickerBox(
                      context: context,
                      label: 'From',
                      date: filter.rangeFromDate,
                      onPicked: notifier.setRangeFromDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _datePickerBox(
                      context: context,
                      label: 'To',
                      date: filter.rangeToDate,
                      onPicked: notifier.setRangeToDate,
                    ),
                  ),
                ]),
              ],
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
                  child: _dateDisplayBox(context, null, filter.date),
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

  Widget _datePickerBox({
    required BuildContext context,
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onPicked,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onPicked(picked);
      },
      child: _dateDisplayBox(context, label, date),
    );
  }

  Widget _dateDisplayBox(BuildContext context, String? label, DateTime date) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          Expanded(
            child: Text(
              '${label != null ? '$label ' : ''}${date.day}/${date.month}/${date.year}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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

class _PebSiteSelectionView extends ConsumerStatefulWidget {
  final Map<String, int> monthMap;
  final List<String> yearOptions;

  const _PebSiteSelectionView({
    required this.monthMap,
    required this.yearOptions,
  });

  @override
  ConsumerState<_PebSiteSelectionView> createState() =>
      _PebSiteSelectionViewState();
}

class _PebSiteSelectionViewState extends ConsumerState<_PebSiteSelectionView> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(siteProvider.notifier).fetchSites();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(typeProvider);
    final siteState = ref.watch(siteProvider);
    final title = type == 'fabrication_work'
        ? 'Fabrication Summary & Analysis'
        : 'Erection Summary & Analysis';

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(title: title),
      body: RefreshIndicator(
        onRefresh: () => ref.read(siteProvider.notifier).fetchSites(),
        child: Builder(
          builder: (context) {
            if (siteState.isLoading && siteState.sites.isEmpty) {
              return const _ShimmerList();
            }

            if (siteState.sites.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                  EmptyModuleState(
                    title: "No Sites Available",
                    subtitle:
                        "Add a site first to view summary and analysis reports",
                    icon: Icons.business_center_rounded,
                    actionLabel: "Refresh",
                    onAction: () =>
                        ref.read(siteProvider.notifier).fetchSites(),
                  ),
                ],
              );
            }

            return CustomScrollbar(
              controller: _controller,
              child: CustomScrollView(
                controller: _controller,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                      child: _SectionHeader(
                        title: 'Select Site',
                        subtitle:
                            'Choose a site to view planned vs actual progress',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 1,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final site = siteState.sites[index];
                          return CompanyCard(
                            imagePath: site.siteImage ?? '',
                            fallbackIcon: Icons.location_city_rounded,
                            companyName: site.siteName,
                            show: false,
                            onTap: () {
                              ref
                                  .read(selectedSiteProvider.notifier)
                                  .select(site);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _PebWorkSummaryView(
                                    monthMap: widget.monthMap,
                                    yearOptions: widget.yearOptions,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: siteState.sites.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

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
  int _selectedTab = 0;

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
    final profitLossAsync = ref.watch(pebProfitLossProvider);
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
            weeklyDateRange: true,
          ),
          Expanded(
            child: _selectedTab == 0
                ? profitLossAsync.when(
                    loading: () => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      children: const [_PebSummaryLoading(compact: true)],
                    ),
                    error: (e, _) => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      children: [
                        _PebSummaryError(
                          message: e.toString().replaceFirst('Exception: ', ''),
                          onRetry: () => ref.invalidate(pebProfitLossProvider),
                        ),
                      ],
                    ),
                    data: (profitLoss) => RefreshIndicator(
                      onRefresh: () async =>
                          ref.refresh(pebProfitLossProvider.future),
                      child: _PebTabbedScroll(
                        controller: _controller,
                        selectedTab: _selectedTab,
                        onTabChanged: (index) =>
                            setState(() => _selectedTab = index),
                        children: [_PebProfitLossView(data: profitLoss)],
                      ),
                    ),
                  )
                : summaryAsync.when(
                    loading: () => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      children: const [_PebSummaryLoading(compact: true)],
                    ),
                    error: (e, _) => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      children: [
                        _PebSummaryError(
                          message: e.toString().replaceFirst('Exception: ', ''),
                          onRetry: () => ref.invalidate(pebWorkSummaryProvider),
                        ),
                      ],
                    ),
                    data: (summary) => RefreshIndicator(
                      onRefresh: () async =>
                          ref.refresh(pebWorkSummaryProvider.future),
                      child: _PebTabbedScroll(
                        controller: _controller,
                        selectedTab: _selectedTab,
                        onTabChanged: (index) =>
                            setState(() => _selectedTab = index),
                        children: _buildProjectTrackingSections(summary),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProjectTrackingSections(PebWorkSummaryModel summary) {
    final mode = summary.trackingMode;
    if (mode == 'dpr_only') {
      return [
        _PebTrackingModeBanner(summary: summary),
        const SizedBox(height: 12),
        _PebDprOnlyHero(summary: summary),
        const SizedBox(height: 12),
        _PebTrendSection(
          points: summary.plannedVsActual,
          title: 'Work Executed Trend',
          subtitle: 'Date-wise executed quantity',
          actualOnly: true,
        ),
        const SizedBox(height: 12),
        _PebDprOnlyStageSection(stages: summary.stages),
      ];
    }

    final hasAssignment = summary.dataAvailability.hasWorkAssignment;
    final hasBoq = summary.dataAvailability.hasBoq;
    return [
      _PebTrackingModeBanner(summary: summary),
      const SizedBox(height: 12),
      _PebOverviewSection(summary: summary),
      const SizedBox(height: 12),
      _PebTrendSection(
        points: summary.plannedVsActual,
        title: hasAssignment ? 'Plan vs Actual Trend' : 'Daily Progress Trend',
        subtitle: hasAssignment
            ? 'Cumulative assigned quantity compared with completed quantity'
            : 'Actual progress against BOQ scope',
      ),
      const SizedBox(height: 12),
      _PebStageSection(
        stages: summary.stages,
        title: hasAssignment ? 'Stage Wise Performance' : 'Stage Progress',
        subtitle: hasAssignment
            ? 'Assigned, completed and difference by stage'
            : hasBoq
                ? 'Each stage compared against total BOQ scope'
                : 'Assignment performance by stage',
      ),
      if (hasAssignment) ...[
        const SizedBox(height: 12),
        _PebGanttSection(rows: summary.gantt),
        const SizedBox(height: 12),
        _PebDelaySection(rows: summary.delayAnalysis),
        const SizedBox(height: 12),
        _PebTeamSection(teams: summary.teams),
      ],
    ];
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
          childAspectRatio: 1.32,
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

class _PebTrackingModeBanner extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PebTrackingModeBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_graph_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _trackingModeLabel(summary.trackingMode),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _trackingModeDescription(summary.trackingMode),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PebDprOnlyHero extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PebDprOnlyHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    final executedMt = summary.stages.fold<double>(
      0,
      (sum, stage) => sum + stage.actual.weightMt,
    );
    final executedQty = summary.stages.fold<double>(
      0,
      (sum, stage) => sum + stage.actual.qty,
    );
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Total Work Executed',
            subtitle: 'DPR data only for selected period',
            compact: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Executed Weight',
                  value: '${_fmt(executedMt)} MT',
                  icon: Icons.scale_rounded,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Executed Qty',
                  value: _fmt(executedQty),
                  icon: Icons.done_all_rounded,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PebDprOnlyStageSection extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _PebDprOnlyStageSection({required this.stages});

  @override
  Widget build(BuildContext context) {
    final visibleStages = stages
        .where((stage) => stage.actual.qty > 0 || stage.actual.weightMt > 0)
        .toList();
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage Activity Summary',
            subtitle: 'Actual quantity only',
            compact: true,
          ),
          if (visibleStages.isEmpty)
            const _EmptyMiniState(text: 'No DPR activity found')
          else
            ...visibleStages.map(
              (stage) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ActualOnlyStageTile(stage: stage),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActualOnlyStageTile extends StatelessWidget {
  final PebStageSummary stage;

  const _ActualOnlyStageTile({required this.stage});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stage.stageName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '${_fmt(stage.actual.weightMt)} MT',
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PebTabbedScroll extends StatelessWidget {
  final ScrollController controller;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final List<Widget> children;

  const _PebTabbedScroll({
    required this.controller,
    required this.selectedTab,
    required this.onTabChanged,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollbar(
      controller: controller,
      child: ListView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          _PebSummaryTabSwitcher(
            selectedIndex: selectedTab,
            onChanged: onTabChanged,
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _PebSummaryTabSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _PebSummaryTabSwitcher({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'P&L Analysis',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _TabButton(
            label: 'Project Tracking',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _PebProfitLossView extends StatelessWidget {
  final PebProfitLossModel data;

  const _PebProfitLossView({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profitColor =
        data.totals.isProfit ? const Color(0xFF15803D) : cs.error;

    if (data.empty) {
      return const EmptyModuleState(
        title: 'No financial data available',
        subtitle:
            'No revenue or expense data was found for the selected period.',
        icon: Icons.query_stats_rounded,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                title: data.site.name,
                subtitle:
                    '${_dateLabel(data.fromDate)} - ${_dateLabel(data.toDate)}',
                compact: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FinancialTile(
                      title: 'Revenue',
                      value: _money(data.totals.revenue),
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFF0F766E),
                      onTap: () => _showRevenueBreakdown(context, data),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FinancialTile(
                      title: 'Expense',
                      value: _money(data.totals.expense),
                      icon: Icons.receipt_long_rounded,
                      color: cs.error,
                      onTap: () => _showExpenseBreakdown(context, data),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: profitColor.withOpacity(0.24)),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.totals.isProfit
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      color: profitColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.totals.isProfit ? 'Profit' : 'Loss',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _money(data.totals.profitLoss.abs()),
                            style: TextStyle(
                              color: profitColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${data.totals.marginPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: profitColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ProfitLossChart(points: data.trend),
      ],
    );
  }
}

class _FinancialTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FinancialTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitLossChart extends StatelessWidget {
  final List<PebProfitLossTrendPoint> points;

  const _ProfitLossChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final visible = points.isEmpty
        ? const <PebProfitLossTrendPoint>[]
        : points.take(12).toList();
    final maxAmount = visible.fold<double>(1, (max, point) {
      return math.max(max, math.max(point.revenue, point.expense));
    });
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Revenue vs Expense',
            subtitle: 'Server-calculated financial trend',
            compact: true,
          ),
          if (visible.isEmpty)
            const _EmptyMiniState(text: 'No financial trend found')
          else ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visible
                    .map(
                      (point) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _GroupedBar(
                            point: point,
                            maxAmount: maxAmount,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                _LegendDot(color: Color(0xFF0F766E), label: 'Revenue'),
                SizedBox(width: 14),
                _LegendDot(color: Color(0xFFDC2626), label: 'Expense'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupedBar extends StatelessWidget {
  final PebProfitLossTrendPoint point;
  final double maxAmount;

  const _GroupedBar({required this.point, required this.maxAmount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final revenueHeight = (point.revenue / maxAmount).clamp(0.03, 1.0);
    final expenseHeight = (point.expense / maxAmount).clamp(0.03, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FractionallySizedBox(
                  heightFactor: revenueHeight,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: FractionallySizedBox(
                  heightFactor: expenseHeight,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    foregroundDecoration: point.loss > 0
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 1,
                            ),
                          )
                        : null,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          point.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _PebTrendSection extends StatelessWidget {
  final List<PebTrendPoint> points;
  final String title;
  final String subtitle;
  final bool actualOnly;

  const _PebTrendSection({
    required this.points,
    this.title = 'Progressive Analysis',
    this.subtitle = 'Planned vs actual quantity trend',
    this.actualOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: subtitle,
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
                          actualOnly
                              ? 'Executed ${_fmt(point.actualQty)}'
                              : 'A ${_fmt(point.actualQty)} / P ${_fmt(point.plannedQty)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (actualOnly)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value:
                              (point.cumulativeActualQty / maxQty).clamp(0, 1),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF0F766E),
                          ),
                        ),
                      )
                    else
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
  final String title;
  final String subtitle;

  const _PebStageSection({
    required this.stages,
    this.title = 'Stage Wise Progress',
    this.subtitle = 'Assigned, in progress, complete and pending marks',
  });

  @override
  Widget build(BuildContext context) {
    final visibleStages = stages
        .where((stage) =>
            stage.assigned > 0 ||
            stage.inProgress > 0 ||
            stage.completed > 0 ||
            stage.pending > 0)
        .toList();
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            subtitle: subtitle,
            compact: true,
          ),
          if (visibleStages.isEmpty)
            const _EmptyMiniState(text: 'No planned or actual stage data found')
          else ...[
            _StageDonutSummary(stages: visibleStages),
            const SizedBox(height: 12),
            ...visibleStages.map((stage) => _StageProgressTile(stage: stage)),
          ],
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
    final visibleRows = rows
        .where((row) =>
            row.plannedStartDate.isNotEmpty ||
            row.plannedEndDate.isNotEmpty ||
            row.actualStartDate.isNotEmpty ||
            row.actualEndDate.isNotEmpty)
        .toList();
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Gantt Timeline',
            subtitle: 'Planned timeline compared with actual execution',
            compact: true,
          ),
          if (visibleRows.isEmpty)
            const _EmptyMiniState(text: 'No timeline available')
          else
            _GanttChart(rows: visibleRows),
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
      padding: const EdgeInsets.all(12),
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
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              if (progress != null)
                Text(
                  '${((progress ?? 0) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
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
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniQuantity(
                  label: 'Planned',
                  value: _fmt(stage.planned.qty),
                  uom: stage.uom,
                ),
              ),
              Expanded(
                child: _MiniQuantity(
                  label: 'Actual',
                  value: _fmt(stage.actual.qty),
                  uom: stage.uom,
                ),
              ),
              Expanded(
                child: _MiniQuantity(
                  label: 'Variance',
                  value: _fmt(stage.planned.qty - stage.actual.qty),
                  uom: stage.uom,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageDonutSummary extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _StageDonutSummary({required this.stages});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assigned = stages.fold<int>(0, (sum, stage) => sum + stage.assigned);
    final completed =
        stages.fold<int>(0, (sum, stage) => sum + stage.completed);
    final inProgress =
        stages.fold<int>(0, (sum, stage) => sum + stage.inProgress);
    final pending = math.max(
      0,
      stages.fold<int>(0, (sum, stage) => sum + stage.pending),
    );
    final progress = assigned > 0 ? (completed / assigned) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: CustomPaint(
              painter: _DonutPainter(
                completed: completed.toDouble(),
                inProgress: inProgress.toDouble(),
                pending: pending.toDouble(),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Done',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _DonutLegend(
                  color: const Color(0xFF16A34A),
                  label: 'Completed',
                  value: completed,
                ),
                const SizedBox(height: 8),
                _DonutLegend(
                  color: const Color(0xFFF59E0B),
                  label: 'In Progress',
                  value: inProgress,
                ),
                const SizedBox(height: 8),
                _DonutLegend(
                  color: const Color(0xFF64748B),
                  label: 'Pending',
                  value: pending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _DonutLegend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double completed;
  final double inProgress;
  final double pending;

  const _DonutPainter({
    required this.completed,
    required this.inProgress,
    required this.pending,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = completed + inProgress + pending;
    final rect = Offset.zero & size;
    final stroke = math.min(size.width, size.height) * 0.14;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE5E7EB);

    canvas.drawArc(
      rect.deflate(stroke / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      basePaint,
    );

    if (total <= 0) return;

    var start = -math.pi / 2;
    void drawSegment(double value, Color color) {
      if (value <= 0) return;
      final sweep = (value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect.deflate(stroke / 2), start, sweep, false, paint);
      start += sweep;
    }

    drawSegment(completed, const Color(0xFF16A34A));
    drawSegment(inProgress, const Color(0xFFF59E0B));
    drawSegment(pending, const Color(0xFF64748B));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.pending != pending;
  }
}

class _GanttChart extends StatelessWidget {
  final List<PebGanttRow> rows;

  const _GanttChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    final datedRows = rows
        .map((row) => _GanttVisualRow.from(row))
        .where((row) => row.hasAnyDate)
        .toList();
    if (datedRows.isEmpty) {
      return const _EmptyMiniState(text: 'No timeline available');
    }

    final allDates = datedRows
        .expand((row) => [
              row.plannedStart,
              row.plannedEnd,
              row.actualStart,
              row.actualEnd,
            ])
        .whereType<DateTime>()
        .toList();
    final minDate = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = allDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final totalDays = math.max(1, maxDate.difference(minDate).inDays + 1);
    final ticks = _buildGanttTicks(minDate, maxDate);

    return LayoutBuilder(
      builder: (context, constraints) {
        final timelineWidth = math.max(430.0, constraints.maxWidth - 104);
        final chartWidth = timelineWidth + 104;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const _GanttLegend(),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(
                          width: 104,
                          height: 42,
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              'Stage',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                        _GanttAxis(
                          width: timelineWidth,
                          minDate: minDate,
                          totalDays: totalDays,
                          ticks: ticks,
                        ),
                      ],
                    ),
                    ...datedRows.map(
                      (row) => _GanttChartRow(
                        row: row,
                        width: timelineWidth,
                        minDate: minDate,
                        totalDays: totalDays,
                        ticks: ticks,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GanttLegend extends StatelessWidget {
  const _GanttLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _GanttLegendItem(label: 'Planned', color: Color(0xFF2563EB)),
        _GanttLegendItem(label: 'Actual', color: Color(0xFF16A34A)),
        _GanttLegendItem(label: 'Delayed', color: Color(0xFFDC2626)),
      ],
    );
  }
}

class _GanttLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _GanttLegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

class _GanttVisualRow {
  final PebGanttRow source;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;

  const _GanttVisualRow({
    required this.source,
    required this.plannedStart,
    required this.plannedEnd,
    required this.actualStart,
    required this.actualEnd,
  });

  bool get hasAnyDate =>
      plannedStart != null ||
      plannedEnd != null ||
      actualStart != null ||
      actualEnd != null;

  factory _GanttVisualRow.from(PebGanttRow row) {
    return _GanttVisualRow(
      source: row,
      plannedStart: _parseDate(row.plannedStartDate),
      plannedEnd: _parseDate(row.plannedEndDate),
      actualStart: _parseDate(row.actualStartDate),
      actualEnd: _parseDate(row.actualEndDate),
    );
  }
}

class _GanttTick {
  final DateTime date;
  final double position;

  const _GanttTick({
    required this.date,
    required this.position,
  });
}

List<_GanttTick> _buildGanttTicks(DateTime minDate, DateTime maxDate) {
  final totalDays = math.max(1, maxDate.difference(minDate).inDays);
  const count = 5;

  return List.generate(count, (index) {
    final position = count == 1 ? 0.0 : index / (count - 1);
    final dayOffset = (totalDays * position).round();
    return _GanttTick(
      date: minDate.add(Duration(days: dayOffset)),
      position: position,
    );
  });
}

class _GanttAxis extends StatelessWidget {
  final double width;
  final DateTime minDate;
  final int totalDays;
  final List<_GanttTick> ticks;

  const _GanttAxis({
    required this.width,
    required this.minDate,
    required this.totalDays,
    required this.ticks,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 11,
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
              ...ticks.map((tick) {
                final x = tick.position * maxWidth;
                final safeLeft = math.max(0.0, math.min(maxWidth - 52, x - 26));
                return Stack(
                  children: [
                    Positioned(
                      left: x,
                      bottom: 8,
                      child: Container(
                        width: 1,
                        height: 8,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                    Positioned(
                      left: safeLeft,
                      bottom: 22,
                      width: 52,
                      child: Text(
                        _shortDayMonth(tick.date),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _GanttChartRow extends StatelessWidget {
  final _GanttVisualRow row;
  final double width;
  final DateTime minDate;
  final int totalDays;
  final List<_GanttTick> ticks;

  const _GanttChartRow({
    required this.row,
    required this.width,
    required this.minDate,
    required this.totalDays,
    required this.ticks,
  });

  @override
  Widget build(BuildContext context) {
    final actualColor = _statusColor(row.source.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 104,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.source.stageName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _StatusChip(
                    label: _statusLabel(row.source.status),
                    color: actualColor,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: width,
            height: 58,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GanttGridPainter(
                      ticks: ticks,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  top: 4,
                  child: Text(
                    'P',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const Positioned(
                  left: 0,
                  top: 31,
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                _GanttPositionedBar(
                  top: 5,
                  leftInset: 16,
                  rightInset: 8,
                  color: const Color(0xFF2563EB),
                  minDate: minDate,
                  totalDays: totalDays,
                  start: row.plannedStart,
                  end: row.plannedEnd,
                ),
                _GanttPositionedBar(
                  top: 32,
                  leftInset: 16,
                  rightInset: 8,
                  color: actualColor,
                  minDate: minDate,
                  totalDays: totalDays,
                  start: row.actualStart,
                  end: row.actualEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GanttGridPainter extends CustomPainter {
  final List<_GanttTick> ticks;
  final Color color;

  const _GanttGridPainter({
    required this.ticks,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, 18), Offset(size.width, 18), paint);
    canvas.drawLine(Offset(0, 45), Offset(size.width, 45), paint);
    for (final tick in ticks) {
      final x = tick.position * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GanttGridPainter oldDelegate) {
    return oldDelegate.ticks != ticks || oldDelegate.color != color;
  }
}

class _GanttPositionedBar extends StatelessWidget {
  final double top;
  final double leftInset;
  final double rightInset;
  final Color color;
  final DateTime minDate;
  final int totalDays;
  final DateTime? start;
  final DateTime? end;

  const _GanttPositionedBar({
    required this.top,
    required this.leftInset,
    required this.rightInset,
    required this.color,
    required this.minDate,
    required this.totalDays,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = start != null || end != null;
    final safeStart = start ?? end;
    final safeEnd = end ?? start;
    final offsetDays = safeStart == null
        ? 0
        : math.max(0, safeStart.difference(minDate).inDays);
    final durationDays = safeStart == null || safeEnd == null
        ? 1
        : math.max(1, safeEnd.difference(safeStart).inDays + 1);
    final leftRatio = (offsetDays / totalDays).clamp(0.0, 0.96).toDouble();
    final rawWidth = (durationDays / totalDays).clamp(0.04, 1.0).toDouble();
    final widthRatio = math.min(rawWidth, math.max(0.04, 1.0 - leftRatio));

    if (!hasDate) return const SizedBox.shrink();

    return Positioned(
      left: leftInset,
      right: rightInset,
      top: top,
      child: SizedBox(
        height: 14,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth * leftRatio,
                  width: constraints.maxWidth * widthRatio,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
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

class _MiniQuantity extends StatelessWidget {
  final String label;
  final String value;
  final String uom;

  const _MiniQuantity({
    required this.label,
    required this.value,
    required this.uom,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uom.trim().isEmpty ? value : '$value $uom',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
        ),
      ],
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
  final bool compact;

  const _PebSummaryLoading({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final skeletons = List.generate(
      compact ? 3 : 5,
      (_) => Container(
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
    if (compact) {
      return Column(children: skeletons);
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: skeletons,
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

String _trackingModeLabel(String mode) {
  switch (mode) {
    case 'boq_work_assignment':
      return 'BOQ + Work Assignment';
    case 'boq_only':
      return 'BOQ Only Tracking';
    case 'work_assignment_only':
      return 'Work Assignment Tracking';
    case 'dpr_only':
      return 'DPR Only Tracking';
    default:
      return 'Project Tracking';
  }
}

String _trackingModeDescription(String mode) {
  switch (mode) {
    case 'boq_work_assignment':
      return 'Planned work is compared with actual DPR execution.';
    case 'boq_only':
      return 'Actual DPR progress is tracked against BOQ scope.';
    case 'work_assignment_only':
      return 'Assignment performance is tracked without BOQ scope.';
    case 'dpr_only':
      return 'Only executed DPR work is shown. Planning and delay are hidden.';
    default:
      return 'Tracking view changes automatically based on available data.';
  }
}

String _money(double value) {
  final abs = value.abs();
  if (abs >= 10000000) return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
  if (abs >= 100000) return '₹${(value / 100000).toStringAsFixed(2)}L';
  return '₹${_fmt(value)}';
}

String _dateLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')} '
      '${_monthShort(parsed.month)} ${parsed.year}';
}

String _monthShort(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

void _showRevenueBreakdown(BuildContext context, PebProfitLossModel data) {
  _showBreakdownSheet(
    context: context,
    title: 'Revenue Breakdown',
    subtitle: data.site.name,
    totalLabel: 'Total Revenue',
    total: data.totals.revenue,
    rows: data.revenueBreakdown
        .map((item) => _BreakdownRowData(
              title: item.activityName,
              amount: item.revenue,
              percentage: item.contributionPercentage,
              detail:
                  '${_fmt(item.quantity)} ${item.unit} · Rate ${_money(item.rate)} · ${item.source}',
            ))
        .toList(),
    showPie: false,
  );
}

void _showExpenseBreakdown(BuildContext context, PebProfitLossModel data) {
  _showBreakdownSheet(
    context: context,
    title: 'Expense Breakdown',
    subtitle: data.site.name,
    totalLabel: 'Total Expense',
    total: data.totals.expense,
    rows: data.expenseBreakdown
        .map((item) => _BreakdownRowData(
              title: item.category,
              amount: item.amount,
              percentage: item.contributionPercentage,
              detail: item.source,
            ))
        .toList(),
    showPie: true,
  );
}

void _showBreakdownSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String totalLabel,
  required double total,
  required List<_BreakdownRowData> rows,
  required bool showPie,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _BreakdownSheet(
      title: title,
      subtitle: subtitle,
      totalLabel: totalLabel,
      total: total,
      rows: rows,
      showPie: showPie,
    ),
  );
}

class _BreakdownRowData {
  final String title;
  final double amount;
  final double percentage;
  final String detail;

  const _BreakdownRowData({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.detail,
  });
}

class _BreakdownSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String totalLabel;
  final double total;
  final List<_BreakdownRowData> rows;
  final bool showPie;

  const _BreakdownSheet({
    required this.title,
    required this.subtitle,
    required this.totalLabel,
    required this.total,
    required this.rows,
    required this.showPie,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxAmount =
        rows.fold<double>(1, (max, row) => math.max(max, row.amount));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(totalLabel,
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  _money(total),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (showPie && rows.isNotEmpty) ...[
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CustomPaint(
                      painter: _ExpensePiePainter(rows: rows),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rows.take(5).map((row) {
                        final index = rows.indexOf(row);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _PieLegendRow(
                            color: _pieColor(index),
                            label: row.title,
                            value: '${row.percentage.toStringAsFixed(1)}%',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: _EmptyMiniState(text: 'No breakdown data available'),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _BreakdownBarRow(row: row, maxAmount: maxAmount);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BreakdownBarRow extends StatelessWidget {
  final _BreakdownRowData row;
  final double maxAmount;

  const _BreakdownBarRow({required this.row, required this.maxAmount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (row.amount / maxAmount).clamp(0.04, 1.0).toDouble();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${row.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  row.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _money(row.amount),
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpensePiePainter extends CustomPainter {
  final List<_BreakdownRowData> rows;

  const _ExpensePiePainter({required this.rows});

  @override
  void paint(Canvas canvas, Size size) {
    final total = rows.fold<double>(0, (sum, row) => sum + row.amount);
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;
    var start = -math.pi / 2;

    if (total <= 0) {
      paint.color = const Color(0xFFE5E7EB);
      canvas.drawArc(rect, 0, math.pi * 2, true, paint);
    } else {
      for (var i = 0; i < rows.length; i++) {
        final sweep = (rows[i].amount / total) * math.pi * 2;
        paint.color = _pieColor(i);
        canvas.drawArc(rect, start, sweep, true, paint);
        start += sweep;
      }
    }

    final holePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.28,
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpensePiePainter oldDelegate) =>
      oldDelegate.rows != rows;
}

class _PieLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _PieLegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

Color _pieColor(int index) {
  const colors = [
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFF0F766E),
    Color(0xFFDB2777),
  ];
  return colors[index % colors.length];
}

DateTime? _parseDate(String value) {
  if (value.isEmpty || value == 'null') return null;
  final parsed = DateTime.tryParse(value);
  return parsed;
}

String _shortDayMonth(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
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
