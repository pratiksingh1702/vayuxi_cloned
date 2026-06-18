// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'dart:ui' as ui;

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
    final selectedSite = ref.watch(selectedSiteProvider);
    final summaryAsync = ref.watch(pebWorkSummaryProvider);
    final profitLossAsync = ref.watch(pebProfitLossProvider);
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
          Expanded(
            child: _selectedTab == 0
                ? profitLossAsync.when(
                    loading: () => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      siteName: selectedSite?.siteName ?? 'Selected Site',
                      rangeLabel: _summaryRangeLabel(filter),
                      children: const [_PebSummaryLoading(compact: true)],
                    ),
                    error: (e, _) => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      siteName: selectedSite?.siteName ?? 'Selected Site',
                      rangeLabel: _summaryRangeLabel(filter),
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
                        siteName: profitLoss.site.name,
                        rangeLabel:
                            '${_dateLabel(profitLoss.fromDate)} - ${_dateLabel(profitLoss.toDate)}',
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
                      siteName: selectedSite?.siteName ?? 'Selected Site',
                      rangeLabel: _summaryRangeLabel(filter),
                      children: const [_PebSummaryLoading(compact: true)],
                    ),
                    error: (e, _) => _PebTabbedScroll(
                      controller: _controller,
                      selectedTab: _selectedTab,
                      onTabChanged: (index) =>
                          setState(() => _selectedTab = index),
                      siteName: selectedSite?.siteName ?? 'Selected Site',
                      rangeLabel: _summaryRangeLabel(filter),
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
                        siteName: selectedSite?.siteName ?? 'Selected Site',
                        rangeLabel: _summaryRangeLabel(filter),
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
    if (mode == 'boq_work_assignment' || mode == 'work_assignment_only') {
      return [_PebPlanningTrackingView(summary: summary)];
    }
    if (mode == 'boq_only') {
      return [_PebBoqTrackingView(summary: summary)];
    }
    return [_PebDprTrackingView(summary: summary)];
  }
}

// ignore: unused_element
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

// ignore: unused_element
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

// ignore: unused_element
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

class _PebPlanningTrackingView extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PebPlanningTrackingView({required this.summary});

  @override
  Widget build(BuildContext context) {
    final stages = _visibleTrackingStages(summary);
    return Column(
      children: [
        _PebTrackingModeBanner(summary: summary),
        const SizedBox(height: 8),
        _PlanningProgressCard(summary: summary),
        const SizedBox(height: 8),
        _StageAssignmentPerformanceCard(stages: stages),
        const SizedBox(height: 8),
        _StageWiseCompactProgressCard(stages: stages),
        const SizedBox(height: 8),
        _PlanningInsightGrid(summary: summary),
        const SizedBox(height: 8),
        _PebTrendSection(
          points: summary.plannedVsActual,
          title: 'Plan vs Actual Trend',
          subtitle: 'Date-wise planned quantity compared with actual DPR',
        ),
        const SizedBox(height: 8),
        _DelayedActivitiesCard(rows: summary.delayAnalysis),
        const SizedBox(height: 8),
        _AssignmentHealthCard(summary: summary),
        const SizedBox(height: 10),
        const _TrackingFooterActions(),
      ],
    );
  }
}

class _PebBoqTrackingView extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PebBoqTrackingView({required this.summary});

  @override
  Widget build(BuildContext context) {
    final stages = summary.stages;
    return Column(
      children: [
        _PebTrackingModeBanner(summary: summary),
        const SizedBox(height: 8),
        _BoqCompletionCard(summary: summary),
        const SizedBox(height: 8),
        _BoqStageProgressCard(stages: stages),
        const SizedBox(height: 8),
        _BoqStageFlowCard(stages: stages),
        const SizedBox(height: 8),
        _PebTrendSection(
          points: summary.plannedVsActual,
          title: 'Daily Progress Trend',
          subtitle: 'Completed quantity from DPR entries',
          actualOnly: true,
        ),
        const SizedBox(height: 8),
        _ItemsRequiringAttentionCard(stages: stages),
        const SizedBox(height: 8),
        _BoqProjectSummaryCard(summary: summary),
        const SizedBox(height: 10),
        const _TrackingFooterActions(),
      ],
    );
  }
}

class _PebDprTrackingView extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PebDprTrackingView({required this.summary});

  @override
  Widget build(BuildContext context) {
    final stages = _visibleTrackingStages(summary);
    return Column(
      children: [
        _PebTrackingModeBanner(summary: summary),
        const SizedBox(height: 8),
        _DprExecutedHeroCard(summary: summary),
        const SizedBox(height: 8),
        _DprStageActivityCard(stages: stages),
        const SizedBox(height: 8),
        _PebTrendSection(
          points: summary.plannedVsActual,
          title: 'Work Executed Trend',
          subtitle: 'Executed quantity from DPR entries only',
          actualOnly: true,
        ),
        const SizedBox(height: 10),
        const _TrackingFooterActions(),
      ],
    );
  }
}

class _PlanningProgressCard extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PlanningProgressCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assignment = summary.modeSummary.assignmentStatus;
    final planned = _firstPositive([
      assignment.planProgressPercentage,
      summary.overview.totalPlannedWeightMt > 0
          ? 100
          : summary.overview.overallProgressPercentage,
    ]);
    final actual = _firstPositive([
      assignment.actualProgressPercentage,
      summary.overview.overallProgressPercentage,
    ]);
    final difference = actual - planned;
    final behind = difference < 0;
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Overall Progress',
            subtitle: 'Plan progress compared with actual DPR progress',
            compact: true,
          ),
          const SizedBox(height: 12),
          _LabelProgressLine(
            label: 'Plan Progress',
            value: planned,
            color: const Color(0xFF5B21B6),
          ),
          const SizedBox(height: 12),
          _LabelProgressLine(
            label: 'Actual Progress',
            value: actual,
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TrackingMiniPanel(
                  title: 'Difference',
                  value: '${difference.toStringAsFixed(0)}%',
                  subtitle: behind ? 'Behind Plan' : 'Ahead / On Plan',
                  color: behind
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF059669),
                  icon: behind
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingMiniPanel(
                  title: 'Project Status',
                  value: behind ? 'Needs Attention' : 'On Track',
                  subtitle: behind
                      ? 'Behind plan in ${summary.overview.delayedStages} stages'
                      : 'Progress is aligned',
                  color: behind
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF059669),
                  icon: behind
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
          if (summary.overview.totalPlannedWeightMt > 0 ||
              summary.overview.totalActualWeightMt > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Planned ${_fmt(summary.overview.totalPlannedWeightMt)} MT  •  Actual ${_fmt(summary.overview.totalActualWeightMt)} MT',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageAssignmentPerformanceCard extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _StageAssignmentPerformanceCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage Assignment Performance',
            subtitle: 'Assigned plan, completed actual and difference by stage',
            compact: true,
          ),
          if (stages.isEmpty)
            const _EmptyMiniState(text: 'No assignment performance found')
          else ...[
            const SizedBox(height: 8),
            ...stages.map((stage) => _StagePerformanceRow(stage: stage)),
            const Divider(height: 20),
            _StagePerformanceTotal(stages: stages),
          ],
        ],
      ),
    );
  }
}

