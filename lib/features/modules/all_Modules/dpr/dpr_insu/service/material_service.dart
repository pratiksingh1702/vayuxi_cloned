import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../../../core/api/dio.dart';
import '../model/eqip_insu.dart';
import '../model/piping_insu.dart';


class InsulationMaterialSetupService {
  final Dio _dio = DioClient.dio;

  /// ================================
  /// FETCH MATERIALS
  /// ================================
  /// FETCH ALL MATERIALS
  Future<Map<String, dynamic>> fetchInsulationRaw(String siteId) async {
      final response = await _dio.get(
        '/insulation-dpr-setup/materials',
        queryParameters: {'siteId': siteId},
      );

      return Map<String, dynamic>.from(response.data);
    }
  Future<Map<String, dynamic>> getMaterials({
    required String siteId,
    String? designation, // piping | equipment
  }) async {
    try {
      final response = await _dio.get(
        '/insulation-dpr-setup/materials',
        queryParameters: {
          'siteId': siteId,
          if (designation != null) 'designation': designation,
        },
      );

      final List list = response.data['data'];
      final int count = response.data['count'];

      // Separate piping and equipment materials
      final List<PipingMaterial> pipingMaterials = [];
      final List<EquipmentMaterial> equipmentMaterials = [];

      for (final json in list) {
        if (json['designation'] == 'piping') {
          pipingMaterials.add(_toPipingMaterial(json));
        } else if (json['designation'] == 'equipment') {
          equipmentMaterials.add(_toEquipmentMaterial(json));
        }
      }

      return {
        'pipingMaterials': pipingMaterials,
        'equipmentMaterials': equipmentMaterials,
        'totalCount': count,
      };
    } catch (e) {
      print('❌ Error fetching insulation materials: $e');
      rethrow;
    }
  }

  /// MAPPERS
  PipingMaterial _toPipingMaterial(Map<String, dynamic> json) {
    return PipingMaterial(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: List<String>.from(json['image'] ?? []),
      uom: json['uom'] ?? '',
      size: "", // Default value - will be set during DPR creation

      // DPR-runtime values → ZERO for setup
      qty: 0,
      length: 0,
      circumference: 0,
      circumference1: 0,
      circumference2: 0,
      zHeight: 0,
      gSlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: '',

    );
  }

  EquipmentMaterial _toEquipmentMaterial(Map<String, dynamic> json) {
    return EquipmentMaterial(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: List<String>.from(json['image'] ?? []),
      uom: json['uom'] ?? '',

      // DPR-runtime values → ZERO for setup
      qty: 0,
      length: 0,
      circumference: 0,
      circumference1: 0,
      circumference2: 0,
      zHeight: 0,
      gSlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: '',

    );
  }

  /// ================================
  /// CREATE MATERIAL
  /// ================================

  Future<void> createMaterial({
    required String siteId,
    required String name,
    required String designation,
    String? uom,
    List<File>? images,
  }) async {
    final formData = FormData.fromMap({
      'siteId': siteId,
      'name': name,
      'designation': designation,
      if (uom != null) 'uom': uom,
      if (images != null)
        'images': images.map(
              (f) => MultipartFile.fromFileSync(f.path),
        ),
    });

    await _dio.post(
      '/insulation-dpr-setup/materials',
      data: formData,
    );
  }

  /// ================================
  /// UPDATE MATERIAL
  /// ================================

  Future<void> updateMaterial({
    required String materialId,
    String? name,
    List<File>? images,
  }) async {
    final formData = FormData.fromMap({
      if (name != null) 'name': name,
      if (images != null)
        'images': images.map(
              (f) => MultipartFile.fromFileSync(f.path),
        ),
    });

    await _dio.put(
      '/insulation-dpr-setup/materials/$materialId',
      data: formData,
    );
  }

  /// ================================
  /// DELETE MATERIAL
  /// ================================

  Future<void> deleteMaterial(String id) async {
    await _dio.delete('/insulation-dpr-setup/materials/$id');
  }

  /// ================================
  /// BULK DELETE
  /// ================================

  Future<void> bulkDelete(List<String> ids) async {
    await _dio.post(
      '/insulation-dpr-setup/materials/bulk-delete',
      data: {'ids': ids},
    );
  }

  /// ================================
  /// COPY MATERIAL
  /// ================================
  Future<Map<String, dynamic>> copyMaterial(String id) async {
    final response =
    await _dio.post('/insulation-dpr-setup/materials/copy/$id');

    return response.data as Map<String, dynamic>;
  }

  /// ================================
  /// APPLY TO ALL SITES
  /// ================================

  Future<void> applyToAllSites(String siteId) async {
    await _dio.post(
      '/insulation-dpr-setup/materials/apply-all',
      data: {'siteId': siteId},
    );
  }

  /// ================================
  /// MAPPERS (IMPORTANT)
  /// ================================

}
