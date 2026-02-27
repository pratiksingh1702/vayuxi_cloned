import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../service/summaryService.dart';
import '../data/model_enums.dart';
import '../data/provider.dart';

class FinancialReportScreen extends ConsumerStatefulWidget {
  final SiteSummaryModel site;
  final SummaryFilter initialFilter;
  final String monthName;

  const FinancialReportScreen({
    super.key,
    required this.site,
    required this.initialFilter,
    required this.monthName,
  });

  @override
  ConsumerState<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> {
  bool _showWithGst = true;
  late SummaryFilter _localFilter;

  // Month names for dropdown
  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  final Map<String, int> _monthMap = const {
    'January': 1, 'February': 2, 'March': 3, 'April': 4,
    'May': 5, 'June': 6, 'July': 7, 'August': 8,
    'September': 9, 'October': 10, 'November': 11, 'December': 12,
  };

  late List<String> _yearOptions;

  // Local site data (re-fetched when filter changes)
  SiteSummaryModel? _currentSite;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _localFilter = widget.initialFilter;
    _currentSite = widget.site;
    _generateYearOptions();
  }

  void _generateYearOptions() {
    final now = DateTime.now();
    _yearOptions = List.generate(now.year - 2024, (i) => (now.year - i).toString());
  }

  SiteSummaryModel get site => _currentSite ?? widget.site;

  double get incomeValue {
    if (site.income == null) return site.weekly?.totalIncome ?? 0;
    return _showWithGst ? site.income!.total : site.income!.base;
  }

  double get expensesValue => site.expenses?.total ?? site.weekly?.totalExpenses ?? 0;
  double get profitValue => site.profit;
  bool get isProfit => profitValue >= 0;

  String get periodLabel {
    switch (_localFilter.filterType) {
      case SummaryFilterType.monthly:
        return '${_monthNames[_localFilter.month - 1]} ${_localFilter.year}';
      case SummaryFilterType.yearly:
        return _localFilter.year;
      case SummaryFilterType.daily:
        return DateFormat('dd MMM yyyy').format(_localFilter.date);
      case SummaryFilterType.weekly:
        return 'Week of ${DateFormat('dd MMM').format(_localFilter.date)}';
    }
  }

  Future<void> _refetchForSite() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final type = ref.read(typeProvider);
      final apiType = type == 'insulation_work' ? 'insulation' : 'mechnical';
      final dateStr =
          '${_localFilter.date.year}-${_localFilter.date.month.toString().padLeft(2, '0')}-${_localFilter.date.day.toString().padLeft(2, '0')}';

      final allSites = await SummaryService.fetchSummary(
        type: apiType,
        filterType: _localFilter.filterType,
        year: _localFilter.year,
        month: _localFilter.month,
        date: dateStr,
      );

      final match = allSites.firstWhere(
            (s) => s.siteId == widget.site.siteId,
        orElse: () => SiteSummaryModel.empty(widget.site.siteId, widget.site.siteName),
      );

      setState(() => _currentSite = match);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFilterTypeChanged(SummaryFilterType type) {
    setState(() => _localFilter = _localFilter.copyWith(filterType: type));
    _refetchForSite();
  }

  void _onMonthChanged(String monthName) {
    setState(() => _localFilter = _localFilter.copyWith(month: _monthMap[monthName]!));
    _refetchForSite();
  }

  void _onYearChanged(String year) {
    setState(() => _localFilter = _localFilter.copyWith(year: year));
    _refetchForSite();
  }

