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
  final String trackingMode;
  final String dprLevel;
  final PebModeRules modeRules;
  final PebModeSummary modeSummary;
  final PebDataAvailability dataAvailability;
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
    required this.trackingMode,
    required this.dprLevel,
    required this.modeRules,
    required this.modeSummary,
    required this.dataAvailability,
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
      trackingMode: json['trackingMode']?.toString() ?? '',
      dprLevel: json['dprLevel']?.toString() ?? '',
      modeRules: PebModeRules.fromJson(json['modeRules'] ?? {}),
      modeSummary: PebModeSummary.fromJson(json['modeSummary'] ?? {}),
      dataAvailability:
          PebDataAvailability.fromJson(json['dataAvailability'] ?? {}),
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

class PebModeRules {
  final bool showPlanning;
  final bool showBoqScope;
  final bool showDelay;
  final bool showGantt;
  final bool showCompletionPercentage;
  final bool showRemainingQuantity;
  final bool showStagePercentages;
  final bool showActualOnly;

  const PebModeRules({
    required this.showPlanning,
    required this.showBoqScope,
    required this.showDelay,
    required this.showGantt,
    required this.showCompletionPercentage,
    required this.showRemainingQuantity,
    required this.showStagePercentages,
    required this.showActualOnly,
  });

  factory PebModeRules.fromJson(Map<String, dynamic> json) => PebModeRules(
        showPlanning: json['showPlanning'] == true,
        showBoqScope: json['showBoqScope'] == true,
        showDelay: json['showDelay'] == true,
        showGantt: json['showGantt'] == true,
        showCompletionPercentage: json['showCompletionPercentage'] == true,
        showRemainingQuantity: json['showRemainingQuantity'] == true,
        showStagePercentages: json['showStagePercentages'] == true,
        showActualOnly: json['showActualOnly'] == true,
      );
}

class PebModeSummary {
  final PebAssignmentModeSummary assignmentStatus;
  final PebBoqScopeSummary boqScope;
  final PebActualOnlySummary actualOnly;

  const PebModeSummary({
    required this.assignmentStatus,
    required this.boqScope,
    required this.actualOnly,
  });

  factory PebModeSummary.fromJson(Map<String, dynamic> json) => PebModeSummary(
        assignmentStatus:
            PebAssignmentModeSummary.fromJson(json['assignmentStatus'] ?? {}),
        boqScope: PebBoqScopeSummary.fromJson(json['boqScope'] ?? {}),
        actualOnly: PebActualOnlySummary.fromJson(json['actualOnly'] ?? {}),
      );
}

class PebAssignmentModeSummary {
  final PebQuantity assignedTillDate;
  final PebQuantity completedTillDate;
  final PebQuantity difference;
  final double planProgressPercentage;
  final double actualProgressPercentage;
  final double differencePercentage;

  const PebAssignmentModeSummary({
    required this.assignedTillDate,
    required this.completedTillDate,
    required this.difference,
    required this.planProgressPercentage,
    required this.actualProgressPercentage,
    required this.differencePercentage,
  });

  factory PebAssignmentModeSummary.fromJson(Map<String, dynamic> json) =>
      PebAssignmentModeSummary(
        assignedTillDate: PebQuantity.fromJson(json['assignedTillDate'] ?? {}),
        completedTillDate:
            PebQuantity.fromJson(json['completedTillDate'] ?? {}),
        difference: PebQuantity.fromJson(json['difference'] ?? {}),
        planProgressPercentage: _asDouble(json['planProgressPercentage']),
        actualProgressPercentage: _asDouble(json['actualProgressPercentage']),
        differencePercentage: _asDouble(json['differencePercentage']),
      );
}

class PebBoqScopeSummary {
  final PebQuantity totalScope;
  final PebQuantity completed;
  final PebQuantity remaining;
  final double completionPercentage;

  const PebBoqScopeSummary({
    required this.totalScope,
    required this.completed,
    required this.remaining,
    required this.completionPercentage,
  });

  factory PebBoqScopeSummary.fromJson(Map<String, dynamic> json) =>
      PebBoqScopeSummary(
        totalScope: PebQuantity.fromJson(json['totalScope'] ?? {}),
        completed: PebQuantity.fromJson(json['completed'] ?? {}),
        remaining: PebQuantity.fromJson(json['remaining'] ?? {}),
        completionPercentage: _asDouble(json['completionPercentage']),
      );
}

class PebActualOnlySummary {
  final PebQuantity executed;

  const PebActualOnlySummary({required this.executed});

  factory PebActualOnlySummary.fromJson(Map<String, dynamic> json) =>
      PebActualOnlySummary(
        executed: PebQuantity.fromJson(json['executed'] ?? {}),
      );
}

