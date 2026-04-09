import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/core/utlis/widgets/custom_scrollbar.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/profit_loss_fusion.dart';

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
    final filter = ref.watch(summaryFilterProvider);
    final notifier = ref.read(summaryFilterProvider.notifier);
    final summaryAsync = ref.watch(summaryDataProvider);
    final monthNames = _monthMap.keys.toList();
    final selectedMonthName = monthNames[filter.month - 1];

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.lightBlue,
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
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => notifier.setFilterType(type),
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
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
                value: selectedMonthName,
                items: monthNames,
                onChanged: (v) => notifier.setMonth(monthMap[v]!),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown(
                value: filter.year,
                items: yearOptions,
                onChanged: (v) => notifier.setYear(v!),
              )),
            ])
          else if (filter.filterType == SummaryFilterType.yearly)
            _dropdown(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${filter.date.day}/${filter.date.month}/${filter.date.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown(
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
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon:
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
    final pct = site.profitPercentage;
    final isProfit = pct >= 0;
    final hasData = site.hasData;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      elevation: 2,
      child: ListTile(
        title: Text(
          site.siteName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
                    ? Colors.grey
                    : isProfit
                        ? Colors.green
                        : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!hasData)
              const Text(
                "No transactions for selected period",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: !hasData
            ? const Icon(Icons.remove_circle_outline, color: Colors.grey)
            : Icon(
                isProfit ? Icons.trending_up : Icons.trending_down,
                color: isProfit ? Colors.green : Colors.red,
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

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: 6,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: Colors.white,
        elevation: 2,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 16,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 10,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Container(
              height: 28,
              width: 28,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No Sites Available",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text("Add sites to see P&L summary",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text("Failed to load data", style: TextStyle(fontSize: 16)),
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
