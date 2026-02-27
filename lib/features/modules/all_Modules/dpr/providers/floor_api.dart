// services/floor_api.dart
import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../../core/api/dio.dart';
import '../models/floorModel.dart';

class FloorApi {
  final Dio dio = DioClient.dio;

  /// GET FLOORS BY SITE
  Future<Response> getFloorsBySite({required String siteId}) {
    return dio.get(
      '/floor',
      queryParameters: {'siteId': siteId},
    );
  }

  Future<Response> createFloor({
    required String name,
    required String rateUploadId,
    required List<Floor> existingFloorsWithImages,
    File? image,
  }) async {
    final formData = FormData.fromMap({
      "floorNames[]": [
        ...existingFloorsWithImages.map((e) => e.name),
        name,
      ],
      "hasFloor": true,
    });

    // Existing floors — send their server URLs
    for (int i = 0; i < existingFloorsWithImages.length; i++) {
      final existing = existingFloorsWithImages[i];
      if (existing.image.startsWith('http')) {
        formData.fields.add(MapEntry("floorImageUrls[$i]", existing.image));
      }
    }

    // New floor image as file
    if (image != null) {
      formData.files.add(MapEntry(
        "floorImages",
        await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      ));
    }

    return await dio.put(
      "/rate-upload/$rateUploadId/detected-fields",
      data: formData,
      options: Options(contentType: "multipart/form-data"),
    );
  }

  /// UPDATE FLOOR
  Future<Response> updateFloor({
    required String floorId,
    String? name,
    File? image,
    bool isApplied=false,
  }) async {
    final formData = FormData.fromMap({
      if (name != null) 'name': name,
      "isApplied": isApplied,
      if (image != null)
        'image': await MultipartFile.fromFile(
          image.path,

          filename: image.path.split('/').last,
        ),
    });

    return dio.put(
      '/floor/$floorId',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
  /// BULK DELETE FLOOR
  Future<Response> bulkDeleteFloor({
    required List<String> ids,
  }) async {
    return await dio.post(
      '/floor/bulk-delete',
      data: {
        'ids': ids,
      },
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
  }

  /// DELETE FLOOR
  Future<Response> deleteFloor({required String floorId}) {
    return dio.delete('/floor/$floorId');
  }
}
