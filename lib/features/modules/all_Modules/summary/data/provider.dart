import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/typeProvider/type_provider.dart';

import '../service/summaryService.dart';
import 'model_enums.dart';

// ─── Filter State ─────────────────────────────────────────────────────────────

class SummaryFilter {
  final SummaryFilterType filterType;
  final int month;         // used for monthly
  final String year;
  final DateTime date;     // used for daily/weekly

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

final summaryDataProvider = FutureProvider.autoDispose<List<SiteSummaryModel>>((ref) async {
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