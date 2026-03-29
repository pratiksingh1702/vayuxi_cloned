import 'dart:io';
import 'package:dio/dio.dart';

import '../../../../../../core/api/dio.dart';
import '../model/eqip_insu.dart';
import '../model/piping_insu.dart';
import '../model/material_setup.dart';


class InsulationMaterialSetupService {
  final Dio _dio = DioClient.dio;

  /// ================================
  /// FETCH MATERIALS WITH SETUP CONFIG
  /// ================================
  
  /// Fetch raw material setup data (includes fieldConfig)
  Future<Map<String, dynamic>> fetchInsulationRaw(String siteId) async {
    final response = await _dio.get(
      '/insulation-dpr-setup/materials',
      queryParameters: {'siteId': siteId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Fetch material setup configurations
  Future<List<MaterialSetup>> fetchMaterialSetup({
    required String siteId,
    String? designation,
  }) async {
    try {
      final response = await _dio.get(
        '/insulation-dpr-setup/materials',
        queryParameters: {
          'siteId': siteId,
          if (designation != null) 'designation': designation,
        },
      );

      final List list = response.data['data'] ?? [];
      return list.map((json) => MaterialSetup.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetching material setup: $e');
      rethrow;
    }
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

  /// MAPPERS - Convert MaterialSetup to runtime materials
  PipingMaterial _toPipingMaterial(Map<String, dynamic> json) {
    return PipingMaterial(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: List<String>.from(json['image'] ?? []),
      uom: json['uom'] ?? '',
      materialCode: json['materialCode'] ?? json['material_code'],
      size: json['size']?.toString(),
      sizeUom: json['sizeUom'] ?? json['size_uom'],
    );
  }

  EquipmentMaterial _toEquipmentMaterial(Map<String, dynamic> json) {
    return EquipmentMaterial(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: List<String>.from(json['image'] ?? []),
      uom: json['uom'] ?? '',
      materialCode: json['materialCode'] ?? json['material_code'],
    );
  }

  /// Convert MaterialSetup to PipingMaterial for UI
  PipingMaterial materialSetupToPiping(MaterialSetup setup) {
    return PipingMaterial(
      id: setup.id,
      name: setup.name,
      image: setup.image,
      uom: setup.uom,
      materialCode: setup.materialCode,
    );
  }

  /// Convert MaterialSetup to EquipmentMaterial for UI
  EquipmentMaterial materialSetupToEquipment(MaterialSetup setup) {
    return EquipmentMaterial(
      id: setup.id,
      name: setup.name,
      image: setup.image,
      uom: setup.uom,
      materialCode: setup.materialCode,
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
  Future<List<String>> updateMaterial({
    required String materialId,
    String? name,
    List<File>? images,
  }) async {
    final formData = FormData();
    if (name != null) formData.fields.add(MapEntry('name', name));
    if (images != null && images.isNotEmpty) {
      for (final image in images) {
        formData.files.add(MapEntry(
          'images',
          MultipartFile.fromFileSync(image.path, filename: image.path.split('/').last),
        ));
      }
    }

    final response = await _dio.put(
      '/insulation-dpr-setup/materials/$materialId',
      data: formData,
    );

    // Parse the returned image list from server response
    final data = response.data['data'] as Map<String, dynamic>?;
    final rawImages = data?['image'] as List<dynamic>?;
    return rawImages?.map((e) => e.toString()).toList() ?? [];
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
  /// FIELD CONFIGURATION MANAGEMENT
  /// ================================

  /// Update field configuration for a material
  Future<MaterialSetup> updateFieldConfig({
    required String materialId,
    required List<Map<String, dynamic>> fieldUpdates,
  }) async {
    try {
      final response = await _dio.put(
        '/insulation-dpr-setup/materials/$materialId/field-config',
        data: {'fieldUpdates': fieldUpdates},
      );
      return MaterialSetup.fromJson(response.data['material']);
    } catch (e) {
      print('❌ Error updating field config: $e');
      rethrow;
    }
  }

  /// Add custom field to a material
  Future<MaterialSetup> addCustomField({
    required String materialId,
    required Map<String, dynamic> fieldDef,
  }) async {
    try {
      final response = await _dio.post(
        '/insulation-dpr-setup/materials/$materialId/custom-field',
        data: {'fieldDef': fieldDef},
      );
      return MaterialSetup.fromJson(response.data['material']);
    } catch (e) {
      print('❌ Error adding custom field: $e');
      rethrow;
    }
  }

  /// Remove custom field from a material
  Future<MaterialSetup> removeCustomField({
    required String materialId,
    required String fieldKey,
  }) async {
    try {
      final response = await _dio.delete(
        '/insulation-dpr-setup/materials/$materialId/custom-field/$fieldKey',
      );
      return MaterialSetup.fromJson(response.data['material']);
    } catch (e) {
      print('❌ Error removing custom field: $e');
      rethrow;
    }
  }

}
