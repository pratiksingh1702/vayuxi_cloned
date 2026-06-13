import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/dpr_structure_model.dart';

class DPRStructureRepository {
  // POST /api/v1/site/{siteId}/dpr-structure
  Future<DPRStructure> createDPR(
    String siteId, {
    required List<Map<String, dynamic>> items,
    String? dprName,
    DateTime? date,
    String? remarks,
    String? teamId,
    String? plant,
    String? location,
    String? moc,
    double? size,
    String? unit,
  }) async {
    // items should be list of {"assemblyMark": "...", "qtyUsed": ..., "boqItemId": "..."}
    final body = <String, dynamic>{
      'items': items
          .map((e) => {
                'assemblyMark': e['assemblyMark'] ?? e['assembly_mark'],
                'qtyUsed': e['qtyUsed'] ?? e['qty_used'],
              })
          .toList(),
    };
    if (dprName != null && dprName.isNotEmpty) body['dprName'] = dprName;
    if (date != null) body['date'] = date.toIso8601String();
    if (remarks != null && remarks.isNotEmpty) body['remarks'] = remarks;
    if (teamId != null && teamId.isNotEmpty) body['teamId'] = teamId;
    if (plant != null && plant.isNotEmpty) body['plant'] = plant;
    if (location != null && location.isNotEmpty) body['location'] = location;
    if (moc != null && moc.isNotEmpty) body['moc'] = moc;
    if (size != null) body['size'] = size;
    if (unit != null && unit.isNotEmpty) body['unit'] = unit;

    final res =
        await DioClient.dio.post('/site/$siteId/dpr-structure', data: body);
    return DPRStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // GET /api/v1/site/{siteId}/dpr-structure
  Future<List<DPRStructure>> getDPRList(
    String siteId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{};
    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['endDate'] = endDate.toIso8601String();
    }

    final res = await DioClient.dio.get(
      '/site/$siteId/dpr-structure',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => DPRStructure.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // GET /api/v1/site/{siteId}/dpr-structure/{dprId}
  Future<DPRStructure> getDPRDetail(String siteId, String dprId) async {
    final res = await DioClient.dio.get('/site/$siteId/dpr-structure/$dprId');
    return DPRStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // DELETE /api/v1/site/{siteId}/dpr-structure/{dprId}
  Future<bool> deleteDPR(String siteId, String dprId) async {
    final res =
        await DioClient.dio.delete('/site/$siteId/dpr-structure/$dprId');
    return res.statusCode == 200;
  }

  // PUT /api/v1/site/{siteId}/dpr-structure/{dprId}
  Future<DPRStructure> updateDPR(
    String siteId,
    String dprId, {
    List<Map<String, dynamic>>? items,
    String? dprName,
    String? remarks,
    String? status,
    bool replaceMode = false,
    String? plant,
    String? location,
    String? moc,
    double? size,
    String? unit,
  }) async {
    final body = <String, dynamic>{
      'replaceMode': replaceMode,
    };
    if (items != null) {
      body['items'] = items
          .map((e) => {
                'assemblyMark': e['assemblyMark'] ?? e['assembly_mark'],
                'qtyUsed': e['qtyUsed'] ?? e['qty_used'],
              })
          .toList();
    }
    if (dprName != null && dprName.isNotEmpty) body['dprName'] = dprName;
    if (remarks != null && remarks.isNotEmpty) body['remarks'] = remarks;
    if (status != null && status.isNotEmpty) body['status'] = status;
    if (plant != null && plant.isNotEmpty) body['plant'] = plant;
    if (location != null && location.isNotEmpty) body['location'] = location;
    if (moc != null && moc.isNotEmpty) body['moc'] = moc;
    if (size != null) body['size'] = size;
    if (unit != null && unit.isNotEmpty) body['unit'] = unit;

    final res = await DioClient.dio
        .put('/site/$siteId/dpr-structure/$dprId', data: body);
    return DPRStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // GET /api/v1/site/{siteId}/structure-work/sheets
  Future<Uint8List> downloadSheet(
    String siteId, {
    required String fromDate,
    required String toDate,
    required String sheetType,
    required String format,
    String? type,
  }) async {
    final apiSheetType = sheetType == 'invoice-v2' ? 'invoice' : sheetType;
    final apiType = _convertStructureTypeForApi(type);
    final res = await DioClient.dioV2.get(
      '/site/$siteId/sheets/$apiSheetType',
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'format': format,
        'type': apiType,
      },
      options: Options(extra: {"withCredentials": true}),
    );
    if (res.data is Map && res.data['data'] is String) {
      return base64Decode(res.data['data'] as String);
    }
    throw Exception('Invalid response format: expected {data: base64String}');
  }

  String _convertStructureTypeForApi(String? type) {
    switch (type) {
      case 'fabrication_work':
      case 'fabrication':
        return 'structure_fabrication';
      case 'structure_fabrication':
        return 'structure_fabrication';
      case 'structure_erection':
        return 'structure_erection';
      case 'structure_work':
      case 'erection_work':
      case 'erection':
      case null:
      case '':
        return 'structure_erection';
      default:
        return 'structure_erection';
    }
  }
}
