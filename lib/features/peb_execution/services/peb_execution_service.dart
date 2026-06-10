import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/peb_execution_models.dart';

class PebExecutionConflict implements Exception {
  final List<dynamic> conflicts;

  PebExecutionConflict(this.conflicts);
}

class PebBoqVariationRequired implements Exception {
  final List<dynamic> variations;

  PebBoqVariationRequired(this.variations);
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
    List<String>? images,
    bool imageUserSpecific = false,
  }) async {
    final payload = {
      'name': name,
      'uom': uom,
      'remarks': remarks,
      'targetQty': targetQty,
      if (images != null) 'image': images,
      if (imageUserSpecific) 'imageUserSpecific': true,
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

  Future<List<String>> uploadSetupImages(
    String siteId,
    List<PlatformFile> files,
  ) async {
    final multipartFiles = <MultipartFile>[];
    for (final file in files) {
      final path = file.path;
      final bytes = file.bytes;
      if (path != null && path.isNotEmpty) {
        multipartFiles.add(
          await MultipartFile.fromFile(path, filename: file.name),
        );
      } else if (bytes != null && bytes.isNotEmpty) {
        multipartFiles.add(
          MultipartFile.fromBytes(bytes, filename: file.name),
        );
      }
    }
    if (multipartFiles.isEmpty) return const [];

    final response = await _dio.post(
      '/site/$siteId/peb-setup/upload-image',
      data: FormData.fromMap({'file': multipartFiles}),
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    final data = response.data is Map ? response.data as Map : const {};
    return (data['urls'] as List? ?? [])
        .map((url) => url.toString())
        .where((url) => url.trim().isNotEmpty)
        .toList();
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
    String quantityType = 'exact',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path!, filename: file.name),
    });
    final query = <String, dynamic>{'quantityType': quantityType};
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

  Future<void> updateBoqItem(
    String siteId,
    String boqId,
    String itemId, {
    required Map<String, dynamic> item,
  }) async {
    await _dio.put(
      '/site/$siteId/boq-structure/$boqId/items/$itemId',
      data: item,
    );
  }

  Future<void> deleteBoqItem(
    String siteId,
    String boqId,
    String itemId,
  ) async {
    await _dio.delete('/site/$siteId/boq-structure/$boqId/items/$itemId');
  }

  Future<void> updateBoq(
    String siteId,
    String boqId,
    PebExecutionType type, {
    required String boqName,
    required List<Map<String, dynamic>> items,
    String quantityType = 'exact',
  }) async {
    await _dio.put('/site/$siteId/boq-structure/$boqId', data: {
      'boqName': boqName,
      'type': type.apiType,
      'quantityType': quantityType,
      'items': items,
    });
  }

  Future<void> createManualBoq(
    String siteId,
    PebExecutionType type, {
    required String boqName,
    required List<Map<String, dynamic>> items,
    String quantityType = 'exact',
  }) async {
    await _dio.post('/site/$siteId/boq-structure', data: {
      'boqName': boqName,
      'type': type.apiType,
      'quantityType': quantityType,
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
      if (teamId.trim().isNotEmpty) 'teamId': teamId,
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
    };
    final results = await Future.wait([
      _dio.get('/site/$siteId/dpr-peb', queryParameters: params),
      getAssignments(siteId, type, status: 'all'),
    ]);
    final response = results[0] as Response<dynamic>;
    final assignments = results[1] as List<PebWorkAssignment>;
    final validAssignmentIds = assignments
        .where((assignment) => assignment.status != 'cancelled')
        .map((assignment) => assignment.id)
        .toSet();
    final completedByKey = <String, Set<String>>{};
    final inProgressByKey = <String, Set<String>>{};
    final completedDateByKey = <String, Map<String, DateTime>>{};
    final latest = <String, Map<String, dynamic>>{};

    for (final dpr in _asList(response.data).whereType<Map>()) {
      final dprDate = DateTime.tryParse((dpr['date'] ?? '').toString());
      for (final rawItem in (dpr['items'] as List? ?? []).whereType<Map>()) {
        final setupItemId = rawItem['setupItemId'] is Map
            ? rawItem['setupItemId']['_id']?.toString() ?? ''
            : rawItem['setupItemId']?.toString() ?? '';
        if (setupItemId.isEmpty) continue;
        final assignmentId = rawItem['assignmentId'] is Map
            ? rawItem['assignmentId']['_id']?.toString() ?? ''
            : rawItem['assignmentId']?.toString() ?? '';
        if (assignmentId.isNotEmpty &&
            !validAssignmentIds.contains(assignmentId)) {
          continue;
        }
        final key = assignmentId.isNotEmpty
            ? '$assignmentId:$setupItemId'
            : setupItemId;
        final isComplete = rawItem['isCompleted'] == true ||
            ((rawItem['progressPercentage'] as num?)?.toDouble() ?? 0) >= 100;
        final hasProgress = isComplete ||
            ((rawItem['progressPercentage'] as num?)?.toDouble() ?? 0) > 0 ||
            ((rawItem['actualQty'] as num?)?.toDouble() ?? 0) > 0;
        if (!hasProgress) continue;
        final completedDate = DateTime.tryParse(
              (rawItem['completedDate'] ?? '').toString(),
            ) ??
            dprDate;
        final time =
            (isComplete ? completedDate : dprDate)?.millisecondsSinceEpoch ?? 0;
        final marks = rawItem['assemblyMark']
            .toString()
            .split(',')
            .map((mark) => mark.trim())
            .where((mark) => mark.isNotEmpty);
        for (final mark in marks) {
          void recordLatest(String statusKey) {
            final latestKey = '$statusKey::$mark';
            final existing = latest[latestKey];
            final existingCompleted = existing?['status'] == 'completed';
            if (existingCompleted && !isComplete) return;
            if (existing == null ||
                isComplete && !existingCompleted ||
                (existing['time'] as int? ?? -1) <= time) {
              latest[latestKey] = {
                'key': statusKey,
                'mark': mark,
                'status': isComplete ? 'completed' : 'in_progress',
                'time': time,
                'completedDate': isComplete ? completedDate : null,
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
        final completedDate = value['completedDate'] as DateTime?;
        if (completedDate != null) {
          completedDateByKey.putIfAbsent(
              key, () => <String, DateTime>{})[mark] = completedDate;
        }
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
      completedDateByKey: completedDateByKey,
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
    String remarks = '',
    String variationReason = '',
    String variationRemarks = '',
    String weightMode = 'none',
    double estimatedWeightPerUnitKg = 0,
    double manualWeightKg = 0,
    double totalWeightKg = 0,
  }) async {
    try {
      await _dio.post(
        '/site/$siteId/dpr-peb',
        data: {
          'date': date,
          'section': type.section,
          'type': type.apiType,
          if (teamId.trim().isNotEmpty) 'teamId': teamId,
          'trackingLevel': trackingLevel,
          'assemblyMark':
              type == PebExecutionType.fabrication ? marks.join(',') : '',
          'boqIds': const [],
          'status': 'submitted',
          'remarks': remarks.trim(),
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
              'weightMode': weightMode,
              'estimatedWeightPerUnitKg': estimatedWeightPerUnitKg,
              'manualWeightKg': manualWeightKg,
              'totalWeightKg': totalWeightKg,
              'remarks': remarks.trim(),
              'manpower': 0,
              'assignedManpower': const [],
              'manualManpower': const [],
              'contractor': '',
              'area': '',
              if (variationReason.trim().isNotEmpty)
                'variationReason': variationReason.trim(),
              if (variationRemarks.trim().isNotEmpty)
                'variationRemarks': variationRemarks.trim(),
            }
          ],
        },
      );
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode == 409 &&
          data is Map &&
          data['code'] == 'BOQ_VARIATION_REQUIRED') {
        throw PebBoqVariationRequired(
          data['variations'] is List ? data['variations'] : const [],
        );
      }
      rethrow;
    }
  }
}
