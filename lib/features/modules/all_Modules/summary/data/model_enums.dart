// ─── Enums ───────────────────────────────────────────────────────────────────

enum SummaryFilterType { daily, weekly, monthly, yearly }

// ─── Sub-models ──────────────────────────────────────────────────────────────

class IncomeModel {
  final double base;
  final double gst;
  final double total;

  const IncomeModel({required this.base, required this.gst, required this.total});

  factory IncomeModel.fromJson(Map<String, dynamic> json) => IncomeModel(
    base: (json['base'] ?? 0).toDouble(),
    gst: (json['gst'] ?? 0).toDouble(),
    total: (json['total'] ?? 0).toDouble(),
  );

  static IncomeModel get zero => const IncomeModel(base: 0, gst: 0, total: 0);
}

class ExpenseBreakdown {
  final double materialTools;
  final double travelling;
  final double food;
  final double accommodation;
  final double miscellaneous;
  final double advance;

  const ExpenseBreakdown({
    required this.materialTools,
    required this.travelling,
    required this.food,
    required this.accommodation,
    required this.miscellaneous,
    required this.advance,
  });

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> json) => ExpenseBreakdown(
    materialTools: (json['material_tools'] ?? 0).toDouble(),
    travelling: (json['travelling'] ?? 0).toDouble(),
    food: (json['food'] ?? 0).toDouble(),
    accommodation: (json['accommodation'] ?? 0).toDouble(),
    miscellaneous: (json['miscellaneous'] ?? 0).toDouble(),
    advance: (json['advance'] ?? 0).toDouble(),
  );

  static ExpenseBreakdown get zero => const ExpenseBreakdown(
    materialTools: 0,
    travelling: 0,
    food: 0,
    accommodation: 0,
    miscellaneous: 0,
    advance: 0,
  );

  Map<String, double> toMap() => {
    'Material & Tools': materialTools,
    'Travelling': travelling,
    'Food': food,
    'Accommodation': accommodation,
    'Miscellaneous': miscellaneous,
    'Advance': advance,
  };
}

class ExpenseModel {
  final ExpenseBreakdown byType;
  final double siteExpenses;
  final double manpowerSalary;
  final double total;

  const ExpenseModel({
    required this.byType,
    required this.siteExpenses,
    required this.manpowerSalary,
    required this.total,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    byType: ExpenseBreakdown.fromJson(json['byType'] ?? {}),
    siteExpenses: (json['siteExpenses'] ?? 0).toDouble(),
    manpowerSalary: (json['manpowerSalary'] ?? 0).toDouble(),
    total: (json['total'] ?? 0).toDouble(),
  );

  static ExpenseModel get zero => ExpenseModel(
    byType: ExpenseBreakdown.zero,
    siteExpenses: 0,
    manpowerSalary: 0,
    total: 0,
  );
}

class DaySummary {
  final double income;
  final double expenses;
  final double salary;
  final double totalExpenses;
  final double profit;

  const DaySummary({
    required this.income,
    required this.expenses,
    required this.salary,
    required this.totalExpenses,
    required this.profit,
  });

  factory DaySummary.fromJson(Map<String, dynamic> json) => DaySummary(
    income: (json['income'] ?? 0).toDouble(),
    expenses: (json['expenses'] ?? 0).toDouble(),
    salary: (json['salary'] ?? 0).toDouble(),
    totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
    profit: (json['profit'] ?? 0).toDouble(),
  );

  static DaySummary get zero =>
      const DaySummary(income: 0, expenses: 0, salary: 0, totalExpenses: 0, profit: 0);
}

class WeeklySummary {
  final Map<String, DaySummary> days;

  const WeeklySummary({required this.days});

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
    days: json.map((key, value) => MapEntry(key, DaySummary.fromJson(value))),
  );

  // Ordered days for display
  static const _orderedDays = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  List<MapEntry<String, DaySummary>> get orderedEntries =>
      _orderedDays.map((d) => MapEntry(d, days[d] ?? DaySummary.zero)).toList();

  double get totalIncome => days.values.fold(0, (s, d) => s + d.income);
  double get totalExpenses => days.values.fold(0, (s, d) => s + d.totalExpenses);
  double get totalProfit => days.values.fold(0, (s, d) => s + d.profit);
}

// ─── Main Site Summary Model ──────────────────────────────────────────────────

class SiteSummaryModel {
  final String siteId;
  final String siteName;

  // For monthly / yearly / daily
  final IncomeModel? income;
  final ExpenseModel? expenses;
  final double profit;
  final double profitPercentage;

  // For weekly
  final WeeklySummary? weekly;

  const SiteSummaryModel({
    required this.siteId,
    required this.siteName,
    this.income,
    this.expenses,
    required this.profit,
    required this.profitPercentage,
    this.weekly,
  });

  bool get hasData => profit != 0 || (income?.total ?? 0) != 0;

  factory SiteSummaryModel.fromJson(
      Map<String, dynamic> json,
      SummaryFilterType filterType,
      ) {
    if (filterType == SummaryFilterType.weekly) {
      final weekly = WeeklySummary.fromJson(json['weekly'] ?? {});
      return SiteSummaryModel(
        siteId: json['siteId'] ?? '',
        siteName: json['siteName'] ?? '',
        weekly: weekly,
        profit: weekly.totalProfit,
        profitPercentage: weekly.totalIncome > 0
            ? (weekly.totalProfit / weekly.totalIncome * 100)
            : 0,
      );
    }

    return SiteSummaryModel(
      siteId: json['siteId'] ?? '',
      siteName: json['siteName'] ?? '',
      income: IncomeModel.fromJson(json['income'] ?? {}),
      expenses: ExpenseModel.fromJson(json['expenses'] ?? {}),
      profit: (json['profit'] ?? 0).toDouble(),
      profitPercentage: (json['profitPercentage'] ?? 0).toDouble(),
    );
  }

  /// Empty model for sites with no data
  factory SiteSummaryModel.empty(String siteId, String siteName) => SiteSummaryModel(
    siteId: siteId,
    siteName: siteName,
    income: IncomeModel.zero,
    expenses: ExpenseModel.zero,
    profit: 0,
    profitPercentage: 0,
  );
}