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
  static Future<void> delete(String siteId) async {
    try {


      final response = await dio.delete(
        '/site/$siteId',
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
  static Future<void> bulkDeleteSites(List<String> siteIds) async {
    if (siteIds.isEmpty) {
      throw Exception("Bulk delete called with empty ID list");
    }

    try {
      final response = await dio.post(
        '/site/bulk-delete',
        data: {
          "ids": siteIds,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print("✅ Status Code: ${response.statusCode}");
      print("✅ Response Data: ${response.data}");
    } catch (e) {
      print("❌ Bulk Delete Error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> uploadFile(
      File file,
      String type, {
        String? siteId,
      }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await dio.post(
      '/site/ocr',
      queryParameters: {
        'type': type,
        if (siteId != null) 'siteId': siteId,
      },
      data: formData,
    );

    return response.data as Map<String, dynamic>;
  }



  static Future<Map<String, dynamic>> createSite(
      FormData formData, String type) async {
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
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getSite(String siteId) async {
    final res = await dio.get("/site/$siteId");
    return res.data;
  }

  static Future<Map<String, dynamic>> getWorkTypeConfig(String siteId) async {
    final res = await dio.get("/site/$siteId/work-type-config");
    return res.data;
  }

  static Future<void> updateWorkTypeConfig(
      String siteId, Map<String, dynamic> config) async {
    await dio.put("/site/$siteId/work-type-config", data: config);
  }
}
