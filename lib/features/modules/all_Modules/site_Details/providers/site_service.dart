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


  static Future<Map<String, dynamic>> createSite(
      Map<String, dynamic> data, String type) async {
    final res = await dio.post("/site?type=$type", data: FormData.fromMap(data));
    return res.data;
  }
}
