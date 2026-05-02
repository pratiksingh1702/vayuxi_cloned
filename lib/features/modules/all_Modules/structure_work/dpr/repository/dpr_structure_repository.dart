import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/dpr_structure_model.dart';

class DPRStructureRepository {
  // POST /api/v1/site/{siteId}/dpr-structure
  Future<DPRStructure> createDPR(
    String siteId, {
    required String boqId,
    required List<Map<String, dynamic>> items,
    DateTime? date,
    String? remarks,
    String? teamId,
  }) async {
    // items should be list of {"assemblyMark": "...", "qtyUsed": ..., "boqItemId": "..."}
    final body = <String, dynamic>{
      'boqId': boqId,
      'items': items.map((e) => {
        'assemblyMark': e['assemblyMark'] ?? e['assembly_mark'],
        'qtyUsed': e['qtyUsed'] ?? e['qty_used'],
        'boqItemId': e['boqItemId'] ?? e['boq_item_id'],
      }).toList(),
    };
    if (date != null) body['date'] = date.toIso8601String();
    if (remarks != null && remarks.isNotEmpty) body['remarks'] = remarks;
    if (teamId != null && teamId.isNotEmpty) body['teamId'] = teamId;

    final res = await DioClient.dio.post('/site/$siteId/dpr-structure', data: body);
    return DPRStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // GET /api/v1/site/{siteId}/dpr-structure
  Future<List<DPRStructure>> getDPRList(
    String siteId, {
    DateTime? startDate,
    DateTime? endDate,
    String? boqId,
  }) async {
    final params = <String, dynamic>{};
    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['endDate'] = endDate.toIso8601String();
    }
    if (boqId != null && boqId.isNotEmpty) {
      params['boqId'] = boqId;
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
    final res =
        await DioClient.dio.get('/site/$siteId/dpr-structure/$dprId');
    return DPRStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // DELETE /api/v1/site/{siteId}/dpr-structure/{dprId}
  Future<bool> deleteDPR(String siteId, String dprId) async {
    final res = await DioClient.dio.delete('/site/$siteId/dpr-structure/$dprId');
    return res.statusCode == 200;
  }

  // GET /api/v1/site/{siteId}/structure-work/sheets
  Future<Uint8List> downloadSheet(
    String siteId, {
    required String fromDate,
    required String toDate,
    required String sheetType,
    required String format,
  }) async {
    final res = await DioClient.dio.get(
      '/site/$siteId/structure-work/sheets',
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'sheetType': sheetType,
        'format': format,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data as List<int>);
  }
}
