// ─── Enums ───────────────────────────────────────────────────────────────────

enum SummaryFilterType { daily, weekly, monthly, yearly }

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) => _asDouble(value).round();

// ─── Sub-models ──────────────────────────────────────────────────────────────

class IncomeModel {
  final double base;
  final double gst;
  final double total;

  const IncomeModel(
      {required this.base, required this.gst, required this.total});

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

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> json) =>
      ExpenseBreakdown(
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

  static DaySummary get zero => const DaySummary(
      income: 0, expenses: 0, salary: 0, totalExpenses: 0, profit: 0);
}

class WeeklySummary {
  final Map<String, DaySummary> days;

  const WeeklySummary({required this.days});

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
        days:
            json.map((key, value) => MapEntry(key, DaySummary.fromJson(value))),
      );

  // Ordered days for display
  static const _orderedDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  List<MapEntry<String, DaySummary>> get orderedEntries =>
      _orderedDays.map((d) => MapEntry(d, days[d] ?? DaySummary.zero)).toList();

  double get totalIncome => days.values.fold(0, (s, d) => s + d.income);
  double get totalExpenses =>
      days.values.fold(0, (s, d) => s + d.totalExpenses);
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
  factory SiteSummaryModel.empty(String siteId, String siteName) =>
      SiteSummaryModel(
        siteId: siteId,
        siteName: siteName,
        income: IncomeModel.zero,
        expenses: ExpenseModel.zero,
        profit: 0,
        profitPercentage: 0,
      );
}

// ─── Erection / Fabrication Summary Analysis Models ─────────────────────────

class PebWorkSummaryModel {
  final String siteId;
  final String type;
  final String section;
  final PebOverview overview;
  final List<PebTrendPoint> plannedVsActual;
  final List<PebStageSummary> stages;
  final List<PebGanttRow> gantt;
  final List<PebDelayRow> delayAnalysis;
  final List<PebTeamSummary> teams;
  final PebMarkSummary markSummary;

  const PebWorkSummaryModel({
    required this.siteId,
    required this.type,
    required this.section,
    required this.overview,
    required this.plannedVsActual,
    required this.stages,
    required this.gantt,
    required this.delayAnalysis,
    required this.teams,
    required this.markSummary,
  });

