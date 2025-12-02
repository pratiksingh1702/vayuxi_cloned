import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/api/dio.dart';
import '../repository/siteModel.dart';


class SiteAPI {
  static final dio = DioClient.dio;

  static Future<List<Map<String, dynamic>>> fetchSites(String type) async {
    final res = await dio.get("/site", queryParameters: {"type": type}
    );
    print("Raw Response: ${res.data}");

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(res.data); // assuming your API returns a list of sites
    } else {
      throw Exception("Failed to fetch sites: ${res.statusCode}");
    }
  }

  static Future<void> updateSite(String siteId, FormData data) async {
    try {


      final response = await dio.put(
        '/site/$siteId',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print("✅ Status Code: ${response.statusCode}");
      print("✅ Response Data: ${response.data}");
    } catch (e) {
      print("❌ Update Error: $e");
      rethrow;
    }
  }

  static Future<void> uploadFile(File file, String type, {String? siteId}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    try {
      final response = await dio.post(
        '/site/ocr',
        queryParameters: {
          "type": type,
          if (siteId != null) "siteId": siteId,
        },
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Response: ${response.data}');
      return response.data; // Consider returning the response data
    } catch (e) {
      print('Error: $e');
      rethrow; // Consider rethrowing to handle errors at call site
    }
  }

  static Future<Map<String, dynamic>> createSite(
      FormData formData,
      String type
      ) async {
    try {
      final res = await dio.post(
        "/site?type=$type",
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Don't throw for 4xx errors
          },
        ),
      );

      if (res.statusCode! >= 400) {
        throw DioException(
          response: res,
          requestOptions: res.requestOptions,
          type: DioExceptionType.badResponse,
        );
      }

      return res.data;
    } on DioException catch (e) {
      // Re-throw to be handled in saveSite method
      rethrow;
    }
  }
}
