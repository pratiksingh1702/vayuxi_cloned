import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../service/summaryService.dart';
import 'model_enums.dart';

// ─── Filter State ─────────────────────────────────────────────────────────────

class SummaryFilter {
  final SummaryFilterType filterType;
  final int month; // used for monthly
  final String year;
  final DateTime date; // used for daily/weekly
  final DateTime rangeFromDate; // used for PEB weekly range
  final DateTime rangeToDate; // used for PEB weekly range

  const SummaryFilter({
    this.filterType = SummaryFilterType.monthly,
    required this.month,
    required this.year,
    required this.date,
    required this.rangeFromDate,
    required this.rangeToDate,
  });

  SummaryFilter copyWith({
    SummaryFilterType? filterType,
    int? month,
    String? year,
    DateTime? date,
    DateTime? rangeFromDate,
    DateTime? rangeToDate,
  }) =>
      SummaryFilter(
        filterType: filterType ?? this.filterType,
        month: month ?? this.month,
        year: year ?? this.year,
        date: date ?? this.date,
        rangeFromDate: rangeFromDate ?? this.rangeFromDate,
        rangeToDate: rangeToDate ?? this.rangeToDate,
      );
}

class SummaryFilterNotifier extends StateNotifier<SummaryFilter> {
  SummaryFilterNotifier()
      : super(SummaryFilter(
          month: DateTime.now().month,
          year: DateTime.now().year.toString(),
          date: DateTime.now(),
          rangeFromDate: DateTime.now()
              .subtract(Duration(days: DateTime.now().weekday - 1)),
          rangeToDate: DateTime.now()
              .subtract(Duration(days: DateTime.now().weekday - 1))
              .add(const Duration(days: 6)),
        ));

  void setFilterType(SummaryFilterType type) =>
      state = state.copyWith(filterType: type);

  void setMonth(int month) => state = state.copyWith(month: month);

  void setYear(String year) => state = state.copyWith(year: year);

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setRangeFromDate(DateTime date) {
    final toDate = state.rangeToDate.isBefore(date) ? date : state.rangeToDate;
    state = state.copyWith(rangeFromDate: date, rangeToDate: toDate);
  }

  void setRangeToDate(DateTime date) {
    final fromDate =
        state.rangeFromDate.isAfter(date) ? date : state.rangeFromDate;
    state = state.copyWith(rangeFromDate: fromDate, rangeToDate: date);
  }
}

final summaryFilterProvider =
    StateNotifierProvider<SummaryFilterNotifier, SummaryFilter>(
  (ref) => SummaryFilterNotifier(),
);

// ─── Data Provider ────────────────────────────────────────────────────────────

final summaryDataProvider =
    FutureProvider.autoDispose<List<SiteSummaryModel>>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final type = ref.watch(typeProvider);
  final apiType = type == 'insulation_work' ? 'insulation' : 'mechnical';

  return SummaryService.fetchSummary(
    type: apiType,
    filterType: filter.filterType,
    year: filter.year,
    month: filter.month,
    date: '${filter.date.year}-'
        '${filter.date.month.toString().padLeft(2, '0')}-'
        '${filter.date.day.toString().padLeft(2, '0')}',
  );
});

final pebWorkSummaryProvider =
    FutureProvider.autoDispose<PebWorkSummaryModel>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final type = ref.watch(typeProvider) ?? 'erection_work';
  final siteId = ref.watch(selectedSiteIdProvider);

  if (siteId == null || siteId.isEmpty) {
    throw Exception('Please select a site first');
  }

  final range = _pebPeriodRange(filter);

  return SummaryService.fetchPebWorkSummary(
    siteId: siteId,
    type: type,
    fromDate: _formatDate(range.from),
    toDate: _formatDate(range.to),
    view: filter.filterType == SummaryFilterType.weekly ? 'weekly' : 'daily',
  );
});

final pebProfitLossProvider =
    FutureProvider.autoDispose<PebProfitLossModel>((ref) async {
  final filter = ref.watch(summaryFilterProvider);
  final type = ref.watch(typeProvider) ?? 'erection_work';
  final siteId = ref.watch(selectedSiteIdProvider);

  if (siteId == null || siteId.isEmpty) {
    throw Exception('Please select a site first');
  }

  final range = _pebPeriodRange(filter);

  return SummaryService.fetchPebProfitLoss(
    siteId: siteId,
    type: type,
    fromDate: _formatDate(range.from),
    toDate: _formatDate(range.to),
    view: filter.filterType == SummaryFilterType.yearly
        ? 'yearly'
        : filter.filterType.name,
  );
});

({DateTime from, DateTime to}) _pebPeriodRange(SummaryFilter filter) {
  final year = int.tryParse(filter.year) ?? DateTime.now().year;
  if (filter.filterType == SummaryFilterType.yearly) {
    return (from: DateTime(year, 1, 1), to: DateTime(year, 12, 31));
  }
  final from = DateTime(year, filter.month, 1);
  final to = DateTime(year, filter.month + 1, 0);
  return (from: from, to: to);
}

String _formatDate(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
