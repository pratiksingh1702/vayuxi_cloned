import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class FinancialReportScreen extends StatelessWidget {
  final String siteName;
  final dynamic income;
  final dynamic expenses;
  final dynamic profit;
  final double profitPercentage;
  final String month;
  final String year;

  const FinancialReportScreen({
    super.key,
    required this.siteName,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.profitPercentage,
    required this.month,
    required this.year,
  });

  bool get isProfit => profit >= 0;

  @override
  Widget build(BuildContext context) {
    final themeColor = isProfit ? Colors.green : Colors.red;
    final screenTitle = isProfit ? "Profit Report" : "Loss Report";
    final totalAmount = income + expenses.abs();

    // Data for bar chart
    final List<ChartData> barChartData = [
      ChartData('Income', income, themeColor),
      ChartData('Expenses', expenses.abs(), Colors.orange),
    ];

    // Data for pie chart
    final List<ChartData> pieChartData = [
      ChartData('Income', income, themeColor),
      ChartData('Expenses', expenses.abs(), Colors.orange),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: Text("$screenTitle - $siteName"),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(context, themeColor),
            const SizedBox(height: 24),

            // Key Metrics Cards
            _buildMetricsSection(),
            const SizedBox(height: 24),

            // Bar Chart - Income vs Expenses
            _buildBarChartSection(barChartData),
            const SizedBox(height: 24),

            // Pie Chart - Income/Expenses Distribution
            _buildPieChartSection(pieChartData, totalAmount),
            const SizedBox(height: 24),

            // Detailed Breakdown
            _buildBreakdownSection(),
            const SizedBox(height: 32),

            // Action Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  "Back to Dashboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isProfit ? Icons.trending_up : Icons.trending_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$month $year",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  siteName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isProfit ? "💰 Profitable Month" : "⚠️ Loss Making Month",
                  style: TextStyle(
                    fontSize: 14,
                    color: themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMetricRow(
            icon: Icons.arrow_upward,
            label: "Total Income",
            value: "₹${income.toStringAsFixed(2)}",
            color: Colors.green,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            icon: Icons.arrow_downward,
            label: "Total Expenses",
            value: "₹${expenses.abs().toStringAsFixed(2)}",
            color: Colors.orange,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            icon: isProfit ? Icons.add_chart : Icons.remove_circle_outline,
            label: isProfit ? "Net Profit" : "Net Loss",
            value: "₹${profit.abs().toStringAsFixed(2)}",
            color: isProfit ? Colors.green : Colors.red,
            isBold: true,
          ),
          const Divider(height: 24),
          _buildMetricRow(
            icon: Icons.percent,
            label: isProfit ? "Profit %" : "Loss %",
            value: "${profitPercentage.abs().toStringAsFixed(2)}%",
            color: isProfit ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSection(List<ChartData> chartData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                color: isProfit ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                "Income vs Expenses",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat('₹#'),
                labelStyle: const TextStyle(fontSize: 12),
              ),
              // Remove the explicit type annotation or use CartesianSeries
              series: <CartesianSeries<ChartData, String>>[
                BarSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.value,
                  pointColorMapper: (ChartData data, _) => data.color,
                  borderRadius: BorderRadius.circular(4),
                  width: 0.6,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildPieChartSection(List<ChartData> chartData, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                color: isProfit ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                "Financial Distribution",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SfCircularChart(
                    series: <CircularSeries>[
                      PieSeries<ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.category,
                        yValueMapper: (ChartData data, _) => data.value,
                        pointColorMapper: (ChartData data, _) => data.color,
                        dataLabelMapper: (ChartData data, _) =>
                        '${data.category}\n${(data.value / total * 100).toStringAsFixed(1)}%',
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                          textStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        explode: true,
                        explodeIndex: 0,
                      ),
                    ],
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                      overflowMode: LegendItemOverflowMode.wrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection() {
    final profitLossColor = isProfit ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: profitLossColor,
              ),
              const SizedBox(width: 8),
              Text(
                "Financial Summary",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            "Income",
            income.toStringAsFixed(2),
            Colors.green,
            Icons.arrow_upward,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            "Expenses",
            expenses.abs().toStringAsFixed(2),
            Colors.orange,
            Icons.arrow_downward,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey[300], thickness: 2),
          const SizedBox(height: 12),
          _buildSummaryItem(
            isProfit ? "Net Profit" : "Net Loss",
            profit.abs().toStringAsFixed(2),
            profitLossColor,
            isProfit ? Icons.add_circle : Icons.remove_circle,
            isBold: true,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            isProfit ? "Profit Margin" : "Loss Margin",
            "${profitPercentage.abs().toStringAsFixed(2)}%",
            profitLossColor,
            Icons.percent,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label,
      String value,
      Color color,
      IconData icon, {
        bool isBold = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            label.contains('%') ? value : "₹$value",
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String category;
  final double value;
  final Color color;

  ChartData(this.category, this.value, this.color);
}