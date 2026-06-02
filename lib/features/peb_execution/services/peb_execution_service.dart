import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/peb_execution_models.dart';

class PebExecutionConflict implements Exception {
  final List<dynamic> conflicts;

  PebExecutionConflict(this.conflicts);
}

class PebExecutionService {
  final Dio _dio = DioClient.dio;

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    if (data is Map && data['success'] == true && data['data'] is List) {
      return data['data'] as List;
    }
    return const [];
  }

  Future<List<PebTeam>> getTeams(String siteId, PebExecutionType type) async {
    final response = await _dio.get(
      '/site/$siteId/team',
      queryParameters: {'type': type.apiType},
    );
    return _asList(response.data)
        .whereType<Map>()
        .map((item) => PebTeam.fromJson(Map<String, dynamic>.from(item)))
        .where((team) => team.id.isNotEmpty)
        .toList();
  }

  Future<PebSetup?> getSetup(String siteId, PebExecutionType type) async {
    final params = {
      'type': type.apiType,
      'section': type.section,
      if (type == PebExecutionType.erection) 'trackingLevel': 'advanced',
    };
    final response =
        await _dio.get('/site/$siteId/peb-setup', queryParameters: params);
    final list = _asList(response.data);
    if (list.isEmpty || list.first is! Map) return null;
    return PebSetup.fromJson(Map<String, dynamic>.from(list.first as Map));
  }

  Future<PebSetup?> resetSetup(
    String siteId,
    PebExecutionType type, {
    String trackingLevel = 'advanced',
  }) async {
    final response = await _dio.post(
      '/site/$siteId/peb-setup/reset',
      data: {
        'section': type.section,
        'type': type.apiType,
        if (type == PebExecutionType.erection) 'trackingLevel': trackingLevel,
      },
    );
    final data = response.data is Map
        ? response.data['data'] ?? response.data
        : response.data;
    if (data is Map) {
      return PebSetup.fromJson(Map<String, dynamic>.from(data));
    }
    return getSetup(siteId, type);
  }

  Future<void> saveSetupItem(
    String siteId,
    PebExecutionType type, {
    String? itemId,
    required String name,
    required String uom,
    required String remarks,
    required num targetQty,
  }) async {
    final payload = {
      'name': name,
      'uom': uom,
      'remarks': remarks,
      'targetQty': targetQty,
      'section': type.section,
      'type': type.apiType,
    };
    if (itemId == null || itemId.isEmpty) {
      await _dio.post('/site/$siteId/peb-setup', data: payload);
    } else {
      await _dio.put(
        '/site/$siteId/peb-setup/item/$itemId',
        queryParameters: {'section': type.section},
        data: payload,
      );
    }
  }

  Future<void> deleteSetupItem(
    String siteId,
    PebExecutionType type,
    String itemId,
  ) async {
    await _dio.delete(
      '/site/$siteId/peb-setup/item/$itemId',
      queryParameters: {'section': type.section},
    );
  }

  Future<void> updateFallbackSetting(
    String siteId,
    PebExecutionType type,
    bool enabled,
  ) async {
    await _dio.put(
      '/site/$siteId/peb-setup',
      data: {
        'type': type.apiType,
        'section': type.section,
        'allowUnassignedDprFallback': enabled,
      },
    );
  }

  Future<List<PebBoq>> getBoqs(String siteId) async {
    final response = await _dio.get(
      '/site/$siteId/boq-structure',
      queryParameters: {'excludeSourceType': 'procurement'},
    );
    return _asList(response.data)
        .whereType<Map>()
        .map((item) => PebBoq.fromJson(Map<String, dynamic>.from(item)))
        .where((boq) => boq.id.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> previewBoqUpload(
      String siteId, PlatformFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path!, filename: file.name),
    });
    final response = await _dio.post(
      '/site/$siteId/peb-boq-mapping/preview',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data['data'] ?? response.data);
  }

  Future<void> importBoqUpload(
    String siteId,
    PlatformFile file, {
    List<Map<String, String>> mappings = const [],
    bool skipMapping = false,
    bool isStandardTemplate = false,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path!, filename: file.name),
    });
    final query = <String, dynamic>{};
    if (!skipMapping && !isStandardTemplate && mappings.isNotEmpty) {
      query['mappings'] = jsonEncode(mappings);
    }
    await _dio.post(
      '/site/$siteId/peb-boq-mapping/import',
      queryParameters: query,
      data: formData,
    );
  }

  Future<List<dynamic>> getBoqItems(String siteId, String boqId) async {
    final response = await _dio.get('/site/$siteId/boq-structure/$boqId/items');
    final data = response.data is Map
        ? response.data['data'] ?? response.data
        : response.data;
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return const [];
  }

  Future<void> deleteBoq(String siteId, String boqId) async {
    await _dio.delete('/site/$siteId/boq-structure/$boqId');
  }

  Future<void> createManualBoq(
    String siteId,
    PebExecutionType type, {
    required String boqName,
    required List<Map<String, dynamic>> items,
  }) async {
    await _dio.post('/site/$siteId/boq-structure', data: {
      'boqName': boqName,
      'type': type.apiType,
      'items': items,
    });
  }

  Future<List<PebWorkAssignment>> getAssignments(
    String siteId,
    PebExecutionType type, {
    String status = 'all',
    String? teamId,
  }) async {
    final response = await _dio.get(
      '/site/$siteId/work-assignment',
      queryParameters: {
        'type': type.apiType,
        'section': type.section,
        'status': status,
        if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
      },
    );
    return _asList(response.data)
        .whereType<Map>()
        .map((item) =>
            PebWorkAssignment.fromJson(Map<String, dynamic>.from(item)))
        .where((assignment) => assignment.id.isNotEmpty)
        .toList();
  }

  Future<void> saveAssignment(
    String siteId,
    PebExecutionType type, {
    String? assignmentId,
    required String teamId,
    required String sourceType,
    required DateTime assignmentDate,
    DateTime? expectedCompletionDate,
    required List<String> boqIds,
    required PebAssignmentItem item,
    bool overrideConflict = false,
  }) async {
    final payload = {
      'type': type.apiType,
      'section': type.section,
      'teamId': teamId,
      'sourceType': sourceType,
      'boqIds': boqIds,
      'assignmentDate': assignmentDate.toIso8601String().split('T').first,
      if (expectedCompletionDate != null)
        'expectedCompletionDate':
            expectedCompletionDate.toIso8601String().split('T').first,
      'overrideAssignmentConflict': overrideConflict,
      'status': 'active',
      'assignments': [item.toJson()],
    };

    try {
      if (assignmentId == null || assignmentId.isEmpty) {
        await _dio.post('/site/$siteId/work-assignment', data: payload);
      } else {
        await _dio.put('/site/$siteId/work-assignment/$assignmentId',
            data: payload);
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode == 409 &&
          data is Map &&
          data['code'] == 'WORK_ASSIGNMENT_CONFLICT') {
        throw PebExecutionConflict(
            data['conflicts'] is List ? data['conflicts'] : const []);
      }
      rethrow;
    }
  }

  Future<void> deleteAssignment(String siteId, String assignmentId) async {
    await _dio.delete('/site/$siteId/work-assignment/$assignmentId');
  }

  Future<PebMarkStatus> getDprMarkStatus(
    String siteId,
    PebExecutionType type, {
    String? teamId,
    String? date,
  }) async {
    final params = {
      'type': type.apiType,
      'section': type.section,
      if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
      if (date != null && date.isNotEmpty) 'endDate': date,
    };
    final response =
        await _dio.get('/site/$siteId/dpr-peb', queryParameters: params);
    final completedByKey = <String, Set<String>>{};
    final inProgressByKey = <String, Set<String>>{};
    final latest = <String, Map<String, dynamic>>{};

    for (final dpr in _asList(response.data).whereType<Map>()) {
      final time = DateTime.tryParse(
            (dpr['updatedAt'] ?? dpr['createdAt'] ?? dpr['date'] ?? '')
                .toString(),
          )?.millisecondsSinceEpoch ??
          0;
      for (final rawItem in (dpr['items'] as List? ?? []).whereType<Map>()) {
        final setupItemId = rawItem['setupItemId'] is Map
            ? rawItem['setupItemId']['_id']?.toString() ?? ''
            : rawItem['setupItemId']?.toString() ?? '';
        if (setupItemId.isEmpty) continue;
        final assignmentId = rawItem['assignmentId'] is Map
            ? rawItem['assignmentId']['_id']?.toString() ?? ''
            : rawItem['assignmentId']?.toString() ?? '';
        final key = assignmentId.isNotEmpty
            ? '$assignmentId:$setupItemId'
            : setupItemId;
        final isComplete = rawItem['isCompleted'] == true ||
            ((rawItem['progressPercentage'] as num?)?.toDouble() ?? 0) >= 100;
        final hasProgress = isComplete ||
            ((rawItem['progressPercentage'] as num?)?.toDouble() ?? 0) > 0 ||
            ((rawItem['actualQty'] as num?)?.toDouble() ?? 0) > 0;
        if (!hasProgress) continue;
        final marks = rawItem['assemblyMark']
            .toString()
            .split(',')
            .map((mark) => mark.trim())
            .where((mark) => mark.isNotEmpty);
        for (final mark in marks) {
          void recordLatest(String statusKey) {
            final latestKey = '$statusKey::$mark';
            if ((latest[latestKey]?['time'] as int? ?? -1) <= time) {
              latest[latestKey] = {
                'key': statusKey,
                'mark': mark,
                'status': isComplete ? 'completed' : 'in_progress',
                'time': time,
              };
            }
          }

          recordLatest(key);
          recordLatest(setupItemId);
        }
      }
    }

    for (final value in latest.values) {
      final key = value['key'] as String;
      final mark = value['mark'] as String;
      final status = value['status'] as String;
      if (status == 'completed') {
        completedByKey.putIfAbsent(key, () => <String>{}).add(mark);
      } else {
        inProgressByKey.putIfAbsent(key, () => <String>{}).add(mark);
      }
    }

    inProgressByKey.forEach((key, marks) {
      marks.removeWhere((mark) => completedByKey[key]?.contains(mark) == true);
    });

    return PebMarkStatus(
      completedByKey: completedByKey,
      inProgressByKey: inProgressByKey,
    );
  }

  Future<void> submitDprProgress(
    String siteId,
    PebExecutionType type, {
    required String date,
    required String teamId,
    required String setupItemId,
    required String assignmentId,
    required String sourceType,
    required String stageName,
    required String uom,
    required List<String> marks,
    required double actualQty,
    required double targetQty,
    required int progressPercentage,
    String trackingLevel = 'advanced',
  }) async {
    await _dio.post(
      '/site/$siteId/dpr-peb',
      data: {
        'date': date,
        'section': type.section,
        'type': type.apiType,
        'teamId': teamId,
        'trackingLevel': trackingLevel,
        'assemblyMark':
            type == PebExecutionType.fabrication ? marks.join(',') : '',
        'boqIds': const [],
        'status': 'submitted',
        'remarks': '',
        'items': [
          {
            'setupItemId': setupItemId,
            'assignmentId': assignmentId,
            'sourceType': sourceType,
            'name': stageName,
            'uom': uom,
            'actualQty': actualQty,
            'targetQty': targetQty,
            'progressPercentage': progressPercentage,
            'isCompleted': progressPercentage >= 100,
            'completedDate': progressPercentage >= 100 ? date : null,
            'assemblyMark': marks.join(','),
            'trackingLevel': trackingLevel,
            'memberType': stageName,
            'weightMode': 'none',
            'estimatedWeightPerUnitKg': 0,
            'manualWeightKg': 0,
            'totalWeightKg': 0,
            'remarks': '',
            'manpower': 0,
            'assignedManpower': const [],
            'manualManpower': const [],
            'contractor': '',
            'area': '',
          }
        ],
      },
    );
  }
}
