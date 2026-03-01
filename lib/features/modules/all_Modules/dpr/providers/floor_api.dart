// services/floor_api.dart
import 'dart:convert';
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
    required String rateUploadId,
    required String newFloorName,
    required List<String> existingFloorNames,
    required List<Floor> existingFloorsWithImages,
    File? newImage,
  }) async {
    final isAddingNew = newFloorName.trim().isNotEmpty;

    // If adding → append
    // If editing/deleting → just use provided list as-is
    final allFloors = isAddingNew
        ? [...existingFloorNames, newFloorName]
        : existingFloorNames;

    final Map<String, dynamic> formMap = {
      "hasFloor": true,

      /// FULL FINAL LIST
      "floors": jsonEncode(allFloors),

      /// Only send new name if actually adding
      "floorNames": isAddingNew
          ? jsonEncode([newFloorName])
          : jsonEncode([]),

      /// Existing objects only (already modified if edit/delete)
      "floorsWithImages": jsonEncode(
        existingFloorsWithImages.map((e) => {
          "name": e.name,
          "image": e.image,
        }).toList(),
      ),
    };

    // Only attach image when adding new
    if (isAddingNew && newImage != null) {
      formMap["floorImages"] = await MultipartFile.fromFile(
        newImage.path,
        filename: newImage.path.split('/').last,
      );
    }

    final formData = FormData.fromMap(formMap);

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
