import 'dart:io';
import 'package:dio/dio.dart';

import 'package:untitled2/core/api/requestQueueModel.dart';
import 'package:untitled2/core/api/requestQueue.dart';

import '../../../../../core/api/dio.dart';

class RateApiClient {
  final Dio _dio = DioClient.dio;

  // Fetch rate list by type
  Future<Map<String, dynamic>> fetchRate(String type, String siteId) async {
    try {
      final response = await _dio.get('/site/$siteId/rate', queryParameters: {
        'type': type,
      });
      print("Response data: ${response.data}");
      return {'success': true, 'data': response.data};
    } catch (e) {
      print(_handleError(e));
      return _handleError(e);
    }
  }

  // Post new rate
  Future<Map<String, dynamic>> postRate(
      Map<String, dynamic> data, String type, String siteId) async {
    try {
      final response = await _dio.post('/site/$siteId/rate',
          data: data, queryParameters: {'type': type});
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Fetch single rate by ID
  Future<Map<String, dynamic>> fetchRateById(String siteId, String rateId) async {
    try {
      final response = await _dio.get('/site/$siteId/rate/$rateId');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Update rate
  Future<Map<String, dynamic>> updateRate(
      Map<String, dynamic> data, String siteId, String rateId) async {
    try {
      final response = await _dio.put('/site/$siteId/rate/$rateId', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Generate CSV
  Future<Map<String, dynamic>> getCsv(String type, String siteId) async {
    try {
      final response = await _dio.get('/site/$siteId/rate/generate-csv',
          queryParameters: {'type': type});
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Upload CSV
  Future<Map<String, dynamic>> uploadCsv(
      FormData data, String type, String siteId) async {
    try {
      final response = await _dio.post(
        '/site/$siteId/rate/upload-csv',
        data: data,
        queryParameters: {'type': type},
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Get Rate UOM
  Future<List<dynamic>> getRateUOM() async {
    try {
      final response = await _dio.get('/uom');
      return response.data;   // directly return list
    } catch (e) {
      rethrow;
    }
  }


  // Post Rate UOM
  Future<Map<String, dynamic>> postRateUOM(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/uom', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Add empty rate entry
  Future<Map<String, dynamic>> addRate(String siteId) async {
    try {
      final response = await _dio.post('/site/$siteId/rate');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return _handleError(e);
    }
  }

  // Centralized error handling
  Map<String, dynamic> _handleError(dynamic error) {
    if (error is DioException) {
      final responseData = error.response?.data;
      return {
        'success': false,
        'data': null,
        'error': responseData ?? error.message,
        'statusCode': error.response?.statusCode,
        'requiresDeviceAuth': responseData is Map && responseData['error']?['requiresDeviceAuth'] == true,
      };
    } else {
      return {'success': false, 'data': null, 'error': error.toString()};
    }
  }
}