class PebDataAvailability {
  final bool hasBoq;
  final bool hasWorkAssignment;
  final bool hasDpr;

  const PebDataAvailability({
    required this.hasBoq,
    required this.hasWorkAssignment,
    required this.hasDpr,
  });

  factory PebDataAvailability.fromJson(Map<String, dynamic> json) =>
      PebDataAvailability(
        hasBoq: json['hasBoq'] == true,
        hasWorkAssignment: json['hasWorkAssignment'] == true,
        hasDpr: json['hasDpr'] == true,
      );
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
  final double totalPlannedQty;
  final double totalPlannedWeightKg;
  final double totalPlannedWeightMt;
  final double totalActualQty;
  final double totalActualWeightKg;
  final double totalActualWeightMt;
  final double totalRemainingQty;
  final double totalRemainingWeightKg;
  final double totalRemainingWeightMt;
  final double differenceQty;
  final double differenceWeightKg;
  final double differenceWeightMt;

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
    required this.totalPlannedQty,
    required this.totalPlannedWeightKg,
    required this.totalPlannedWeightMt,
    required this.totalActualQty,
    required this.totalActualWeightKg,
    required this.totalActualWeightMt,
    required this.totalRemainingQty,
    required this.totalRemainingWeightKg,
    required this.totalRemainingWeightMt,
    required this.differenceQty,
    required this.differenceWeightKg,
    required this.differenceWeightMt,
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
        totalPlannedQty: _asDouble(json['totalPlannedQty']),
        totalPlannedWeightKg: _asDouble(json['totalPlannedWeightKg']),
        totalPlannedWeightMt: _asDouble(json['totalPlannedWeightMt']),
        totalActualQty: _asDouble(json['totalActualQty']),
        totalActualWeightKg: _asDouble(json['totalActualWeightKg']),
        totalActualWeightMt: _asDouble(json['totalActualWeightMt']),
        totalRemainingQty: _asDouble(json['totalRemainingQty']),
        totalRemainingWeightKg: _asDouble(json['totalRemainingWeightKg']),
        totalRemainingWeightMt: _asDouble(json['totalRemainingWeightMt']),
        differenceQty: _asDouble(json['differenceQty']),
        differenceWeightKg: _asDouble(json['differenceWeightKg']),
        differenceWeightMt: _asDouble(json['differenceWeightMt']),
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
  final PebQuantity scope;
  final PebQuantity difference;
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
    required this.scope,
    required this.difference,
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
        scope: PebQuantity.fromJson(json['scope'] ?? {}),
        difference: PebQuantity.fromJson(json['difference'] ?? {}),
        delayDays: _asInt(json['delayDays']),
        status: json['status']?.toString() ?? '',
      );
}

class PebQuantity {
  final double qty;
  final double marks;
  final double weightMt;
  final double weightKg;

  const PebQuantity({
    required this.qty,
    required this.marks,
    required this.weightMt,
    required this.weightKg,
  });

