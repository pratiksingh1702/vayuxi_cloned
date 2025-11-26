import 'package:flutter/material.dart';
import 'package:untitled2/core/api/dio.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/summary/screens/profit.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/summaryServic'
    'e.dart';
import 'loss.dart';
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen>{
  int? selectedMonth;
  String? selectedYear;
  bool isLoading = false;
  List<dynamic> dataList = [];

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
  }

  void _generateYearOptions(int startYear) {
    final currentYear = DateTime.now().year;
    final years = [
      for (var y = currentYear; y >= startYear; y--) y.toString(),
    ];
    setState(() => yearOptions = years);
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

      setState(() => dataList = data);
    } catch (e) {
      debugPrint("❌ Error fetching summary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch summary")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = monthMap.keys.toList();

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
                        value: selectedMonth != null
                            ? monthNames[selectedMonth! - 1]
                            : null,
                        hint: const Text(
                          "Input Text",
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
                          "Input Text",
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
          else if (dataList.isEmpty)
            const Expanded(
              child: Center(child: Text("No data available")),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  final item = dataList[index];
                  final profitPercentage = (item['profitPercentage'] ?? 0).toDouble();
                  final bool isProfit = profitPercentage >= 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.white,
                    child: ListTile(
                      title: Text(item['siteName'] ?? "Unknown Site"),
                      subtitle: Text("Profit: ${profitPercentage.toStringAsFixed(2)}%"),
                      trailing: Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        color: isProfit ? Colors.green : Colors.red,
                      ),
                      onTap: () {
                        final route = MaterialPageRoute(
                          builder: (_) => isProfit
                              ? ProfitScreen(
                            siteName: item['siteName'],
                            income: item['income'],
                            expenses: item['expenses'],
                            profit: item['profit'],
                            profitPercentage: profitPercentage,
                            month: monthNames[selectedMonth! - 1],
                            year: selectedYear!,
                          )
                              : LossScreen(
                            siteName: item['siteName'],
                            income: item['income'],
                            expenses: item['expenses'],
                            loss: item['loss'],
                            profitPercentage: profitPercentage,
                            month: monthNames[selectedMonth! - 1],
                            year: selectedYear!,
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
}