  void _onDateChanged(DateTime date) {
    setState(() => _localFilter = _localFilter.copyWith(date: date));
    _refetchForSite();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isProfit ? Colors.green : Colors.red;
    final isWeeklyOrDaily = _localFilter.filterType == SummaryFilterType.weekly ||
        _localFilter.filterType == SummaryFilterType.daily;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text(site.siteName),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Filter Controls ──────────────────────────────────────────────
            _buildFilterSection(),
            const SizedBox(height: 16),

            if (_isLoading)
              Container(
                height: 200,
                decoration: _cardDecoration(),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load data', style: TextStyle(color: Colors.red[700])),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _refetchForSite,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else ...[
                _buildHeader(themeColor),
                const SizedBox(height: 20),
                _buildSummaryCard(themeColor),
                const SizedBox(height: 20),
                _buildGstToggle(),
                const SizedBox(height: 20),
                isWeeklyOrDaily ? _buildHorizontalBarChart() : _buildVerticalBarChart(),
                const SizedBox(height: 20),
                _buildExpensePieChart(),
                const SizedBox(height: 20),
                _buildMetricsGrid(),
                const SizedBox(height: 32),
              ],

            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Filter Section ─────────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Period',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 12),

          // Filter type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SummaryFilterType.values.map((type) {
                final isSelected = _localFilter.filterType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _onFilterTypeChanged(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                            : [],
                      ),
                      child: Text(
                        _filterLabel(type),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Date/month/year selectors
          _buildDateSelectors(),
        ],
      ),
    );
  }

  Widget _buildDateSelectors() {
    switch (_localFilter.filterType) {
      case SummaryFilterType.monthly:
        return Row(children: [
          Expanded(child: _styledDropdown(
            value: _monthNames[_localFilter.month - 1],
            items: _monthNames,
            icon: Icons.calendar_month,
            onChanged: (v) => _onMonthChanged(v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: _styledDropdown(
            value: _localFilter.year,
            items: _yearOptions,
            icon: Icons.today,
            onChanged: (v) => _onYearChanged(v!),
          )),
        ]);

      case SummaryFilterType.yearly:
        return _styledDropdown(
          value: _localFilter.year,
          items: _yearOptions,
          icon: Icons.today,
          onChanged: (v) => _onYearChanged(v!),
        );

      case SummaryFilterType.daily:
      case SummaryFilterType.weekly:
        return Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _localFilter.date,
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (picked != null) _onDateChanged(picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(_localFilter.date),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[600]),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _styledDropdown(
            value: _localFilter.year,
            items: _yearOptions,
            icon: Icons.today,
            onChanged: (v) => _onYearChanged(v!),
          )),
        ]);
    }
  }

  Widget _styledDropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _filterLabel(SummaryFilterType type) {
    switch (type) {
      case SummaryFilterType.daily: return 'Daily';
      case SummaryFilterType.weekly: return 'Weekly';
      case SummaryFilterType.monthly: return 'Monthly';
      case SummaryFilterType.yearly: return 'Yearly';
    }
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color, color.withOpacity(0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(site.siteName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(periodLabel,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(isProfit ? '💰 Profitable Period' : '⚠️ Loss Period',
                  style: const TextStyle(fontSize: 13, color: Colors.white)),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Summary Card ───────────────────────────────────────────────────────────

  Widget _buildSummaryCard(Color color) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Text(isProfit ? 'Net Profit' : 'Net Loss',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(
          '₹${NumberFormat('#,##,###.##').format(profitValue.abs())}',
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(
            '${site.profitPercentage >= 0 ? '+' : ''}${site.profitPercentage.toStringAsFixed(2)}%',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    ),
  );

  // ── GST Toggle ─────────────────────────────────────────────────────────────

  Widget _buildGstToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: _cardDecoration(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Income Display', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              _showWithGst
                  ? 'Incl. GST  ₹${NumberFormat.compact().format(site.income?.total ?? 0)}'
                  : 'Excl. GST  ₹${NumberFormat.compact().format(site.income?.base ?? 0)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            Text('Excl.', style: TextStyle(fontSize: 12, color: !_showWithGst ? Colors.blue : Colors.grey)),
            Switch(
              value: _showWithGst,
              onChanged: (v) => setState(() => _showWithGst = v),
              activeColor: Colors.green,
            ),
            Text('Incl.', style: TextStyle(fontSize: 12, color: _showWithGst ? Colors.green : Colors.grey)),
          ],
        ),
      ],
    ),
  );

  // ── Vertical Bar Chart (monthly / yearly) ──────────────────────────────────

  Widget _buildVerticalBarChart() {
    final data = [
      _ChartData('Income', incomeValue, Colors.green),
      _ChartData('Expenses', expensesValue, Colors.red),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.bar_chart_rounded, Colors.blue, 'Income vs Expenses'),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(majorGridLines: const MajorGridLines(width: 0)),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compact(),
                majorGridLines: MajorGridLines(width: 1, color: Colors.grey[200]),
                axisLine: const AxisLine(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(enable: true, format: 'point.x : ₹point.y'),
              series: <CartesianSeries<_ChartData, String>>[
                ColumnSeries<_ChartData, String>(
                  dataSource: data,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.value,
                  pointColorMapper: (d, _) => d.color,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  width: 0.45,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    builder: (raw, point, series, pi, si) {
                      final d = raw as _ChartData;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: d.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('₹${NumberFormat.compact().format(d.value)}',
                            style: TextStyle(color: d.color, fontWeight: FontWeight.bold, fontSize: 11)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal Grouped Bar Chart (weekly = 7 days, daily = single day) ─────
  Widget _buildHorizontalBarChart() {
    final isWeekly = _localFilter.filterType == SummaryFilterType.weekly;

    List<_BarEntry> chartEntries = [];

    if (isWeekly && site.weekly != null) {
      final entries = site.weekly!.orderedEntries;
      chartEntries = entries.map((e) => _BarEntry(
        label: _formatDay(e.key),
        income: e.value.income,
        expense: e.value.totalExpenses,
      )).toList();
    } else {
      chartEntries = [
        _BarEntry(
          label: DateFormat('dd MMM').format(_localFilter.date),
          income: incomeValue,
          expense: expensesValue,
        ),
      ];
    }

    final chartHeight = isWeekly ? 460.0 : 220.0;
    final barThickness = isWeekly ? 28.0 : 40.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.bar_chart_rounded,
            Colors.blue,
            isWeekly ? 'Weekly: Income vs Expenses' : 'Daily: Income vs Expenses',
          ),
          const SizedBox(height: 8),
          Row(children: [
            _legendDot(Colors.blue, 'Income'),
            const SizedBox(width: 16),
            _legendDot(Colors.orange, 'Expenses'),
          ]),
          const SizedBox(height: 20),

          // ── Custom horizontal bar chart ─────────────────────────
          SizedBox(
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxVal = chartEntries.fold<double>(
                  0,
                      (prev, e) => [prev, e.income, e.expense].reduce(
                        (a, b) => a > b ? a : b,
                  ),
                );
                final availableWidth = constraints.maxWidth;
                // Left label column width
                const labelWidth = 60.0;
                final barAreaWidth = availableWidth - labelWidth - 8;

                return Column(
                  children: [
                    // ── X-axis money labels at top ────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: labelWidth + 8),
                      child: _buildMoneyAxisLabels(barAreaWidth, maxVal),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chartEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final entry = chartEntries[i];
                          return _buildBarRow(
                            entry: entry,
                            maxVal: maxVal,
                            labelWidth: labelWidth,
                            barAreaWidth: barAreaWidth,
                            barThickness: barThickness,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Bottom axis line ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(left: labelWidth + 8),
                      child: Container(height: 1, color: Colors.grey[300]),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyAxisLabels(double width, double maxVal) {
    const steps = 4;
    return SizedBox(
      height: 18,
      child: Stack(
        children: List.generate(steps + 1, (i) {
          final fraction = i / steps;
          final value = maxVal * fraction;
          final label = NumberFormat.compact().format(value);
          return Positioned(
            left: width * fraction - (i == steps ? 30 : 0),
            child: Text(
              '₹$label',
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBarRow({
    required _BarEntry entry,
    required double maxVal,
    required double labelWidth,
    required double barAreaWidth,
    required double barThickness,
  }) {
    final incomeFraction = maxVal > 0 ? (entry.income / maxVal).clamp(0.0, 1.0) : 0.0;
    final expenseFraction = maxVal > 0 ? (entry.expense / maxVal).clamp(0.0, 1.0) : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Day / date label on LEFT (Y axis)
        SizedBox(
          width: labelWidth,
          child: Text(
            entry.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Bars area
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Income bar
              _animatedBar(
                fraction: incomeFraction,
                barAreaWidth: barAreaWidth,
                thickness: barThickness,
                color: Colors.blue,
                value: entry.income,
                labelColor: Colors.blue[700]!,
              ),
              const SizedBox(height: 4),
              // Expense bar
              _animatedBar(
                fraction: expenseFraction,
                barAreaWidth: barAreaWidth,
                thickness: barThickness,
                color: Colors.orange,
                value: entry.expense,
                labelColor: Colors.orange[700]!,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _animatedBar({
    required double fraction,
    required double barAreaWidth,
    required double thickness,
    required Color color,
    required double value,
    required Color labelColor,
  }) {
    final barWidth = barAreaWidth * fraction;
    final showLabel = barWidth > 30;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background track
        Container(
          height: thickness,
          width: barAreaWidth,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Filled bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          height: thickness,
          width: barWidth.isNaN || barWidth < 0 ? 0 : barWidth,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerRight,
          child: showLabel
              ? Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              '₹${NumberFormat.compact().format(value)}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : null,
        ),
        // Label outside bar when bar is too short
        if (!showLabel && value > 0)
          Positioned(
            left: barWidth + 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                '₹${NumberFormat.compact().format(value)}',
                style: TextStyle(
                  fontSize: 9,
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':    return 'Mon';
      case 'tuesday':   return 'Tue';
      case 'wednesday': return 'Wed';
      case 'thursday':  return 'Thu';
      case 'friday':    return 'Fri';
      case 'saturday':  return 'Sat';
      case 'sunday':    return 'Sun';
      default:          return day;
    }
  }
  // ── Expense Breakdown Pie ──────────────────────────────────────────────────

  Widget _buildExpensePieChart() {
    final List<_ChartData> pieData = [];

    // Color palette for slices
    final palette = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    if (site.expenses != null && site.expenses!.total > 0) {
      // Named expense categories from API
      final categories = site.expenses!.byType.toMap();
      int ci = 0;

      for (final e in categories.entries) {

          print('Category: ${e.key}');
          print('Original Value: ${e.value}');
          print('Injected Test Value: 123.00');

          pieData.add(
            _ChartData(
              e.key,
             e.value, // forced test value
              palette[ci % palette.length],
            ),
          );

          ci++;

      }

      print('Final pieData length: ${pieData.length}');
      for (final d in pieData) {
        print('Pie Slice -> ${d.label} : ${d.value}');
      }
      // Manpower salary as its own slice
      if (site.expenses!.manpowerSalary > 0) {
        pieData.add(_ChartData('Manpower Salary', site.expenses!.manpowerSalary, palette[ci % palette.length]));
      }
    } else if (site.weekly != null) {
      // Weekly: show salary vs site-expenses breakdown across days that have data
      final entries = site.weekly!.orderedEntries;
      int ci = 0;
      for (final e in entries) {
        if (e.value.totalExpenses > 0) {
          // Split into site expense + salary per day if available
          if (e.value.expenses > 0) {
            pieData.add(_ChartData('${_dayLabel(e.key)} Expenses', e.value.expenses, palette[ci % palette.length]));
            ci++;
          }
          if (e.value.salary > 0) {
            pieData.add(_ChartData('${_dayLabel(e.key)} Salary', e.value.salary, palette[ci % palette.length]));
            ci++;
          }
        }
      }
    }

    if (pieData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            _sectionTitle(Icons.pie_chart_rounded, Colors.purple, 'Expense Distribution'),
            const SizedBox(height: 20),
            Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No expense data for this period',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }

    final total = pieData.fold<double>(0, (s, d) => s + d.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.pie_chart_rounded, Colors.purple, 'Expense Distribution'),
          const SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: SfCircularChart(
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: const TextStyle(fontSize: 11),
                iconHeight: 10,
                iconWidth: 10,
              ),
              series: <CircularSeries>[
                DoughnutSeries<_ChartData, String>(
                  dataSource: pieData,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.value,
                  pointColorMapper: (d, _) => d.color,
                  dataLabelMapper: (d, _) =>
                  '${(d.value / total * 100).toStringAsFixed(1)}%',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    connectorLineSettings: ConnectorLineSettings(
                      type: ConnectorType.curve,
                      length: '8%',
                    ),
                  ),
                  innerRadius: '52%',
                  explode: true,
                  explodeGesture: ActivationMode.singleTap,
                  explodeOffset: '4%',
                  radius: '85%',
                ),
              ],
              annotations: [
                CircularChartAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      Text(
                        '₹${NumberFormat.compact().format(total)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expense breakdown list below the chart
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ...pieData.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: d.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(d.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                Text(
                  '₹${NumberFormat('#,##,###.##').format(d.value)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: d.color),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: d.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(d.value / total * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: d.color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Metrics Grid ───────────────────────────────────────────────────────────

  Widget _buildMetricsGrid() {
    final color = isProfit ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.analytics_outlined, Colors.orange, 'Detailed Metrics'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _metricCard(
              'Income (w/ GST)',
              '₹${NumberFormat('#,##,###').format(site.income?.total ?? incomeValue)}',
              Icons.arrow_upward_rounded, Colors.green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(
              'Income (excl. GST)',
              '₹${NumberFormat('#,##,###').format(site.income?.base ?? 0)}',
              Icons.money, Colors.green.shade700,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _metricCard(
              'GST Amount',
              '₹${NumberFormat('#,##,###').format(site.income?.gst ?? 0)}',
              Icons.receipt_long, Colors.blue,
            )),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(
              'Total Expenses',
              '₹${NumberFormat('#,##,###').format(expensesValue)}',
              Icons.arrow_downward_rounded, Colors.red,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _metricCard(
              isProfit ? 'Net Profit' : 'Net Loss',
              '₹${NumberFormat('#,##,###').format(profitValue.abs())}',
              isProfit ? Icons.trending_up : Icons.trending_down, color,
            )),
            const SizedBox(width: 12),
            Expanded(child: _metricCard(
              'Margin %',
              '${site.profitPercentage.abs().toStringAsFixed(2)}%',
              Icons.percent_rounded, color,
            )),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
    ],
  );

  Widget _sectionTitle(IconData icon, Color color, String title) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
      ),
    ],
  );

  Widget _metricCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700]))),
        ]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
  );

  /// Mon, Tue, Wed…
  String _dayLabel(String day) => day.substring(0, 3)[0].toUpperCase() + day.substring(1, 3);
}

// ─── Chart Data ────────────────────────────────────────────────────────────────

class _ChartData {
  final String label;
  final double value;
  final Color color;
  const _ChartData(this.label, this.value, this.color);
}
class _BarEntry {
  final String label;
  final double income;
  final double expense;
  const _BarEntry({required this.label, required this.income, required this.expense});
}