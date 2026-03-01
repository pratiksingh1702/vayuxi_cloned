import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';

import '../models/rate_file_models.dart';

class MocApi {
  final Dio dio = DioClient.dio;

  /// CREATE MOC (POST)
  Future<Response> createMoc({
    required String rateUploadId,
    required String newMocName,
    required List<String> existingMocs,
    required List<NamedImage> existingMocsWithImages,
    File? newImage,
  }) async {

    final isAddingNew = newMocName.trim().isNotEmpty;

    final allMocs = isAddingNew
        ? [...existingMocs, newMocName]
        : existingMocs;

    final formMap = {
      "hasMoc": true,
      "mocs": jsonEncode(allMocs),
      "mocsWithImages":
      jsonEncode(existingMocsWithImages.map((e) => e.toJson()).toList()),
    };

    if (isAddingNew) {
      formMap["mocNames"] = jsonEncode([newMocName]);
    } else {
      formMap["mocNames"] = jsonEncode([]); // 👈 important
    }

    if (isAddingNew && newImage != null) {
      formMap["mocImages"] = await MultipartFile.fromFile(
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

  /// GET MOC LIST BY SITE ID
  Future<Response> getMocBySite({
    required String siteId,
  }) async {
    return await dio.get(
      "/moc",
      queryParameters: {
        "siteId": siteId,
      },
    );
  }

  /// UPDATE MOC (PUT)
  Future<Response> updateMoc({
    required String mocId,
    String? name,
    bool? isApplied,
    File? image,
  }) async {
    final formData = FormData.fromMap({
      if (name != null) "name": name,
      if (isApplied != null) "isApplied": isApplied.toString(),
      if (image != null)
        "image": await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
    });

    return await dio.put(
      "/moc/$mocId",
      data: formData,
      options: Options(
        contentType: "multipart/form-data",
      ),
    );
  }
  /// BULK DELETE MOC
  Future<Response> bulkDeleteMoc({
    required List<String> ids,
  }) async {
    return await dio.post(
      '/moc/bulk-delete',
      data: {
        'ids': ids,
      },
      options: Options(
        contentType: Headers.jsonContentType,
      ),
    );
  }


  /// DELETE MOC
  Future<Response> deleteMoc({
    required String mocId,
  }) async {
    return await dio.delete(
      "/moc/$mocId",
    );
  }
}
