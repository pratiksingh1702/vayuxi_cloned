import 'package:flutter/material.dart';
import 'package:untitled2/core/api/dio.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/profit.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/profit_loss_fusion.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/summaryService.dart';

import 'loss.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  int? selectedMonth;
  String? selectedYear;
  bool isLoading = false;
  List<dynamic> dataList = [];
  List<SiteModel> allSites = []; // Store all sites

  final Map<String, int> monthMap = const {
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

  List<String> yearOptions = [];

  @override
  void initState() {
    super.initState();
    DioClient.init();
    _generateYearOptions(2025);
    _fetchSites(); // Fetch all sites first
    // Set default values
    final now = DateTime.now();
    setState(() {
      selectedMonth = now.month;
      selectedYear = now.year.toString();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSummary();
    });
  }

  void _generateYearOptions(int startYear) {
    final currentYear = DateTime.now().year;
    final years = [
      for (var y = currentYear; y >= startYear; y--) y.toString(),
    ];
    setState(() => yearOptions = years);
  }

  // Fetch all sites
  Future<void> _fetchSites() async {
    try {
      final sites = ref.read(siteProvider).sites;
      setState(() => allSites = sites);
    } catch (e) {
      debugPrint("❌ Error fetching sites: $e");
    }
  }

  Future<void> _fetchSummary() async {
    if (selectedMonth == null || selectedYear == null) return;

    setState(() => isLoading = true);
    final type = ref.read(typeProvider);

    try {
      final data = type == "insulation_work"
          ? await SummaryAPI.fetchInsulationSummary(
          month: selectedMonth!, year: selectedYear!)
          : await SummaryAPI.fetchMechanicalSummary(
          month: selectedMonth!, year: selectedYear!);

      // Merge fetched data with all sites
      final mergedData = _mergeDataWithAllSites(data);
      setState(() => dataList = mergedData);
    } catch (e) {
      debugPrint("❌ Error fetching summary: $e");
      // Even if API fails, show all sites with 0 profit
      final emptyData = _createEmptyDataForAllSites();
      setState(() => dataList = emptyData);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Merge API data with all sites (fill missing sites with 0 values)
  List<dynamic> _mergeDataWithAllSites(List<dynamic> apiData) {
    final Map<String, dynamic> apiDataMap = {};

    // Convert API data to map with siteName as key
    for (final item in apiData) {
      final siteName = item['siteName']?.toString();
      if (siteName != null) {
        apiDataMap[siteName] = item;
      }
    }

    // Create merged list
    final List<dynamic> mergedList = [];

    for (final site in allSites) {
      final siteName = site.siteName;
      final apiItem = apiDataMap[siteName];

      if (apiItem != null) {
        // Site has data from API
        mergedList.add(apiItem);
      } else {
        // Site has no data - create entry with 0 values
        mergedList.add({
          'siteName': siteName,
          'income': 0.0,
          'expenses': 0.0,
          'profit': 0.0,
          'loss': 0.0,
          'profitPercentage': 0.0,
        });
      }
    }

    // Sort by site name alphabetically
    mergedList.sort((a, b) => (a['siteName'] ?? '').compareTo(b['siteName'] ?? ''));

    return mergedList;
  }

  // Create empty data for all sites (when API fails)
  List<dynamic> _createEmptyDataForAllSites() {
    final List<dynamic> emptyData = [];

    for (final site in allSites) {
      emptyData.add({
        'siteName': site.siteName,
        'income': 0.0,
        'expenses': 0.0,
        'profit': 0.0,
        'loss': 0.0,
        'profitPercentage': 0.0,
      });
    }

    // Sort by site name alphabetically
    emptyData.sort((a, b) => (a['siteName'] ?? '').compareTo(b['siteName'] ?? ''));

    return emptyData;
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = monthMap.keys.toList();
    final defaultMonth = selectedMonth != null ? monthNames[selectedMonth! - 1] : null;

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "P&L Summary"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // MONTH DROPDOWN
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: defaultMonth,
                        hint: const Text(
                          "Select Month",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey),
                        isExpanded: true,
                        items: monthNames
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          final monthNum = monthMap[value]!;
                          setState(() => selectedMonth = monthNum);
                          _fetchSummary();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // YEAR DROPDOWN
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedYear,
                        hint: const Text(
                          "Select Year",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey),
                        isExpanded: true,
                        items: yearOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          setState(() => selectedYear = value);
                          _fetchSummary();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Colors.blue)),
            )
          else
            Expanded(
              child: dataList.isEmpty
                  ? _buildNoSitesAvailable()
                  : ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  final item = dataList[index];
                  final profitPercentage = (item['profitPercentage'] ?? 0).toDouble();
                  final bool isProfit = profitPercentage >= 0;
                  final siteName = item['siteName']?.toString() ?? "Unknown Site";

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        siteName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Profit: ${profitPercentage.toStringAsFixed(2)}%",
                            style: TextStyle(
                              color: profitPercentage == 0
                                  ? Colors.grey
                                  : isProfit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (profitPercentage == 0)
                            const Text(
                              "No transactions for selected period",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      trailing: profitPercentage == 0
                          ? const Icon(Icons.remove_circle_outline, color: Colors.grey)
                          : Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        color: isProfit ? Colors.green : Colors.red,
                        size: 28,
                      ),
                        onTap: () {
                          final route = MaterialPageRoute(
                            builder: (_) => profitPercentage == 0
                                ? _buildZeroProfitScreen(item, defaultMonth ?? '')
                                : FinancialReportScreen(
                              siteName: siteName,
                              income: (item['income'] ?? 0.0).toDouble(),
                              expenses: (item['expenses'] ?? 0.0).toDouble(),
                              profit: (item['profit'] ?? 0.0).toDouble(),
                              profitPercentage: profitPercentage,
                              month: defaultMonth ?? '',
                              year: selectedYear ?? '',
                            ),
                          );
                          Navigator.push(context, route);
                        },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoSitesAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No Sites Available",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add sites to see P&L summary",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add site or refresh
              _fetchSites();
              _fetchSummary();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh"),
          ),
        ],
      ),
    );
  }

  Widget _buildZeroProfitScreen(Map<String, dynamic> item, String month) {
    final siteName = item['siteName']?.toString() ?? "Unknown Site";

    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: "Summary Details"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                siteName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Period: $month ${selectedYear ?? ''}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        "No Transactions",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "There were no income or expense transactions recorded for this site during the selected period.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryRow("Income", "₹0.00", Colors.green),
                      _buildSummaryRow("Expenses", "₹0.00", Colors.red),
                      const Divider(height: 30),
                      _buildSummaryRow("Profit/Loss", "₹0.00", Colors.blue),
                      _buildSummaryRow("Profit %", "0.00%", Colors.blue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Back to Summary"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}