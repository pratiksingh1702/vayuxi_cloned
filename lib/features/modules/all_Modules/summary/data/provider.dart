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

  const SummaryFilter({
    this.filterType = SummaryFilterType.monthly,
    required this.month,
    required this.year,
    required this.date,
  });

  SummaryFilter copyWith({
    SummaryFilterType? filterType,
    int? month,
    String? year,
    DateTime? date,
  }) =>
      SummaryFilter(
        filterType: filterType ?? this.filterType,
        month: month ?? this.month,
        year: year ?? this.year,
        date: date ?? this.date,
      );
}

class SummaryFilterNotifier extends StateNotifier<SummaryFilter> {
  SummaryFilterNotifier()
      : super(SummaryFilter(
          month: DateTime.now().month,
          year: DateTime.now().year.toString(),
          date: DateTime.now(),
        ));

  void setFilterType(SummaryFilterType type) =>
      state = state.copyWith(filterType: type);

  void setMonth(int month) => state = state.copyWith(month: month);

  void setYear(String year) => state = state.copyWith(year: year);

  void setDate(DateTime date) => state = state.copyWith(date: date);
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

  final range = _pebSummaryRange(filter);

  return SummaryService.fetchPebWorkSummary(
    siteId: siteId,
    type: type,
    fromDate: _formatDate(range.from),
    toDate: _formatDate(range.to),
    view: range.view,
  );
});

({DateTime from, DateTime to, String view}) _pebSummaryRange(
  SummaryFilter filter,
) {
  switch (filter.filterType) {
    case SummaryFilterType.daily:
      return (from: filter.date, to: filter.date, view: 'daily');
    case SummaryFilterType.weekly:
      final from =
          filter.date.subtract(Duration(days: filter.date.weekday - 1));
      final to = from.add(const Duration(days: 6));
      return (from: from, to: to, view: 'weekly');
    case SummaryFilterType.monthly:
      final year = int.tryParse(filter.year) ?? DateTime.now().year;
      final from = DateTime(year, filter.month, 1);
      final to = DateTime(year, filter.month + 1, 0);
      return (from: from, to: to, view: 'monthly');
    case SummaryFilterType.yearly:
      final year = int.tryParse(filter.year) ?? DateTime.now().year;
      return (
        from: DateTime(year, 1, 1),
        to: DateTime(year, 12, 31),
        view: 'monthly'
      );
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
