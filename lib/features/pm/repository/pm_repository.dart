import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/api/dio.dart';

import '../models/pm_models.dart';

class PmRepository {
  final Dio _dio = DioClient.dio;

  bool _usesStructurePm(String workType) {
    final normalized = workType.toLowerCase();
    return normalized.contains('structure') ||
        normalized.contains('erection') ||
        normalized.contains('fabrication');
  }

  String _setupPath(String siteId, String workType) =>
      _usesStructurePm(workType)
          ? '/site/$siteId/structure-work/pm-resources'
          : '/site/$siteId/pm/setup';

  String _entryPath(String siteId, String workType) =>
      _usesStructurePm(workType)
          ? '/site/$siteId/structure-work/pm-entry'
          : '/site/$siteId/pm/entry';

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

  dynamic _dataField(dynamic responseData, String field) {
    if (responseData is! Map) return responseData;
    final data = responseData['data'];
    if (data is Map) return data[field];
    return responseData;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _normalizeDisplayKey(dynamic value) {
    return value
        .toString()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<PmCategory> _structureResourcesToCategories(dynamic responseData) {
    final resources = _asList(responseData);
    final grouped = <String, List<PmEquipment>>{};
    final seenEquipmentKeys = <String>{};
    for (final item in resources.whereType<Map>()) {
      final json = Map<String, dynamic>.from(item);
      final categoryName = (json['categoryName'] ?? 'P&M').toString();
      final categoryKey = (json['unitCode'] ?? categoryName).toString();
      final equipmentId = (json['_id'] ?? json['id'] ?? '').toString();
      final equipmentName =
          (json['resourceName'] ?? json['equipmentName'] ?? '').toString();
      final unit = (json['uom'] ?? json['unit'] ?? 'Nos.').toString();
      final dedupeKey = [
        _normalizeDisplayKey(categoryName),
        _normalizeDisplayKey(equipmentName),
        _normalizeDisplayKey(unit),
      ].join('::');
      if (seenEquipmentKeys.contains(dedupeKey)) continue;
      seenEquipmentKeys.add(dedupeKey);
      grouped.putIfAbsent(categoryName, () => []);
      grouped[categoryName]!.add(PmEquipment.fromJson({
        'id': equipmentId,
        'source': json['isDefault'] == true ? 'master' : 'custom',
        'categoryKey': categoryKey,
        'categoryName': categoryName,
        'equipmentName': equipmentName,
        'image': json['image'] ?? '',
        'capacity': json['capacity'] ?? json['requiredQty'] ?? '',
        'unit': unit,
        'isCustom': json['isDefault'] != true,
      }));
    }

    return grouped.entries.map((entry) {
      return PmCategory(
        categoryKey:
            entry.value.isNotEmpty ? entry.value.first.categoryKey : entry.key,
        categoryName: entry.key,
        equipment: entry.value,
      );
    }).toList();
  }

  Future<List<PmCategory>> getSetup(String siteId, String workType) async {
    final response = await _dio.get(_setupPath(siteId, workType));
    if (_usesStructurePm(workType)) {
      return _structureResourcesToCategories(response.data);
    }
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
    required String workType,
  }) async {
    await _dio.post(
      _setupPath(siteId, workType),
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
    required String workType,
  }) async {
    final path = _usesStructurePm(workType)
        ? '/site/$siteId/structure-work/pm-resources/${equipment.id}'
        : '/site/$siteId/pm/setup/equipment/${equipment.id}';
    await _dio.put(
      path,
      queryParameters:
          _usesStructurePm(workType) ? null : {'source': equipment.source},
      data: {
        'equipmentName': equipmentName,
        'capacity': capacity,
        'unit': unit,
        'image': image,
      },
    );
  }

  Future<void> deleteEquipment(
      String siteId, String workType, PmEquipment equipment) async {
    final path = _usesStructurePm(workType)
        ? '/site/$siteId/structure-work/pm-resources/${equipment.id}'
        : '/site/$siteId/pm/setup/equipment/${equipment.id}';
    await _dio.delete(
      path,
      queryParameters:
          _usesStructurePm(workType) ? null : {'source': equipment.source},
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

  Future<List<PmEntry>> getEntries(String siteId, String workType,
      {required String date}) async {
    final response = await _dio.get(
      _entryPath(siteId, workType),
      queryParameters: {'date': date},
    );
    if (_usesStructurePm(workType)) {
      final rows = _asList(_dataField(response.data, 'rows'));
      return rows.whereType<Map>().where((item) {
        return _toDouble(item['actualQty']) > 0 ||
            (item['remarks'] ?? '').toString().trim().isNotEmpty;
      }).map((item) {
        final json = Map<String, dynamic>.from(item);
        return PmEntry.fromJson({
          '_id': json['entryId'] ?? json['_id'],
          'equipmentId': json['_id'] ?? json['resourceId'],
          'entryDate': date,
          'categoryName': json['categoryName'],
          'equipmentName': json['resourceName'],
          'equipmentImage': json['image'] ?? '',
          'quantityExecuted': json['actualQty'],
          'unit': json['uom'],
          'workDescription': json['remarks'],
          'status': 'working',
        });
      }).toList();
    }
    return _asList(response.data)
        .whereType<Map>()
        .map((item) => PmEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<PmSummary> getDashboard(String siteId, String workType,
      {required String date}) async {
    if (_usesStructurePm(workType)) {
      final response = await _dio.get(
        _entryPath(siteId, workType),
        queryParameters: {'date': date},
      );
      final summary = _asMap(_dataField(response.data, 'summary'));
      return PmSummary.fromJson({
        'totalEquipment': summary['totalResources'],
        'totalEntries': summary['filledResources'],
        'runningEquipment': summary['filledResources'],
        'idleEquipment': summary['pendingResources'],
      });
    }
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
    if (_usesStructurePm(workType)) {
      await _dio.post(
        _entryPath(siteId, workType),
        data: {
          'date': date,
          'entries': [
            {
              'resourceId': equipment.id,
              'actualQty': _toDouble(data['quantityExecuted']),
              'remarks':
                  data['workDescription'] ?? data['activityPerformed'] ?? '',
            }
          ],
        },
      );
      return;
    }

    final entryId = data['entryId']?.toString() ?? '';
    final payload = {
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
    }..remove('entryId');

    if (entryId.isNotEmpty) {
      await _dio.put('/site/$siteId/pm/entry/$entryId', data: payload);
      return;
    }

    await _dio.post('/site/$siteId/pm/entry', data: payload);
  }
}
