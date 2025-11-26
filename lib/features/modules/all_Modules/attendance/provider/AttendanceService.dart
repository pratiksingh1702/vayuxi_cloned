import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../../core/api/dio.dart';

class AttendanceApi {
  /// Fetch attendance list
  static Future<Response> fetchAttendance({
    required String type,
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/attendance",
        queryParameters: {"type": type},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Post single attendance
  static Future<Response> postAttendance({
    required dynamic data,
    required String type,
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/attendance",
        queryParameters: {"type": type},
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch attendance by ID (⚠️ API looks like expenseId in your TS code)
  static Future<Response> fetchAttendanceById({
    required String siteId,
    required String attendanceId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/attendance/$attendanceId",
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update attendance
  static Future<Response> updateAttendance({
    required dynamic data,
    required String siteId,
    required String attendanceId,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/site/$siteId/attendance/$attendanceId",
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch attendance from-to date
  static Future<Response> fetchAttendanceFromTo({
    required String type,
    required String siteId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final from = startDate != null
          ? startDate.toIso8601String().split("T")[0]
          : "";
      final to =
      endDate != null ? endDate.toIso8601String().split("T")[0] : "";

      final response = await DioClient.dio.get(
        "/site/$siteId/attendance/generate-attendance",
        queryParameters: {
          "type": type,
          "fromDate": from,
          "toDate": to,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Post multiple attendance
  /// Post multiple attendance
  static Future<Response> postMultipleAttendance({
    required dynamic data,
    required String type,
    required String siteId,
  }) async {
    try {
      print('🚀 Sending multiple attendance request:');
      print('   URL: /site/$siteId/attendance/multiple-attendance');
      print('   Type: $type');
      print('   Data: ${jsonEncode(data)}'); // This will show the exact JSON

      final response = await DioClient.dio.post(
        "/site/$siteId/attendance/multiple-attendance",
        queryParameters: {"type": type},
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status! < 500; // Don't throw for 400 errors, let us handle them
          },
        ),
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response data: ${response.data}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }

      return response;

    } catch (e) {
      print('❌ Error in postMultipleAttendance: $e');
      rethrow;
    }
  }

  /// Post multiple present attendance
  static Future<Response> postMultiplePresentAttendance({
    required dynamic data,
    required String type,
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/attendance/multiple-present",
        queryParameters: {"type": type},
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
  static Future<Response> fetchAttendanceByDate({
    required String type,
    required String siteId,
    required String fromDate,
  }) async {
    try {
      // Format date from DD/MM/YYYY to YYYY-MM-DD
      final parts = fromDate.split('/');
      final formattedDate = "${parts[2]}-${parts[1]}-${parts[0]}";

      print('🔍 Fetching attendance for date: $formattedDate');

      final response = await DioClient.dio.get(
        "/site/$siteId/attendance/attendance",
        queryParameters: {
          "type": type,
          "fromDate": formattedDate,
        },
      );

      print('✅ Attendance fetch response: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ Error fetching attendance by date: $e');
      rethrow;
    }
  }

  /// Update existing attendance records (equivalent to PutAttendance in RN)
  static Future<Response> updateMultipleAttendance({
    required dynamic data,
    required String type,
    required String siteId,
    required String fromDate,
  })  async {
    try {
      print('🔄 Updating existing attendance records');
      print('   Date: $fromDate');

      // Format date from DD/MM/YYYY to YYYY-MM-DD like RN
      final parts = fromDate.split('/');
      final formattedDate = "${parts[2]}-${parts[1]}-${parts[0]}";

      final response = await DioClient.dio.post(
        "/site/$siteId/attendance/update", // POST to update endpoint
        queryParameters: {
          "type": type,
          "fromDate": formattedDate, // Use formatted date
        },
        data: data,
      );

      print('✅ Attendance updated: ${response.statusCode}');
      print('✅ Response data: ${response.data}');
      return response;

    } catch (e) {
      print('❌ Error updating attendance: $e');
      rethrow;
    }
  }
  /// Fetch manpower (attendance2 handler in TS code)
  static Future<Response> fetchAttendance2({
    required String type,
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/manpower",
        queryParameters: {"type": type},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