  factory PebQuantity.fromJson(Map<String, dynamic> json) => PebQuantity(
        qty: _asDouble(json['qty']),
        marks: _asDouble(json['marks']),
        weightMt: _asDouble(json['weightMt']),
        weightKg: _asDouble(json['weightKg']),
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

class PebProfitLossModel {
  final PebProfitLossSite site;
  final String type;
  final String fromDate;
  final String toDate;
  final String view;
  final PebProfitLossTotals totals;
  final List<PebProfitLossTrendPoint> trend;
  final List<PebRevenueBreakdownItem> revenueBreakdown;
  final List<PebExpenseBreakdownItem> expenseBreakdown;
  final bool empty;

  const PebProfitLossModel({
    required this.site,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.view,
    required this.totals,
    required this.trend,
    required this.revenueBreakdown,
    required this.expenseBreakdown,
    required this.empty,
  });

  factory PebProfitLossModel.fromJson(Map<String, dynamic> json) {
    final totals = PebProfitLossTotals.fromJson(json['totals'] ?? {});
    final rawRevenueRows = (json['revenueBreakdown'] as List? ?? [])
        .map((e) =>
            PebRevenueBreakdownItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return PebProfitLossModel(
      site: PebProfitLossSite.fromJson(json['site'] ?? {}),
      type: json['type']?.toString() ?? '',
      fromDate: json['fromDate']?.toString() ?? '',
      toDate: json['toDate']?.toString() ?? '',
      view: json['view']?.toString() ?? '',
      totals: totals,
      trend: (json['trend'] as List? ?? [])
          .map((e) =>
              PebProfitLossTrendPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      revenueBreakdown: PebRevenueBreakdownItem.summaryOnly(
        rawRevenueRows,
        totalRevenue: totals.revenue,
      ),
      expenseBreakdown: (json['expenseBreakdown'] as List? ?? [])
          .map((e) =>
              PebExpenseBreakdownItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      empty: json['empty'] == true,
    );
  }
}

class PebProfitLossSite {
  final String id;
  final String name;

  const PebProfitLossSite({required this.id, required this.name});

  factory PebProfitLossSite.fromJson(Map<String, dynamic> json) =>
      PebProfitLossSite(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Selected Site',
      );
}

class PebProfitLossTotals {
  final double revenue;
  final double expense;
  final double profitLoss;
  final double marginPercentage;
  final bool isProfit;

  const PebProfitLossTotals({
    required this.revenue,
    required this.expense,
    required this.profitLoss,
    required this.marginPercentage,
    required this.isProfit,
  });

  factory PebProfitLossTotals.fromJson(Map<String, dynamic> json) =>
      PebProfitLossTotals(
        revenue: _asDouble(json['revenue']),
        expense: _asDouble(json['expense']),
        profitLoss: _asDouble(json['profitLoss']),
        marginPercentage: _asDouble(json['marginPercentage']),
        isProfit: json['isProfit'] != false,
      );
}

class PebProfitLossTrendPoint {
  final String label;
  final String startDate;
  final String endDate;
  final double revenue;
  final double expense;
  final double loss;

  const PebProfitLossTrendPoint({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.revenue,
    required this.expense,
    required this.loss,
  });

  factory PebProfitLossTrendPoint.fromJson(Map<String, dynamic> json) =>
      PebProfitLossTrendPoint(
        label: json['label']?.toString() ?? '',
        startDate: json['startDate']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? '',
        revenue: _asDouble(json['revenue']),
        expense: _asDouble(json['expense']),
        loss: _asDouble(json['loss']),
      );
}

class PebRevenueBreakdownItem {
  final String activityName;
  final double revenue;
  final double contributionPercentage;
  final double quantity;
  final double rate;
  final String unit;
  final String source;

  const PebRevenueBreakdownItem({
    required this.activityName,
    required this.revenue,
    required this.contributionPercentage,
    required this.quantity,
    required this.rate,
    required this.unit,
    required this.source,
  });

  factory PebRevenueBreakdownItem.fromJson(Map<String, dynamic> json) =>
      PebRevenueBreakdownItem(
        activityName: json['activityName']?.toString() ?? 'Revenue Item',
        revenue: _asDouble(json['revenue']),
        contributionPercentage: _asDouble(json['contributionPercentage']),
        quantity: _asDouble(json['quantity']),
        rate: _asDouble(json['rate']),
        unit: json['unit']?.toString() ?? '',
        source: json['source']?.toString() ?? 'Summary Sheet',
      );

  static List<PebRevenueBreakdownItem> summaryOnly(
    List<PebRevenueBreakdownItem> rows, {
    required double totalRevenue,
  }) {
    if (rows.isEmpty && totalRevenue <= 0) return const [];
    final first = rows.isNotEmpty ? rows.first : null;
    final revenue = totalRevenue > 0
        ? totalRevenue
        : rows.fold<double>(0, (sum, item) => sum + item.revenue);
    final weightedQty =
        rows.fold<double>(0, (sum, item) => sum + item.quantity);
    final unit = first?.unit ?? '';
    final rate = first?.rate ?? 0;

    return [
      PebRevenueBreakdownItem(
        activityName: rows.length == 1
            ? (first?.activityName ?? 'Summary Sheet Total')
            : 'Summary Sheet Total',
        revenue: revenue,
        contributionPercentage: revenue > 0 ? 100 : 0,
        quantity: weightedQty > 0 ? weightedQty : (first?.quantity ?? 0),
        rate: rate,
        unit: unit,
        source: 'Summary Sheet',
      ),
    ];
  }
}

class PebExpenseBreakdownItem {
  final String category;
  final double amount;
  final double contributionPercentage;
  final int count;
  final String source;

  const PebExpenseBreakdownItem({
    required this.category,
    required this.amount,
    required this.contributionPercentage,
    required this.count,
    required this.source,
  });

  factory PebExpenseBreakdownItem.fromJson(Map<String, dynamic> json) =>
      PebExpenseBreakdownItem(
        category: json['category']?.toString() ?? 'Expense',
        amount: _asDouble(json['amount']),
        contributionPercentage: _asDouble(json['contributionPercentage']),
        count: _asInt(json['count']),
        source: json['source']?.toString() ?? 'Expense Module',
      );
}