class _StageWiseCompactProgressCard extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _StageWiseCompactProgressCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage-wise Progress',
            subtitle: 'Plan and actual percentage for each work stage',
            compact: true,
          ),
          if (stages.isEmpty)
            const _EmptyMiniState(text: 'No stage-wise progress found')
          else
            SizedBox(
              height: 122,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: stages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _StageFlowMiniCard(
                  stage: stages[index],
                  index: index + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanningInsightGrid extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _PlanningInsightGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final todayAssigned = summary.plannedVsActual.isNotEmpty
        ? summary.plannedVsActual.last.plannedWeightMt
        : summary.overview.totalPlannedWeightMt;
    final todayActual = summary.plannedVsActual.isNotEmpty
        ? summary.plannedVsActual.last.actualWeightMt
        : summary.overview.totalActualWeightMt;
    final achievement =
        todayAssigned > 0 ? (todayActual / todayAssigned) * 100 : 0.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SummaryCard(
            child: Column(
              children: [
                _TinyMetricLine(
                  icon: Icons.assignment_outlined,
                  label: 'Work Assigned Today',
                  value: '${_fmt(todayAssigned)} MT',
                ),
                const Divider(height: 18),
                _TinyMetricLine(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Work Completed Today',
                  value: '${_fmt(todayActual)} MT',
                ),
                const Divider(height: 18),
                _TinyMetricLine(
                  icon: Icons.flag_outlined,
                  label: 'Today Achievement',
                  value: '${achievement.clamp(0, 999).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DelayedActivitiesCard extends StatelessWidget {
  final List<PebDelayRow> rows;

  const _DelayedActivitiesCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final delayed = rows.where((row) => row.delayDays > 0).take(4).toList();
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Delayed Activities',
            subtitle: 'Stages that need attention',
            compact: true,
          ),
          if (delayed.isEmpty)
            const _EmptyMiniState(text: 'No delayed activity found')
          else
            ...delayed.map(
              (row) => _SimpleAttentionRow(
                title: row.stageName,
                subtitle: row.plannedEndDate.isEmpty
                    ? 'Target date unavailable'
                    : 'Target ${_shortDate(row.plannedEndDate)}',
                trailing: '${row.delayDays} days',
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentHealthCard extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _AssignmentHealthCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final onSchedule = summary.stages
        .where((stage) =>
            stage.status == 'completed' || stage.status == 'in_progress')
        .length;
    final behind = summary.stages
        .where((stage) =>
            stage.status == 'delayed' || stage.status == 'completed_late')
        .length;
    final ahead =
        summary.stages.where((stage) => stage.difference.weightMt < 0).length;
    return _SummaryCard(
      child: Row(
        children: [
          Expanded(
            child: _HealthMetric(
              icon: Icons.schedule_rounded,
              color: const Color(0xFF059669),
              value: '$onSchedule',
              label: 'On Schedule',
            ),
          ),
          Expanded(
            child: _HealthMetric(
              icon: Icons.history_toggle_off_rounded,
              color: const Color(0xFFF59E0B),
              value: '$behind',
              label: 'Behind',
            ),
          ),
          Expanded(
            child: _HealthMetric(
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF2563EB),
              value: '$ahead',
              label: 'Ahead',
            ),
          ),
          Expanded(
            child: _HealthMetric(
              icon: Icons.format_list_bulleted_rounded,
              color: const Color(0xFF7C3AED),
              value: '${summary.overview.totalAssigned}',
              label: 'Assigned',
            ),
          ),
        ],
      ),
    );
  }
}

class _BoqCompletionCard extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _BoqCompletionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scope = summary.modeSummary.boqScope;
    final completion = _firstPositive([
      scope.completionPercentage,
      summary.overview.overallProgressPercentage,
    ]);
    final completed = _firstPositive([
      scope.completed.weightMt,
      summary.overview.totalActualWeightMt,
    ]);
    final total = _firstPositive([
      scope.totalScope.weightMt,
      summary.overview.totalBoqWeightMt,
    ]);
    final remaining = math.max(0.0, total - completed);
    final cs = Theme.of(context).colorScheme;
    return _SummaryCard(
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: CustomPaint(
              painter: _SingleDonutPainter(
                percentage: completion.clamp(0, 100),
                color: const Color(0xFF5B21B6),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${completion.clamp(0, 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Complete',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _TinyMetricLine(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Total Completed',
                  value: '${_fmt(completed)} MT',
                ),
                const Divider(height: 18),
                _TinyMetricLine(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total BOQ Scope',
                  value: '${_fmt(total)} MT',
                ),
                const Divider(height: 18),
                _TinyMetricLine(
                  icon: Icons.pie_chart_outline_rounded,
                  label: 'Remaining Scope',
                  value: '${_fmt(remaining)} MT',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoqStageProgressCard extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _BoqStageProgressCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage-wise Progress',
            subtitle: 'Completed quantity compared with BOQ scope',
            compact: true,
          ),
          if (stages.isEmpty)
            const _EmptyMiniState(text: 'No BOQ stage progress found')
          else
            ...stages.map((stage) => _BoqStageProgressRow(stage: stage)),
        ],
      ),
    );
  }
}

class _BoqStageFlowCard extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _BoqStageFlowCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage Flow',
            subtitle: 'Scope moving through configured stages',
            compact: true,
          ),
          if (stages.isEmpty)
            const _EmptyMiniState(text: 'No stage flow available')
          else
            ...List.generate(stages.length, (index) {
              final stage = stages[index];
              return Column(
                children: [
                  _StageFlowLine(stage: stage, index: index + 1),
                  if (index != stages.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _ItemsRequiringAttentionCard extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _ItemsRequiringAttentionCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    final attention = stages
        .where((stage) =>
            stage.progressPercentage < 50 && stage.actual.weightMt > 0)
        .take(4)
        .toList();
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Items Requiring Attention',
            subtitle: 'Stages with slow movement',
            compact: true,
          ),
          if (attention.isEmpty)
            const _EmptyMiniState(text: 'No attention item found')
          else
            ...attention.map(
              (stage) => _SimpleAttentionRow(
                title: stage.stageName,
                subtitle:
                    'Progress ${stage.progressPercentage.toStringAsFixed(0)}%',
                trailing: '${_fmt(stage.actual.weightMt)} MT',
              ),
            ),
        ],
      ),
    );
  }
}

class _BoqProjectSummaryCard extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _BoqProjectSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final scope = summary.modeSummary.boqScope;
    final total = _firstPositive([
      scope.totalScope.weightMt,
      summary.overview.totalBoqWeightMt,
    ]);
    final completed = _firstPositive([
      scope.completed.weightMt,
      summary.overview.totalActualWeightMt,
    ]);
    final remaining = math.max(0.0, total - completed);
    final avg = summary.plannedVsActual.isEmpty
        ? 0.0
        : summary.plannedVsActual
                .fold<double>(0, (sum, point) => sum + point.actualWeightMt) /
            summary.plannedVsActual.length;
    return _SummaryCard(
      child: Row(
        children: [
          Expanded(
            child: _HealthMetric(
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF5B21B6),
              value: '${_fmt(total)} MT',
              label: 'BOQ Scope',
            ),
          ),
          Expanded(
            child: _HealthMetric(
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF059669),
              value: '${_fmt(completed)} MT',
              label: 'Completed',
            ),
          ),
          Expanded(
            child: _HealthMetric(
              icon: Icons.timelapse_rounded,
              color: const Color(0xFFF59E0B),
              value: '${_fmt(remaining)} MT',
              label: 'Remaining',
            ),
          ),
          Expanded(
            child: _HealthMetric(
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF2563EB),
              value: '${_fmt(avg)} MT',
              label: 'Avg Daily',
            ),
          ),
        ],
      ),
    );
  }
}

