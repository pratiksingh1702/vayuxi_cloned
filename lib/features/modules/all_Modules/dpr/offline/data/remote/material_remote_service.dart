import '../../../../../../../core/api/dio.dart';
import '../../../dpr_insu/service/material_service.dart';
import '../../../providers/dpr_material_service.dart';

import '../local/local_material.dart';
import 'package:dio/dio.dart';

class MaterialRemoteService {
  final _insulation = InsulationMaterialSetupService();
  final Dio _dio = DioClient.dio;

  /// ---------------- INSULATION ----------------
  ///
  Future<Map<String, dynamic>> fetchInsulation(String siteId) {
    return _insulation.getMaterials(siteId: siteId);
  }
  Future<Map<String, dynamic>> fetchInsulationRaw(String siteId) async {
    final response = await _dio.get(
      '/insulation-dpr-setup/materials',
      queryParameters: {'siteId': siteId},
    );

    return Map<String, dynamic>.from(response.data);
  }
  Future<void> createInsulation(LocalMaterial m) {
    return _insulation.createMaterial(
      siteId: m.siteId,
      name: m.name,
      designation: m.designation,
      uom: m.uom,
    );
  }

  Future<void> updateInsulation(LocalMaterial m) {
    return _insulation.updateMaterial(
      materialId: m.serverId!,
      name: m.name,
    );
  }

  Future<void> deleteInsulation(LocalMaterial m) {
    return _insulation.deleteMaterial(m.serverId!);
  }

  /// ---------------- MECHANICAL ----------------
  Future<Map<String, dynamic>> fetchMechanical({
    required String siteId,
    required String dprId,
  }) {
    return DprMaterialService.fetchMaterialById(
      mechanicalId: siteId,
      editDprId: dprId,
    );
  }

  Future<void> createMechanical(LocalMaterial m) {
    // mechanical uses FormData normally – simplified here
    return Future.value();
  }

  Future<void> updateMechanical(LocalMaterial m) {
    return Future.value();
  }

  Future<void> deleteMechanical(LocalMaterial m) {
    return Future.value();
  }
}
