import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/api/dio.dart';

import '../models/pm_models.dart';

class PmRepository {
  final Dio _dio = DioClient.dio;

  List<dynamic> _asList(dynamic responseData) {
    final data = responseData is Map ? responseData['data'] : responseData;
    if (data is List) return data;
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic responseData) {
    final data = responseData is Map
        ? responseData['data'] ?? responseData
        : responseData;
    if (data is Map) return Map<String, dynamic>.from(data);
    return const {};
  }

  Future<List<PmCategory>> getSetup(String siteId) async {
    final response = await _dio.get('/site/$siteId/pm/setup');
    return _asList(response.data)
        .whereType<Map>()
        .map((item) => PmCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> addEquipment(
    String siteId, {
    required String categoryKey,
    required String categoryName,
    required String equipmentName,
    required String capacity,
    required String unit,
    required String image,
  }) async {
    await _dio.post(
      '/site/$siteId/pm/setup',
      data: {
        'categoryKey': categoryKey,
        'categoryName': categoryName,
        'equipmentName': equipmentName,
        'capacity': capacity,
        'unit': unit,
        'image': image,
      },
    );
  }

  Future<void> updateEquipment(
    String siteId,
    PmEquipment equipment, {
    required String equipmentName,
    required String capacity,
    required String unit,
    required String image,
  }) async {
    await _dio.put(
      '/site/$siteId/pm/setup/equipment/${equipment.id}',
      queryParameters: {'source': equipment.source},
      data: {
        'equipmentName': equipmentName,
        'capacity': capacity,
        'unit': unit,
        'image': image,
      },
    );
  }

  Future<void> deleteEquipment(String siteId, PmEquipment equipment) async {
    await _dio.delete(
      '/site/$siteId/pm/setup/equipment/${equipment.id}',
      queryParameters: {'source': equipment.source},
    );
  }

  Future<String> uploadImage(String siteId, PlatformFile file) async {
    final path = file.path;
    if (path == null || path.isEmpty) return '';
    final response = await _dio.post(
      '/site/$siteId/pm/setup/upload-image',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: file.name),
      }),
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    final urls = response.data is Map ? response.data['urls'] as List? : null;
    return urls?.isNotEmpty == true ? urls!.first.toString() : '';
  }

  Future<List<PmEntry>> getEntries(String siteId,
      {required String date}) async {
    final response = await _dio.get(
      '/site/$siteId/pm/entry',
      queryParameters: {'date': date},
    );
    return _asList(response.data)
        .whereType<Map>()
        .map((item) => PmEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<PmSummary> getDashboard(String siteId, {required String date}) async {
    final response = await _dio.get(
      '/site/$siteId/pm/dashboard',
      queryParameters: {'date': date},
    );
    return PmSummary.fromJson(_asMap(response.data));
  }

  Future<void> createEntry(
    String siteId, {
    required PmEquipment equipment,
    required String date,
    required String workType,
    required Map<String, dynamic> data,
  }) async {
    await _dio.post(
      '/site/$siteId/pm/entry',
      data: {
        'type': workType,
        'entryDate': date,
        'categoryKey': equipment.categoryKey,
        'categoryName': equipment.categoryName,
        if (equipment.source == 'custom')
          'equipmentOverrideId': equipment.id
        else
          'masterEquipmentId': equipment.id,
        'equipmentName': equipment.equipmentName,
        'equipmentImage': equipment.image,
        ...data,
      },
    );
  }
}
