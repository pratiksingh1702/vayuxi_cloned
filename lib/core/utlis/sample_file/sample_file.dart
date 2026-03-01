import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../api/dio.dart';

class TemplatesApiService {
  final Dio dio;

  TemplatesApiService({Dio? dio}) : dio = dio ?? DioClient.dio;

  /// GET /api/v1/templates/download?model=inventory
  /// GET /api/v1/templates/download?model=site
  /// GET /api/v1/templates/download?model=manpower
  /// GET /api/v1/templates/download?model=rate
  Future<Uint8List> downloadTemplate({

    required String model,
  }) async {
    final response = await dio.get(
      "/templates/download",
      queryParameters: {"model": model},
      options: Options(
        responseType: ResponseType.bytes, // ✅ must for download
        followRedirects: true,
        receiveTimeout: const Duration(seconds: 120),  headers: {
        "Accept": "text/csv",
      },

      ),

    );
    print(response.headers);
    return Uint8List.fromList(response.data);
  }
}