  factory PebWorkSummaryModel.fromJson(Map<String, dynamic> json) {
    return PebWorkSummaryModel(
      siteId: json['siteId']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      overview: PebOverview.fromJson(json['overview'] ?? {}),
      plannedVsActual: (json['plannedVsActual'] as List? ?? [])
          .map((e) => PebTrendPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      stages: (json['stages'] as List? ?? [])
          .map((e) => PebStageSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      gantt: (json['gantt'] as List? ?? [])
          .map((e) => PebGanttRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      delayAnalysis: (json['delayAnalysis'] as List? ?? [])
          .map((e) => PebDelayRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      teams: (json['teams'] as List? ?? [])
          .map((e) => PebTeamSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      markSummary: PebMarkSummary.fromJson(json['markSummary'] ?? {}),
    );
  }
}

class PebOverview {
  final int totalBoqMarks;
  final double totalBoqQty;
  final double totalBoqWeightMt;
  final int totalAssigned;
  final int totalInProgress;
  final int totalCompleted;
  final int totalPending;
  final int delayedStages;
  final double overallProgressPercentage;

  const PebOverview({
    required this.totalBoqMarks,
    required this.totalBoqQty,
    required this.totalBoqWeightMt,
    required this.totalAssigned,
    required this.totalInProgress,
    required this.totalCompleted,
    required this.totalPending,
    required this.delayedStages,
    required this.overallProgressPercentage,
  });

  factory PebOverview.fromJson(Map<String, dynamic> json) => PebOverview(
        totalBoqMarks: _asInt(json['totalBoqMarks']),
        totalBoqQty: _asDouble(json['totalBoqQty']),
        totalBoqWeightMt: _asDouble(json['totalBoqWeightMt']),
        totalAssigned: _asInt(json['totalAssigned']),
        totalInProgress: _asInt(json['totalInProgress']),
        totalCompleted: _asInt(json['totalCompleted']),
        totalPending: _asInt(json['totalPending']),
        delayedStages: _asInt(json['delayedStages']),
        overallProgressPercentage: _asDouble(json['overallProgressPercentage']),
      );
}

class PebTrendPoint {
  final String period;
  final double plannedQty;
  final double actualQty;
  final double plannedWeightMt;
  final double actualWeightMt;
  final int plannedMarks;
  final int completedMarks;
  final double cumulativePlannedQty;
  final double cumulativeActualQty;

  const PebTrendPoint({
    required this.period,
    required this.plannedQty,
    required this.actualQty,
    required this.plannedWeightMt,
    required this.actualWeightMt,
    required this.plannedMarks,
    required this.completedMarks,
    required this.cumulativePlannedQty,
    required this.cumulativeActualQty,
  });

  factory PebTrendPoint.fromJson(Map<String, dynamic> json) => PebTrendPoint(
        period: json['period']?.toString() ?? '',
        plannedQty: _asDouble(json['plannedQty']),
        actualQty: _asDouble(json['actualQty']),
        plannedWeightMt: _asDouble(json['plannedWeightMt']),
        actualWeightMt: _asDouble(json['actualWeightMt']),
        plannedMarks: _asInt(json['plannedMarks']),
        completedMarks: _asInt(json['completedMarks']),
        cumulativePlannedQty: _asDouble(json['cumulativePlannedQty']),
        cumulativeActualQty: _asDouble(json['cumulativeActualQty']),
      );
}

class PebStageSummary {
  final String stageId;
  final String stageName;
  final String uom;
  final int assigned;
  final int pending;
  final int inProgress;
  final int completed;
  final double progressPercentage;
  final PebQuantity planned;
  final PebQuantity actual;
  final int delayDays;
  final String status;

  const PebStageSummary({
    required this.stageId,
    required this.stageName,
    required this.uom,
    required this.assigned,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.progressPercentage,
    required this.planned,
    required this.actual,
    required this.delayDays,
    required this.status,
  });

  factory PebStageSummary.fromJson(Map<String, dynamic> json) =>
      PebStageSummary(
        stageId: json['stageId']?.toString() ?? '',
        stageName: json['stageName']?.toString() ?? 'Stage',
        uom: json['uom']?.toString() ?? 'Nos',
        assigned: _asInt(json['assigned']),
        pending: _asInt(json['pending']),
        inProgress: _asInt(json['inProgress']),
        completed: _asInt(json['completed']),
        progressPercentage: _asDouble(json['progressPercentage']),
        planned: PebQuantity.fromJson(json['planned'] ?? {}),
        actual: PebQuantity.fromJson(json['actual'] ?? {}),
        delayDays: _asInt(json['delayDays']),
        status: json['status']?.toString() ?? '',
      );
}

class PebQuantity {
  final double qty;
  final double marks;
  final double weightMt;

  const PebQuantity({
    required this.qty,
    required this.marks,
    required this.weightMt,
  });

  factory PebQuantity.fromJson(Map<String, dynamic> json) => PebQuantity(
        qty: _asDouble(json['qty']),
        marks: _asDouble(json['marks']),
        weightMt: _asDouble(json['weightMt']),
      );
}

class PebGanttRow {
  final String stageName;
  final String plannedStartDate;
  final String plannedEndDate;
  final String actualStartDate;
  final String actualEndDate;
  final String status;
  final int delayDays;
  final double progressPercentage;

  const PebGanttRow({
    required this.stageName,
    required this.plannedStartDate,
    required this.plannedEndDate,
    required this.actualStartDate,
    required this.actualEndDate,
    required this.status,
    required this.delayDays,
    required this.progressPercentage,
  });

  factory PebGanttRow.fromJson(Map<String, dynamic> json) => PebGanttRow(
        stageName: json['stageName']?.toString() ?? 'Stage',
        plannedStartDate: json['plannedStartDate']?.toString() ?? '',
        plannedEndDate: json['plannedEndDate']?.toString() ?? '',
        actualStartDate: json['actualStartDate']?.toString() ?? '',
        actualEndDate: json['actualEndDate']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        delayDays: _asInt(json['delayDays']),
        progressPercentage: _asDouble(json['progressPercentage']),
      );
}

class PebDelayRow {
  final String stageName;
  final String plannedEndDate;
  final String actualEndDate;
  final int delayDays;
  final String status;
  final int pending;
  final int inProgress;
  final int completed;

  const PebDelayRow({
    required this.stageName,
    required this.plannedEndDate,
    required this.actualEndDate,
    required this.delayDays,
    required this.status,
    required this.pending,
    required this.inProgress,
    required this.completed,
  });

  factory PebDelayRow.fromJson(Map<String, dynamic> json) => PebDelayRow(
        stageName: json['stageName']?.toString() ?? 'Stage',
        plannedEndDate: json['plannedEndDate']?.toString() ?? '',
        actualEndDate: json['actualEndDate']?.toString() ?? '',
        delayDays: _asInt(json['delayDays']),
        status: json['status']?.toString() ?? '',
        pending: _asInt(json['pending']),
        inProgress: _asInt(json['inProgress']),
        completed: _asInt(json['completed']),
      );
}

class PebTeamSummary {
  final String teamId;
  final String teamName;
  final int assigned;
  final int inProgress;
  final int completed;
  final int pending;
  final double plannedQty;
  final double actualQty;
  final double plannedWeightMt;
  final double actualWeightMt;
  final double productivityPercentage;

  const PebTeamSummary({
    required this.teamId,
    required this.teamName,
    required this.assigned,
    required this.inProgress,
    required this.completed,
    required this.pending,
    required this.plannedQty,
    required this.actualQty,
    required this.plannedWeightMt,
    required this.actualWeightMt,
    required this.productivityPercentage,
  });

  factory PebTeamSummary.fromJson(Map<String, dynamic> json) => PebTeamSummary(
        teamId: json['teamId']?.toString() ?? '',
        teamName: json['teamName']?.toString() ?? 'Team',
        assigned: _asInt(json['assigned']),
        inProgress: _asInt(json['inProgress']),
        completed: _asInt(json['completed']),
        pending: _asInt(json['pending']),
        plannedQty: _asDouble(json['plannedQty']),
        actualQty: _asDouble(json['actualQty']),
        plannedWeightMt: _asDouble(json['plannedWeightMt']),
        actualWeightMt: _asDouble(json['actualWeightMt']),
        productivityPercentage: _asDouble(json['productivityPercentage']),
      );
}

class PebMarkSummary {
  final int totalMarks;
  final int assignedMarks;
  final int unassignedMarks;
  final int inProgressMarks;
  final int completedMarks;
  final int pendingMarks;

  const PebMarkSummary({
    required this.totalMarks,
    required this.assignedMarks,
    required this.unassignedMarks,
    required this.inProgressMarks,
    required this.completedMarks,
    required this.pendingMarks,
  });

  factory PebMarkSummary.fromJson(Map<String, dynamic> json) => PebMarkSummary(
        totalMarks: _asInt(json['totalMarks']),
        assignedMarks: _asInt(json['assignedMarks']),
        unassignedMarks: _asInt(json['unassignedMarks']),
        inProgressMarks: _asInt(json['inProgressMarks']),
        completedMarks: _asInt(json['completedMarks']),
        pendingMarks: _asInt(json['pendingMarks']),
      );
}
