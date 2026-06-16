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

  Future<List<DPRStructure>> getPebDPRList(
    String siteId, {
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    final apiType = _convertStructureTypeForDprApi(type);
    final params = <String, dynamic>{
      'section': apiType == 'fabrication_work' ? 'fabrication' : 'erection',
      'type': apiType,
    };
    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['endDate'] = endDate.toIso8601String();
    }

    final res = await DioClient.dio.get(
      '/site/$siteId/dpr-peb',
      queryParameters: params,
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => _dprStructureFromPeb(e.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<bool> deletePebDPR(String siteId, String dprId) async {
    final res = await DioClient.dio.delete('/site/$siteId/dpr-peb/$dprId');
    return res.statusCode == 200;
  }

  DPRStructure _dprStructureFromPeb(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((raw) => raw.cast<String, dynamic>())
            .expand((item) {
            final marks = item['assemblyMark']
                .toString()
                .split(',')
                .map((mark) => mark.trim())
                .where((mark) => mark.isNotEmpty)
                .toList();
            final effectiveMarks = marks.isEmpty
                ? <String>[item['name']?.toString() ?? 'Level 1']
                : marks;
            final qty = (item['actualQty'] as num?)?.toDouble() ?? 0;
            final perMarkQty = effectiveMarks.length > 1 ? 1.0 : qty;
            final totalWeight = _readPebItemWeightKg(item, qty);
            final perMarkWeight = effectiveMarks.length > 1
                ? totalWeight / effectiveMarks.length
                : totalWeight;
            return effectiveMarks.map(
              (mark) => DPRStructureItem(
                id: item['_id']?.toString() ?? '',
                assemblyMark: mark,
                qtyUsed: perMarkQty,
                netWeightPerUnit:
                    (item['netWeightPerUnit'] as num?)?.toDouble() ??
                        (item['estimatedWeightPerUnitKg'] as num?)?.toDouble(),
                totalNetWeight: perMarkWeight > 0 ? perMarkWeight : null,
              ),
            );
          }).toList()
        : <DPRStructureItem>[];

    final firstItem =
        rawItems is List && rawItems.isNotEmpty && rawItems.first is Map
            ? (rawItems.first as Map).cast<String, dynamic>()
            : <String, dynamic>{};
    final team = json['teamId'];
    final createdBy = json['createdBy'];
    final dprDate = DateTime.tryParse((json['date'] ?? '').toString());
    final createdAt = DateTime.tryParse((json['createdAt'] ?? '').toString());
    final updatedAt = DateTime.tryParse((json['updatedAt'] ?? '').toString());
    final totalQty = items.fold<double>(0, (sum, item) => sum + item.qtyUsed);
    final totalWeight = items.fold<double>(
      0,
      (sum, item) => sum + (item.totalNetWeight ?? 0),
    );
    final stageName = firstItem['name']?.toString() ??
        firstItem['memberType']?.toString() ??
        (json['section']?.toString() ?? 'Structure DPR');
    final id = json['_id']?.toString() ?? '';
    final fallbackDprNumber =
        id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();

    return DPRStructure(
      id: id,
      dprName: stageName,
      dprNumber: json['dprNumber']?.toString() ?? fallbackDprNumber,
      siteId: json['siteId'] is Map
          ? json['siteId']['_id']?.toString()
          : json['siteId']?.toString(),
      siteName:
          json['siteId'] is Map ? json['siteId']['siteName']?.toString() : null,
      company: json['company'] is Map
          ? json['company']['_id']?.toString()
          : json['company']?.toString(),
      type: json['type']?.toString(),
      items: items,
      totalQtyUsed: totalQty,
      totalNetWeight: totalWeight,
      date: dprDate,
      status: json['status']?.toString() ?? 'submitted',
      remarks: json['remarks']?.toString(),
      createdByName:
          createdBy is Map ? createdBy['fullName']?.toString() : null,
      createdAt: createdAt,
      teamId: team is Map ? team['_id']?.toString() : team?.toString(),
      teamName: team is Map ? team['teamName']?.toString() : null,
      updatedAt: updatedAt,
    );
  }

  double _readPebItemWeightKg(Map<String, dynamic> item, double actualQty) {
    for (final key in [
      'totalWeightKg',
      'manualWeightKg',
      'totalWeight',
      'totalNetWeight',
      'weightKg',
      'weight',
    ]) {
      final value = item[key];
      if (value is num && value > 0) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }

    final perUnit = (item['estimatedWeightPerUnitKg'] as num?)?.toDouble() ??
        (item['netWeightPerUnit'] as num?)?.toDouble() ??
        0;
    return actualQty * perUnit;
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
    final apiType = _convertStructureTypeForApi(type);
    if (sheetType == 'detailed-with-pm' ||
        sheetType == 'detailed' ||
        sheetType == 'date-mark-default') {
      final res = await DioClient.dio.get<List<int>>(
        '/site/$siteId/structure-work/sheets',
        queryParameters: {
          'fromDate': fromDate,
          'toDate': toDate,
          'sheetType': sheetType,
          'format': format,
          'type': apiType,
        },
        options: Options(
          responseType: ResponseType.bytes,
          extra: {"withCredentials": true},
        ),
      );
      final data = res.data;
      if (data != null) return Uint8List.fromList(data);
      throw Exception('Invalid response format: expected binary sheet data');
    }

    final apiSheetType = sheetType == 'invoice-v2' ? 'invoice' : sheetType;
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

  String _convertStructureTypeForDprApi(String? type) {
    switch (type) {
      case 'fabrication_work':
      case 'fabrication':
      case 'structure_fabrication':
        return 'fabrication_work';
      case 'structure_work':
      case 'erection_work':
      case 'erection':
      case 'structure_erection':
      case null:
      case '':
        return 'erection_work';
      default:
        return 'erection_work';
    }
  }
}
