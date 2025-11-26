import 'package:dio/dio.dart';
import '../../../../../core/api/dio.dart';


class SummaryAPI {
  static final dio = DioClient.dio;

  /// Fetch Insulation Summary
  static Future<List<dynamic>> fetchInsulationSummary({
    required int month,
    required String year,
  }) async {
    final res = await dio.get(
      '/summery-sheet/insulation',
      queryParameters: {'month': month, 'year': year},
    );
    return res.data;
  }

  /// Fetch Mechanical Summary
  static Future<List<dynamic>> fetchMechanicalSummary({
    required int month,
    required String year,
  }) async {
    final res = await dio.get(
      '/summery-sheet/mechnical',
      queryParameters: {'month': month, 'year': year},
    );
    return res.data;
  }
}