class _DprExecutedHeroCard extends StatelessWidget {
  final PebWorkSummaryModel summary;

  const _DprExecutedHeroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final executed = _firstPositive([
      summary.modeSummary.actualOnly.executed.weightMt,
      summary.overview.totalActualWeightMt,
      summary.stages
          .fold<double>(0, (sum, stage) => sum + stage.actual.weightMt),
    ]);
    final cs = Theme.of(context).colorScheme;
    return _SummaryCard(
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.55),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.precision_manufacturing_rounded,
              color: cs.primary,
              size: 42,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Work Executed',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(executed)} MT',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                  ),
                ),
                Text(
                  'During selected period',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
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

class _DprStageActivityCard extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _DprStageActivityCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'Stage Activity Summary',
            subtitle: 'Quantities are based on DPR entries only',
            compact: true,
          ),
          if (stages.isEmpty)
            const _EmptyMiniState(text: 'No DPR activity found')
          else
            ...List.generate(
              stages.length,
              (index) => _DprStageActivityRow(
                stage: stages[index],
                index: index + 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _LabelProgressLine extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _LabelProgressLine({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              minHeight: 9,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            '${value.clamp(0, 999).toStringAsFixed(0)}%',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingMiniPanel extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _TrackingMiniPanel({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePerformanceRow extends StatelessWidget {
  final PebStageSummary stage;

  const _StagePerformanceRow({required this.stage});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final planned = _stagePlannedWeight(stage);
    final actual = _stageActualWeight(stage);
    final diff = actual - planned;
    final color = _performanceColor(stage.progressPercentage);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_stageIcon(stage.stageName), color: cs.primary, size: 22),
              const SizedBox(width: 10),
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
                '${stage.progressPercentage.clamp(0, 999).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _MiniQuantity(
                      label: 'Plan', value: _fmt(planned), uom: 'MT')),
              Expanded(
                  child: _MiniQuantity(
                      label: 'Actual', value: _fmt(actual), uom: 'MT')),
              Expanded(
                child: _MiniQuantity(
                  label: 'Diff',
                  value: '${diff >= 0 ? '+' : ''}${_fmt(diff)}',
                  uom: 'MT',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (stage.progressPercentage / 100).clamp(0, 1),
              minHeight: 7,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePerformanceTotal extends StatelessWidget {
  final List<PebStageSummary> stages;

  const _StagePerformanceTotal({required this.stages});

  @override
  Widget build(BuildContext context) {
    final planned = stages.fold<double>(
        0, (sum, stage) => sum + _stagePlannedWeight(stage));
    final actual =
        stages.fold<double>(0, (sum, stage) => sum + _stageActualWeight(stage));
    final diff = actual - planned;
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Total',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          'Plan ${_fmt(planned)} MT  •  Actual ${_fmt(actual)} MT  •  ${diff >= 0 ? '+' : ''}${_fmt(diff)} MT',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ],
    );
  }
}

class _StageFlowMiniCard extends StatelessWidget {
  final PebStageSummary stage;
  final int index;

  const _StageFlowMiniCard({required this.stage, required this.index});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final diff = _stageActualWeight(stage) - _stagePlannedWeight(stage);
    return Container(
      width: 104,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Icon(_stageIcon(stage.stageName), color: cs.primary, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stage.stageName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
          ),
          const Spacer(),
          _TinyBar(
              label: 'Plan',
              value: stage.progressPercentage / 100,
              color: const Color(0xFF5B21B6)),
          const SizedBox(height: 5),
          _TinyBar(
              label: 'Actual',
              value: stage.progressPercentage / 100,
              color: const Color(0xFF059669)),
          const SizedBox(height: 5),
          Text(
            'Diff ${diff >= 0 ? '+' : ''}${_fmt(diff)} MT',
            style: TextStyle(
              color:
                  diff < 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TinyBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 35, child: Text(label, style: const TextStyle(fontSize: 9))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 4,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _TinyMetricLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TinyMetricLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 18),
        const SizedBox(width: 10),
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
          value,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _SimpleAttentionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _SimpleAttentionRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _HealthMetric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }
}

class _BoqStageProgressRow extends StatelessWidget {
  final PebStageSummary stage;

  const _BoqStageProgressRow({required this.stage});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _performanceColor(stage.progressPercentage);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(_stageIcon(stage.stageName), color: cs.primary, size: 22),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              stage.stageName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (stage.progressPercentage / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              '${_fmt(_stageActualWeight(stage))} MT',
              textAlign: TextAlign.end,
              style:
                  TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label:
                '${stage.progressPercentage.clamp(0, 999).toStringAsFixed(0)}%',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _StageFlowLine extends StatelessWidget {
  final PebStageSummary stage;
  final int index;

  const _StageFlowLine({
    required this.stage,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = _performanceColor(stage.progressPercentage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withOpacity(0.14),
            child: Text(
              '$index',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stage.stageName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${_fmt(_stageActualWeight(stage))} MT',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DprStageActivityRow extends StatelessWidget {
  final PebStageSummary stage;
  final int index;

  const _DprStageActivityRow({
    required this.stage,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: cs.primaryContainer,
            child: Text(
              '$index',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(_stageIcon(stage.stageName), color: cs.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stage.stageName,
              style:
                  TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${_fmt(_stageActualWeight(stage))} MT',
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleDonutPainter extends CustomPainter {
  final double percentage;
  final Color color;

  const _SingleDonutPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = math.min(size.width, size.height) * 0.13;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE9E4FA);
    final valuePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
        rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2, false, basePaint);
    canvas.drawArc(
      rect.deflate(stroke / 2),
      -math.pi / 2,
      (percentage.clamp(0, 100) / 100) * math.pi * 2,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SingleDonutPainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}

class _TrackingFooterActions extends StatelessWidget {
  const _TrackingFooterActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_month_rounded),
            label: const Text('View Timeline'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download'),
          ),
        ),
      ],
    );
  }
}

class _PebTabbedScroll extends StatelessWidget {
  final ScrollController controller;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final String siteName;
  final String rangeLabel;
  final List<Widget> children;

  const _PebTabbedScroll({
    required this.controller,
    required this.selectedTab,
    required this.onTabChanged,
    required this.siteName,
    required this.rangeLabel,
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
          _PebContextHeader(
            siteName: siteName,
            rangeLabel: rangeLabel,
          ),
          const SizedBox(height: 18),
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

class _PebContextHeader extends StatelessWidget {
  final String siteName;
  final String rangeLabel;

  const _PebContextHeader({
    required this.siteName,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFF0E9FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: Color(0xFF5B2BBE),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      siteName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rangeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PebProfitLossView extends StatelessWidget {
  final PebProfitLossModel data;

  const _PebProfitLossView({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const revenueColor = Color(0xFF5B2BBE);
    const expenseColor = Color(0xFFFF3B72);
    final resultColor = data.totals.isProfit
        ? const Color(0xFF15803D)
        : const Color(0xFFCC1237);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _FinancialTile(
                title: 'Revenue',
                value: _moneyFull(data.totals.revenue),
                hint: 'Tap bar or card for details',
                icon: Icons.trending_up_rounded,
                color: revenueColor,
                tint: const Color(0xFFEAFBF2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _RevenueBreakdownPage(data: data),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FinancialTile(
                title: 'Expense',
                value: _moneyFull(data.totals.expense),
                hint: 'Tap bar or card for details',
                icon: Icons.trending_down_rounded,
                color: expenseColor,
                tint: const Color(0xFFFFEEF3),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ExpenseOverviewPage(data: data),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.totals.isProfit
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: resultColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.totals.isProfit ? 'Profit' : 'Loss',
                      style: TextStyle(
                        color: resultColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _moneyFull(data.totals.profitLoss.abs()),
                      style: TextStyle(
                        color: resultColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 52,
                width: 1,
                color: cs.outlineVariant.withOpacity(0.7),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Margin',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.totals.marginPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: resultColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ProfitLossChart(
          data: data,
          onRevenueTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => _RevenueBreakdownPage(data: data)),
          ),
          onExpenseTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _ExpenseOverviewPage(data: data)),
          ),
        ),
        const SizedBox(height: 12),
        _ProfitLossInsight(data: data),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: revenueColor,
                  side: const BorderSide(color: revenueColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
                style: FilledButton.styleFrom(
                  backgroundColor: revenueColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfitLossSiteHeader extends StatelessWidget {
  final PebProfitLossModel data;

  const _ProfitLossSiteHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFF0E9FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: Color(0xFF5B2BBE),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.site.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_dateLabel(data.fromDate)} - ${_dateLabel(data.toDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FinancialTile extends StatelessWidget {
  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  const _FinancialTile({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 172),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.65)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 21,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitLossChart extends ConsumerWidget {
  final PebProfitLossModel data;
  final VoidCallback onRevenueTap;
  final VoidCallback onExpenseTap;

  const _ProfitLossChart({
    required this.data,
    required this.onRevenueTap,
    required this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final filter = ref.watch(summaryFilterProvider);
    final notifier = ref.read(summaryFilterProvider.notifier);
    final visible = data.trend.isEmpty
        ? [
            PebProfitLossTrendPoint(
              label: _chartViewLabel(data.view),
              startDate: data.fromDate,
              endDate: data.toDate,
              revenue: data.totals.revenue,
              expense: data.totals.expense,
              loss:
                  data.totals.profitLoss < 0 ? data.totals.profitLoss.abs() : 0,
            ),
          ]
        : data.trend.take(12).toList();
    final maxAmount = visible.fold<double>(1, (max, point) {
      return math.max(max, math.max(point.revenue, point.expense));
    });
    final yMax = _niceChartMax(maxAmount);
    final isSinglePeriod = visible.length <= 1;
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<SummaryFilterType>(
                    value: filter.filterType,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                    items: SummaryFilterType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              _filterTypeLabel(type),
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (type) {
                      if (type != null) notifier.setFilterType(type);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  _chartViewLabel(data.view),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Amount (₹)',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: isSinglePeriod ? 300 : 260,
            child: _ProfitLossBarPlot(
              points: visible,
              maxAmount: yMax,
              singlePeriod: isSinglePeriod,
              onRevenueTap: onRevenueTap,
              onExpenseTap: onExpenseTap,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _LegendDot(
                color: const Color(0xFF5B2BBE),
                label: 'Revenue (${_moneyFull(data.totals.revenue)})',
              ),
              _LegendDot(
                color: const Color(0xFFFF3B72),
                label: 'Expense (${_moneyFull(data.totals.expense)})',
              ),
              if (!data.totals.isProfit)
                _LegendDot(
                  color: const Color(0xFFFF3B72),
                  label: 'Loss (${_moneyFull(data.totals.profitLoss.abs())})',
                  outline: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfitLossBarPlot extends StatelessWidget {
  final List<PebProfitLossTrendPoint> points;
  final double maxAmount;
  final bool singlePeriod;
  final VoidCallback onRevenueTap;
  final VoidCallback onExpenseTap;

  const _ProfitLossBarPlot({
    required this.points,
    required this.maxAmount,
    required this.singlePeriod,
    required this.onRevenueTap,
    required this.onExpenseTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final labels = _chartAxisLabels(maxAmount);
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in labels)
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  labels.length,
                  (_) => Container(
                    height: 1,
                    color: cs.outlineVariant.withOpacity(0.55),
                  ),
                ),
              ),
              Positioned.fill(
                top: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: singlePeriod
                      ? [
                          Expanded(
                            child: _SingleFinancialBar(
                              label: 'Revenue',
                              value: points.first.revenue,
                              maxAmount: maxAmount,
                              color: const Color(0xFF5B2BBE),
                              loss: points.first.loss,
                              onTap: onRevenueTap,
                            ),
                          ),
                          const SizedBox(width: 34),
                          Expanded(
                            child: _SingleFinancialBar(
                              label: 'Expense',
                              value: points.first.expense,
                              maxAmount: maxAmount,
                              color: const Color(0xFFFF3B72),
                              onTap: onExpenseTap,
                            ),
                          ),
                        ]
                      : points
                          .map(
                            (point) => Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: _GroupedFinancialBar(
                                  point: point,
                                  maxAmount: maxAmount,
                                  onRevenueTap: onRevenueTap,
                                  onExpenseTap: onExpenseTap,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool outline;

  const _LegendDot({
    required this.color,
    required this.label,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: outline ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: outline ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SingleFinancialBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxAmount;
  final Color color;
  final double loss;
  final VoidCallback onTap;

  const _SingleFinancialBar({
    required this.label,
    required this.value,
    required this.maxAmount,
    required this.color,
    required this.onTap,
    this.loss = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final heightFactor = (value / maxAmount).clamp(0.03, 1.0).toDouble();
    final lossFactor = (loss / maxAmount).clamp(0.0, 1.0).toDouble();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            _moneyFull(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: (heightFactor + lossFactor).clamp(0.03, 1.0),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (loss > 0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LossHatchPainter(color: color),
                        ),
                      ),
                    FractionallySizedBox(
                      heightFactor: heightFactor /
                          math.max(0.03, heightFactor + lossFactor),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedFinancialBar extends StatelessWidget {
  final PebProfitLossTrendPoint point;
  final double maxAmount;
  final VoidCallback onRevenueTap;
  final VoidCallback onExpenseTap;

  const _GroupedFinancialBar({
    required this.point,
    required this.maxAmount,
    required this.onRevenueTap,
    required this.onExpenseTap,
  });

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
                child: InkWell(
                  onTap: onRevenueTap,
                  child: FractionallySizedBox(
                    heightFactor: revenueHeight,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B2BBE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: InkWell(
                  onTap: onExpenseTap,
                  child: FractionallySizedBox(
                    heightFactor: expenseHeight,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B72),
                        borderRadius: BorderRadius.circular(6),
                      ),
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

class _LossHatchPainter extends CustomPainter {
  final Color color;

  const _LossHatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withOpacity(0.8);
    final hatchPaint = Paint()
      ..strokeWidth = 1
      ..color = color.withOpacity(0.12);
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, borderPaint);
    for (var x = -size.height; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x.toDouble(), size.height),
        Offset(x + size.height, 0),
        hatchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LossHatchPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProfitLossInsight extends StatelessWidget {
  final PebProfitLossModel data;

  const _ProfitLossInsight({required this.data});

  @override
  Widget build(BuildContext context) {
    final isProfit = data.totals.isProfit;
    final color = isProfit ? const Color(0xFF15803D) : const Color(0xFF5B2BBE);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isProfit ? Icons.lightbulb_rounded : Icons.tips_and_updates,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              isProfit
                  ? 'Revenue is higher than expenses. You made a profit of ${_moneyFull(data.totals.profitLoss.abs())} this period.'
                  : 'Expenses are higher than revenue. You are incurring a loss of ${_moneyFull(data.totals.profitLoss.abs())} this period.',
              style: const TextStyle(
                color: Color(0xFF171827),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueBreakdownPage extends StatefulWidget {
  final PebProfitLossModel data;

  const _RevenueBreakdownPage({required this.data});

  @override
  State<_RevenueBreakdownPage> createState() => _RevenueBreakdownPageState();
}

class _RevenueBreakdownPageState extends State<_RevenueBreakdownPage> {
  PebRevenueBreakdownItem? _selected;

  @override
  Widget build(BuildContext context) {
    final rows = [...widget.data.revenueBreakdown]
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final selected = _selected ?? (rows.isNotEmpty ? rows.first : null);
    return _BreakdownScaffold(
      title: 'Revenue Breakdown',
      data: widget.data,
      buttonLabel: 'Download Report',
      child: Column(
        children: [
          _TotalHeroCard(
            label: 'Total Revenue',
            value: _moneyFull(widget.data.totals.revenue),
            subtitle: 'From ${rows.length} Revenue Items',
            icon: Icons.savings_rounded,
          ),
          const SizedBox(height: 14),
          _RankedBreakdownCard(
            title: 'Revenue Contribution',
            subtitle: '(Ranked by Revenue)',
            itemTitle: 'Item / Activity',
            amountTitle: 'Revenue (₹)',
            axisTitle: 'Revenue (₹)',
            rows: rows
                .map(
                  (item) => _RankedBreakdownRow(
                    name: item.activityName,
                    amount: item.revenue,
                    contribution: item.contributionPercentage,
                    icon: Icons.engineering_rounded,
                    onTap: () => setState(() => _selected = item),
                  ),
                )
                .toList(),
          ),
          if (selected != null) ...[
            const SizedBox(height: 14),
            _RevenueDetailPanel(item: selected),
          ],
        ],
      ),
    );
  }
}

class _ExpenseOverviewPage extends StatefulWidget {
  final PebProfitLossModel data;

  const _ExpenseOverviewPage({required this.data});

  @override
  State<_ExpenseOverviewPage> createState() => _ExpenseOverviewPageState();
}

class _ExpenseOverviewPageState extends State<_ExpenseOverviewPage> {
  PebExpenseBreakdownItem? _selected;

  @override
  Widget build(BuildContext context) {
    final rows = _expenseRowsWithSalarySection(widget.data.expenseBreakdown)
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final selected = _selected ?? (rows.isNotEmpty ? rows.first : null);
    return _BreakdownScaffold(
      title: 'Expense Overview',
      data: widget.data,
      buttonLabel: 'Download Report',
      child: Column(
        children: [
          _TotalHeroCard(
            label: 'Total Expense',
            value: _moneyFull(widget.data.totals.expense),
            subtitle: 'From ${rows.length} Expense Categories',
            icon: Icons.savings_rounded,
          ),
          const SizedBox(height: 14),
          _RankedBreakdownCard(
            title: 'Expense Contribution',
            itemTitle: 'Category',
            amountTitle: 'Expense (₹)',
            axisTitle: 'Expense (₹)',
            rows: rows
                .map(
                  (item) => _RankedBreakdownRow(
                    name: item.category,
                    amount: item.amount,
                    contribution: item.contributionPercentage,
                    icon: _expenseIcon(item.category),
                    onTap: () => setState(() => _selected = item),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          _ExpenseInsight(rows: rows),
          if (selected != null) ...[
            const SizedBox(height: 14),
            _ExpenseDetailPanel(item: selected),
          ],
        ],
      ),
    );
  }
}

class _BreakdownScaffold extends StatelessWidget {
  final String title;
  final PebProfitLossModel data;
  final String buttonLabel;
  final Widget child;

  const _BreakdownScaffold({
    required this.title,
    required this.data,
    required this.buttonLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5B2BBE);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                children: [
                  _BreakdownHeader(title: title, data: data),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.6),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: purple,
                        side: const BorderSide(color: purple),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded),
                      label: Text(buttonLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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

class _BreakdownHeader extends StatelessWidget {
  final String title;
  final PebProfitLossModel data;

  const _BreakdownHeader({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ProfitLossSiteHeader(data: data),
      ],
    );
  }
}

class _TotalHeroCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  const _TotalHeroCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SummaryCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF5B2BBE),
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 94,
            height: 94,
            decoration: const BoxDecoration(
              color: Color(0xFFF0E9FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF5B2BBE), size: 48),
          ),
        ],
      ),
    );
  }
}

class _RankedBreakdownRow {
  final String name;
  final double amount;
  final double contribution;
  final IconData icon;
  final VoidCallback onTap;

  const _RankedBreakdownRow({
    required this.name,
    required this.amount,
    required this.contribution,
    required this.icon,
    required this.onTap,
  });
}

class _RankedBreakdownCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String itemTitle;
  final String amountTitle;
  final String axisTitle;
  final List<_RankedBreakdownRow> rows;

  const _RankedBreakdownCard({
    required this.title,
    required this.itemTitle,
    required this.amountTitle,
    required this.axisTitle,
    required this.rows,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxAmount = rows.fold<double>(
      1,
      (max, row) => math.max(max, row.amount),
    );
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: title,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
              children: [
                if (subtitle.isNotEmpty)
                  TextSpan(
                    text: ' $subtitle',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  'Sr',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: Text(
                  itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Text(
                  amountTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              SizedBox(
                width: 76,
                child: Text(
                  'Contribution',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const _EmptyMiniState(text: 'No data available')
          else
            ...rows.asMap().entries.map(
                  (entry) => _RankedBarTile(
                    index: entry.key + 1,
                    row: entry.value,
                    maxAmount: maxAmount,
                  ),
                ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              axisTitle,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedBarTile extends StatelessWidget {
  final int index;
  final _RankedBreakdownRow row;
  final double maxAmount;

  const _RankedBarTile({
    required this.index,
    required this.row,
    required this.maxAmount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (row.amount / maxAmount).clamp(0.02, 1.0).toDouble();
    return InkWell(
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF0E9FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Color(0xFF5B2BBE),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  if (index <= 6) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _softRankColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        row.icon,
                        color: _rankIconColor(index),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                  ],
                  Expanded(
                    child: Text(
                      row.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 18,
                        backgroundColor:
                            const Color(0xFF5B2BBE).withOpacity(0.08),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF5B2BBE),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _moneyFull(row.amount),
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 76,
              child: Text(
                '${row.contribution.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF5B2BBE),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueDetailPanel extends StatelessWidget {
  final PebRevenueBreakdownItem item;

  const _RevenueDetailPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailPanel(
      title: item.activityName,
      icon: Icons.engineering_rounded,
      metrics: [
        ('Revenue', _moneyFull(item.revenue)),
        ('Contribution', '${item.contributionPercentage.toStringAsFixed(0)}%'),
        ('Executed Qty', '${_fmt(item.quantity)} ${item.unit}'),
        ('Rate', '${_moneyFull(item.rate)} / ${item.unit}'),
        ('Unit', item.unit.isEmpty ? '-' : item.unit),
      ],
      source: item.source,
      ctaLabel: 'View in Summary Sheet',
    );
  }
}

class _ExpenseDetailPanel extends StatelessWidget {
  final PebExpenseBreakdownItem item;

  const _ExpenseDetailPanel({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailPanel(
      title: item.category,
      icon: _expenseIcon(item.category),
      metrics: [
        ('Total Expense', _moneyFull(item.amount)),
        ('Contribution', '${item.contributionPercentage.toStringAsFixed(0)}%'),
        ('Entries', '${item.count}'),
      ],
      source: item.source,
      ctaLabel: 'View ${item.category} Details',
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<(String, String)> metrics;
  final String source;
  final String ctaLabel;

  const _DetailPanel({
    required this.title,
    required this.icon,
    required this.metrics,
    required this.source,
    required this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _SummaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 54,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0E9FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF5B2BBE)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: metrics
                  .map(
                    (metric) => Container(
                      width: 124,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: cs.outlineVariant),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric.$1,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            metric.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF5B2BBE),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: cs.outlineVariant),
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Source: $source',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () {},
              label: Text(ctaLabel),
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5B2BBE),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseInsight extends StatelessWidget {
  final List<PebExpenseBreakdownItem> rows;

  const _ExpenseInsight({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final top = rows.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Color(0xFF5B2BBE)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${top.category} expenses account for ${top.contributionPercentage.toStringAsFixed(0)}% of total site expenditure.',
              style: const TextStyle(
                color: Color(0xFF171827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF5B2BBE)),
        ],
      ),
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
            _PebTrendChart(
                points: points.take(8).toList(), actualOnly: actualOnly),
        ],
      ),
    );
  }
}

class _PebTrendChart extends StatelessWidget {
  final List<PebTrendPoint> points;
  final bool actualOnly;

  const _PebTrendChart({
    required this.points,
    required this.actualOnly,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cumulativePlan =
        points.fold<double>(0, (sum, point) => sum + point.plannedWeightMt);
    final cumulativeActual =
        points.fold<double>(0, (sum, point) => sum + point.actualWeightMt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 172,
          width: double.infinity,
          child: CustomPaint(
            painter: _PebTrendChartPainter(
              points: points,
              actualOnly: actualOnly,
              gridColor: cs.outlineVariant.withValues(alpha: 0.55),
              textColor: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!actualOnly) ...[
              const _LegendDot(color: Color(0xFF5B21B6), label: 'Plan'),
              const SizedBox(width: 12),
            ],
            const _LegendDot(color: Color(0xFF059669), label: 'Actual'),
          ],
        ),
        if (!actualOnly) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Cumulative Plan: ${_fmt(cumulativePlan)} MT    Cumulative Actual: ${_fmt(cumulativeActual)} MT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PebTrendChartPainter extends CustomPainter {
  final List<PebTrendPoint> points;
  final bool actualOnly;
  final Color gridColor;
  final Color textColor;

  const _PebTrendChartPainter({
    required this.points,
    required this.actualOnly,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 28.0;
    const top = 14.0;
    const bottom = 28.0;
    const right = 10.0;
    final chartWidth = math.max(1.0, size.width - left - right);
    final chartHeight = math.max(1.0, size.height - top - bottom);
    final maxValue = points.fold<double>(1, (max, point) {
      final plan = actualOnly ? 0.0 : point.plannedWeightMt;
      final actual = point.actualWeightMt;
      return math.max(max, math.max(plan, actual));
    });

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.1;

    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight - (chartHeight * i / 3);
      canvas.drawLine(
          Offset(left, y), Offset(size.width - right, y), gridPaint);
      _drawText(
        canvas,
        _fmt(maxValue * i / 3),
        Offset(0, y - 7),
        textColor,
        9,
      );
    }
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(left, top + chartHeight),
      Offset(size.width - right, top + chartHeight),
      axisPaint,
    );

    List<Offset> toOffsets(double Function(PebTrendPoint point) valueOf) {
      if (points.length == 1) {
        final y = top +
            chartHeight -
            (valueOf(points.first) / maxValue) * chartHeight;
        return [Offset(left + chartWidth / 2, y)];
      }
      return List.generate(points.length, (index) {
        final x = left + chartWidth * index / (points.length - 1);
        final y = top +
            chartHeight -
            (valueOf(points[index]) / maxValue) * chartHeight;
        return Offset(x, y);
      });
    }

    void drawSeries(List<Offset> offsets, Color color) {
      if (offsets.isEmpty) return;
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (final point in offsets.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
      final fillPath = Path.from(path)
        ..lineTo(offsets.last.dx, top + chartHeight)
        ..lineTo(offsets.first.dx, top + chartHeight)
        ..close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.16),
              color.withValues(alpha: 0.02)
            ],
          ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight)),
      );
      for (final point in offsets) {
        canvas.drawCircle(point, 3.2, Paint()..color = color);
      }
    }

    if (!actualOnly) {
      drawSeries(
          toOffsets((point) => point.plannedWeightMt), const Color(0xFF5B21B6));
    }
    drawSeries(
        toOffsets((point) => point.actualWeightMt), const Color(0xFF059669));

    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * i / (points.length - 1);
      _drawText(
        canvas,
        _compactPeriod(points[i].period),
        Offset(x - 14, top + chartHeight + 8),
        textColor,
        9,
      );
    }
  }

  String _compactPeriod(String value) {
    if (value.length <= 6) return value;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return '${parsed.day}/${parsed.month}';
    return value.substring(0, 6);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PebTrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.actualOnly != actualOnly ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

// ignore: unused_element
class _PebStageSection extends StatelessWidget {
  final List<PebStageSummary> stages;
  final String title;
  final String subtitle;

  const _PebStageSection({
    required this.stages,
    // ignore: unused_element_parameter
    this.title = 'Stage Wise Progress',
    // ignore: unused_element_parameter
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

// ignore: unused_element
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

// ignore: unused_element
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

// ignore: unused_element
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
        borderRadius: BorderRadius.circular(16),
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

// ignore: unused_element
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

List<PebStageSummary> _visibleTrackingStages(PebWorkSummaryModel summary) {
  final stages = summary.stages.where((stage) {
    return stage.assigned > 0 ||
        stage.inProgress > 0 ||
        stage.completed > 0 ||
        stage.pending > 0 ||
        stage.planned.qty > 0 ||
        stage.planned.weightMt > 0 ||
        stage.actual.qty > 0 ||
        stage.actual.weightMt > 0 ||
        stage.scope.qty > 0 ||
        stage.scope.weightMt > 0;
  }).toList();
  return stages.isEmpty ? summary.stages : stages;
}

double _stagePlannedWeight(PebStageSummary stage) {
  return _firstPositive([
    stage.planned.weightMt,
    stage.scope.weightMt,
    stage.planned.weightKg / 1000,
    stage.scope.weightKg / 1000,
    stage.planned.qty,
    stage.scope.qty,
  ]);
}

double _stageActualWeight(PebStageSummary stage) {
  return _firstPositive([
    stage.actual.weightMt,
    stage.actual.weightKg / 1000,
    stage.actual.qty,
  ]);
}

double _firstPositive(List<double> values) {
  for (final value in values) {
    if (value.isFinite && value > 0) return value;
  }
  return 0;
}

Color _performanceColor(double percentage) {
  if (percentage >= 90) return const Color(0xFF059669);
  if (percentage >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFFDC2626);
}

IconData _stageIcon(String stageName) {
  final normalized = stageName.toLowerCase();
  if (normalized.contains('unload')) return Icons.construction_rounded;
  if (normalized.contains('shift'))
    return Icons.precision_manufacturing_rounded;
  if (normalized.contains('erection') || normalized.contains('erect')) {
    return Icons.account_tree_rounded;
  }
  if (normalized.contains('align')) return Icons.center_focus_strong_rounded;
  if (normalized.contains('bolt') || normalized.contains('tight')) {
    return Icons.settings_input_component_rounded;
  }
  if (normalized.contains('patch') || normalized.contains('paint')) {
    return Icons.format_paint_rounded;
  }
  if (normalized.contains('qc') || normalized.contains('clearance')) {
    return Icons.fact_check_rounded;
  }
  if (normalized.contains('dispatch')) return Icons.local_shipping_outlined;
  return Icons.construction_rounded;
}

String _shortDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
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
    'Dec',
  ];
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]}';
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
      return 'Tracking Mode: Planning Based (With Work Assignment)';
    case 'boq_only':
      return 'Tracking Mode: BOQ Based (No Work Assignment)';
    case 'work_assignment_only':
      return 'Tracking Mode: Planning Based (Work Assignment Only)';
    case 'dpr_only':
      return 'Tracking Mode: DPR Based (No BOQ, No Work Assignment)';
    default:
      return 'Project Tracking';
  }
}

String _trackingModeDescription(String mode) {
  switch (mode) {
    case 'boq_work_assignment':
      return 'Progress is calculated from Work Assignment plan vs actual DPR progress.';
    case 'boq_only':
      return 'Progress is calculated from BOQ quantity against actual DPR progress.';
    case 'work_assignment_only':
      return 'Progress is calculated from planned assignments against actual DPR progress.';
    case 'dpr_only':
      return 'Dashboard shows insights based only on Daily Progress Report entries.';
    default:
      return 'Tracking view changes automatically based on available data.';
  }
}

String _moneyFull(double value) {
  final isNegative = value < 0;
  final rounded = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 2 == 0 && fromEnd != 2) {
      buffer.write(',');
    }
  }
  return '${isNegative ? '-' : ''}₹${buffer.toString()}';
}

double _niceChartMax(double amount) {
  if (amount <= 0) return 1;
  if (amount <= 100000) return 100000;
  final lakh = (amount / 100000).ceil();
  return (lakh + (lakh % 2 == 0 ? 0 : 1)) * 100000;
}

List<String> _chartAxisLabels(double maxAmount) {
  final labels = <String>[];
  for (var i = 5; i >= 0; i--) {
    final value = maxAmount * i / 5;
    labels.add(value == 0 ? '0' : '${(value / 100000).toStringAsFixed(0)}L');
  }
  return labels;
}

String _chartViewLabel(String view) {
  switch (view) {
    case 'daily':
      return 'Daily';
    case 'weekly':
      return 'Weekly';
    case 'yearly':
      return 'Yearly';
    default:
      return 'Monthly';
  }
}

String _filterTypeLabel(SummaryFilterType type) {
  switch (type) {
    case SummaryFilterType.daily:
      return 'Daily';
    case SummaryFilterType.weekly:
      return 'Weekly';
    case SummaryFilterType.monthly:
      return 'Monthly';
    case SummaryFilterType.yearly:
      return 'Yearly';
  }
}

IconData _expenseIcon(String category) {
  final text = category.toLowerCase();
  if (text.contains('salary') || text.contains('manpower')) {
    return Icons.person_rounded;
  }
  if (text.contains('material')) return Icons.work_rounded;
  if (text.contains('equipment') || text.contains('p&m')) {
    return Icons.settings_rounded;
  }
  if (text.contains('transport') || text.contains('travel')) {
    return Icons.local_shipping_rounded;
  }
  if (text.contains('food')) return Icons.restaurant_rounded;
  return Icons.more_horiz_rounded;
}

List<PebExpenseBreakdownItem> _expenseRowsWithSalarySection(
  List<PebExpenseBreakdownItem> rows,
) {
  final normalized = [...rows];
  final hasSalary = normalized.any(
    (item) => item.category.toLowerCase().contains('salary'),
  );
  if (!hasSalary) {
    normalized.add(
      const PebExpenseBreakdownItem(
        category: 'Salary',
        amount: 0,
        contributionPercentage: 0,
        count: 0,
        source: 'Salary Module',
      ),
    );
  }
  return normalized;
}

Color _softRankColor(int index) {
  const colors = [
    Color(0xFFF0E9FF),
    Color(0xFFEAFBF2),
    Color(0xFFEAF4FF),
    Color(0xFFFFF1E6),
    Color(0xFFFFF7D6),
    Color(0xFFF3F0FF),
  ];
  return colors[(index - 1) % colors.length];
}

Color _rankIconColor(int index) {
  const colors = [
    Color(0xFF5B2BBE),
    Color(0xFF12A66A),
    Color(0xFF2682D9),
    Color(0xFFFF8A1C),
    Color(0xFFD89A00),
    Color(0xFF6B5DD3),
  ];
  return colors[(index - 1) % colors.length];
}

String _dateLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return '${parsed.day.toString().padLeft(2, '0')} '
      '${_monthShort(parsed.month)} ${parsed.year}';
}

String _summaryRangeLabel(SummaryFilter filter) {
  switch (filter.filterType) {
    case SummaryFilterType.daily:
      return _dateLabel(filter.date.toIso8601String());
    case SummaryFilterType.weekly:
      return '${_dateLabel(filter.rangeFromDate.toIso8601String())} - '
          '${_dateLabel(filter.rangeToDate.toIso8601String())}';
    case SummaryFilterType.monthly:
      final year = int.tryParse(filter.year) ?? DateTime.now().year;
      final from = DateTime(year, filter.month, 1);
      final to = DateTime(year, filter.month + 1, 0);
      return '${_dateLabel(from.toIso8601String())} - '
          '${_dateLabel(to.toIso8601String())}';
    case SummaryFilterType.yearly:
      return '01 Jan ${filter.year} - 31 Dec ${filter.year}';
  }
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
