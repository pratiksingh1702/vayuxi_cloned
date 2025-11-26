// lib/core/api/salary_api.dart
import 'package:dio/dio.dart';
import '../../../../../core/api/dio.dart';

class SalaryAPI {
  static final dio = DioClient.dio;

  /// Post Salary
  static Future<Map<String, dynamic>> postSalary({
    required Map<String, dynamic> data,
    required String type,
    required int month,
    required String year,
  }) async {
    final res = await dio.post(
      "/salary",
      data: data,
      queryParameters: {
        'type': type,
        'month': month,
        'year': year,
      },
    );
    return res.data;
  }

  /// Fetch Salary by Site
  static Future<List<dynamic>> fetchSalaryBySite({
    required String type,
    required String id,
    required String month,
    required String year,
  }) async {
    final res = await dio.get(
      "/salary/$id",
      queryParameters: {
        'type': type,
        'month': month,
        'year': year,
      },
    );

    // The backend returns a raw List, not wrapped inside {"data": [...]}
    if (res.data is List) {
      return List<dynamic>.from(res.data);
    } else if (res.data is Map && res.data['data'] is List) {
      // optional safety in case API changes later
      return List<dynamic>.from(res.data['data']);
    } else {
      return [];
    }
  }


  /// Fetch Salary by Employee
  static Future<Map<String, dynamic>> fetchSalaryByEmployee({
    required String type,
    required String month,
    required String year,
  }) async {
    final res = await dio.get(
      "/salary",
      queryParameters: {
        'type': type,
        'month': month,
        'year': year,
      },
    );
    return res.data;
  }

  /// Fetch Site Salary Employees
  static Future<Map<String, dynamic>> fetchSiteSalaryEmployees({
    required String id,
  }) async {
    final res = await dio.get("/site/$id/manpower");
    return res.data;
  }
}