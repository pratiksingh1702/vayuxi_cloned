
import '../../../../../core/api/dio.dart';
import '../data/model_enums.dart';

import 'package:untitled2/core/api/dio.dart';

class SummaryService {
  static final _dio = DioClient.dio;

  static Future<List<SiteSummaryModel>> fetchSummary({
    required String type, // 'mechnical' or 'insulation'
    required SummaryFilterType filterType,
    String? year,
    int? month,
    String? date, // 'yyyy-MM-dd' for daily/weekly
  }) async {
    final query = <String, dynamic>{
      'filterType': filterType.name,
      if (year != null) 'year': year,
      if (month != null && filterType == SummaryFilterType.monthly) 'month': month,
      if (date != null &&
          (filterType == SummaryFilterType.daily ||
              filterType == SummaryFilterType.weekly))
        'date': date,
    };

    final res = await _dio.get('/summery-sheet/$type', queryParameters: query);
    final List data = res.data;
    return data.map((e) => SiteSummaryModel.fromJson(e, filterType)).toList();
  }
}