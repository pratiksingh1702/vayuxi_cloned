import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../../core/api/dio.dart';
import '../models/pipingModel.dart';
import '../models/equipmentModel.dart';

class DefaultMaterialService {
  final Dio _dio = DioClient.dio;

  /// ---------------------------------------------------------------------------
  /// SETUP DPR (Initialize defaults)
  /// POST /default-material/setup
  /// ---------------------------------------------------------------------------
  Future<List<dynamic>> setupDpr({
    required String siteId,
    required String designation, // piping | equipment | both
    bool isApplied = false,
  }) async {
    final res = await _dio.post(
      '/default-material/setup',
      data: {
        "siteId": siteId,
        "designation": designation,
        "isApplied": isApplied,
      },
    );

    final List list = res.data['materials'] ?? [];
    return _mapMaterials(list);
  }

  /// ---------------------------------------------------------------------------
  /// GET DEFAULT MATERIALS
  /// GET /default-material
  /// ---------------------------------------------------------------------------
  Future<List<dynamic>> getDefaultMaterials({
    String? siteId,
    String? designation,
  }) async {
    final res = await _dio.get(
      '/default-material',
      queryParameters: {
        if (siteId != null) "siteId": siteId,
        if (designation != null) "designation": designation,
      },
    );

    return _mapMaterials(res.data);
  }

  /// ---------------------------------------------------------------------------
  /// CREATE CUSTOM MATERIAL
  /// POST /default-material
  /// ---------------------------------------------------------------------------
  Future<dynamic> createMaterial({
    required String materialName,
    required String uom,
    required String calculationCategory,
    required String designation,
    String? siteId,
    bool isApplied = false,
    File? image,
  }) async {
    final form = FormData.fromMap({
      "materialName": materialName,
      "uom": uom,
      "calculationCategory": calculationCategory,
      "designation": designation,
      "site": siteId,
      "isApplied": isApplied,
      if (image != null)
        "image": await MultipartFile.fromFile(image.path),
    });

    final res = await _dio.post('/default-material', data: form);
    return _mapSingle(res.data);
  }

  /// ---------------------------------------------------------------------------
  /// UPDATE MATERIAL
  /// PUT /default-material/:id
  /// ---------------------------------------------------------------------------
  Future<dynamic> updateMaterial({
    required String id,
    String? materialName,
    String? uom,
    String? calculationCategory,
    bool? isApplied,
    File? image,
  }) async {
    final form = FormData.fromMap({
      if (materialName != null) "materialName": materialName,
      if (uom != null) "uom": uom,
      if (calculationCategory != null)
        "calculationCategory": calculationCategory,
      if (isApplied != null) "isApplied": isApplied,
      if (image != null)
        "image": await MultipartFile.fromFile(image.path),
    });

    final res = await _dio.put('/default-material/$id', data: form);
    return _mapSingle(res.data);
  }

  /// ---------------------------------------------------------------------------
  /// DELETE SINGLE MATERIAL
  /// DELETE /default-material/:id
  /// ---------------------------------------------------------------------------
  Future<void> deleteMaterial(String id) async {
    await _dio.delete('/default-material/$id');
  }

  /// ---------------------------------------------------------------------------
  /// BULK DELETE
  /// POST /default-material/bulk-delete
  /// ---------------------------------------------------------------------------
  Future<void> bulkDelete(List<String> ids) async {
    await _dio.post(
      '/default-material/bulk-delete',
      data: {"ids": ids},
    );
  }

  /// ---------------------------------------------------------------------------
  /// REFRESH MATERIALS
  /// POST /default-material/refresh
  /// ---------------------------------------------------------------------------
  Future<List<dynamic>> refreshMaterials({
    required String siteId,
    required String designation,
    bool isApplied = false,
  }) async {
    final res = await _dio.post(
      '/default-material/refresh',
      data: {
        "siteId": siteId,
        "designation": designation,
        "isApplied": isApplied,
      },
    );

    return _mapMaterials(res.data['materials'] ?? []);
  }

  /// ===========================================================================
  /// INTERNAL MAPPERS
  /// ===========================================================================

  List<dynamic> _mapMaterials(List list) {
    return list.map(_mapSingle).toList();
  }

  dynamic _mapSingle(dynamic json) {
    final String des = json['designation'];

    if (des == 'piping') {
      return PipingItem.fromJson({
        ...json,
        "qty": 0,
        "length": 0,
        "rmt": 0,
        "diameter": 0,
        "weight": 0,
        "power": 0,
        "actualRate": 0,
        "rate": 0,
        "moc": "",
        "size": "",
        "location": "",
        "plant": "",
        "designation": [des],
      });
    }

    return EquipmentItem.fromJson({
      ...json,
      "qty": 0,
      "length": 0,
      "rmt": 0,
      "diameter": 0,
      "weight": 0,
      "power": 0,
      "actualRate": 0,
      "rate": 0,
      "moc": "",
      "size": "",
      "location": "",
      "plant": "",
      "designation": [des],
    });
  }
}
