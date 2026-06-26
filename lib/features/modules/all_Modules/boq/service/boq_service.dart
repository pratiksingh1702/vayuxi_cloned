import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../models/boq_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BOQ API SERVICE
// Uses DioClient.dio from your existing setup (base URL already set)
// ─────────────────────────────────────────────────────────────────────────────

class BoqApiService {
  final Dio _dio;

  BoqApiService(this._dio);

  // ── List BOQs ─────────────────────────────────────────────────────────────

  Future<({List<BoqListItem> boqs, BoqPagination pagination})> getBoqs({
    required String siteId,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    };

    final resp = await _dio.get(
      '/site/$siteId/boq',
      queryParameters: queryParams,
    );

    final data = resp.data['data'] as Map<String, dynamic>;
    final rawBoqs = data['boqs'] as List<dynamic>;

    return (
      boqs: rawBoqs
          .map((e) => BoqListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          BoqPagination.fromJson(data['pagination'] as Map<String, dynamic>),
    );
  }

  // ── Get BOQ Detail ────────────────────────────────────────────────────────

  Future<BoqDetail> getBoqDetail({
    required String siteId,
    required String boqId,
  }) async {
    final resp = await _dio.get('/site/$siteId/boq/$boqId');
    return BoqDetail.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  Future<List<BoqDetail>> getMechanicalPipingBoqs({
    required String siteId,
  }) async {
    final resp = await _dio.get('/site/$siteId/boq/mechanical-piping');
    final raw = resp.data['data'];
    final list = raw is List
        ? raw
        : raw is Map<String, dynamic> && raw['boqs'] is List
            ? raw['boqs'] as List
            : const [];
    return list
        .map((e) => BoqDetail.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Get BOQ Progress ──────────────────────────────────────────────────────

  Future<BoqProgress> getBoqProgress({
    required String siteId,
    required String boqId,
  }) async {
    final resp = await _dio.get('/site/$siteId/boq/$boqId/progress');
    return BoqProgress.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  // ── Upload Excel BOQ ──────────────────────────────────────────────────────
  //
  // API (Phase 3, endpoint 16): timeline is sent as a JSON *string* in
  // multipart/form-data, e.g.:
  //   timeline={"startDate":"2026-03-20","endDate":"2026-04-20",...}
  //
  // Pass [timelineJsonString] from _TimelineState.toApiJsonString().

  Future<({BoqListItem boq, BoqUploadSummary? summary})> uploadBoqExcel({
    required String siteId,
    required PlatformFile file,
    required String type,
    String? boqName,
    String? timelineJsonString, // ← JSON string, not Map
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      ),
      'type': type,
      if (boqName != null) 'boqName': boqName,
      // API expects: timeline={"startDate":...} as a raw JSON string field
      if (timelineJsonString != null) 'timeline': timelineJsonString,
    });

    final resp = await _dio.post(
      '/site/$siteId/boq/upload',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );

    final data = resp.data['data'] as Map<String, dynamic>;
    final summaryJson = resp.data['summary'] as Map<String, dynamic>?;

    return (
      boq: BoqListItem.fromJson(data),
      summary:
          summaryJson != null ? BoqUploadSummary.fromJson(summaryJson) : null,
    );
  }

  // ── Create Manual Mechanical BOQ ──────────────────────────────────────────
  //
  // API (Phase 3, endpoint 15): timeline sent as a JSON *object* in the body.
  // Pass [timeline] from _TimelineState.toApiPayload().

  Future<BoqListItem> createManualMechanicalBoq({
    required String siteId,
    required String boqName,
    List<Map<String, dynamic>>? items,
    double? directTotalInchDia,
    double? directTotalInchMtr,
    Map<String, dynamic>? timeline, // ← plain Map, serialised by Dio
  }) async {
    final body = <String, dynamic>{
      'boqName': boqName,
      'type': 'mechanical_work',
      if (items != null) 'items': items,
      if (directTotalInchDia != null) 'directTotalInchDia': directTotalInchDia,
      if (directTotalInchMtr != null) 'directTotalInchMtr': directTotalInchMtr,
      if (timeline != null) 'timeline': timeline,
    };

    final resp = await _dio.post('/site/$siteId/boq/manual', data: body);
    return BoqListItem.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  // ── Create Manual Insulation BOQ ──────────────────────────────────────────

  Future<BoqListItem> createManualInsulationBoq({
    required String siteId,
    required String boqName,
    List<Map<String, dynamic>>? items,
    double? directTotalRMT,
    double? directTotalArea,
    Map<String, dynamic>? timeline,
  }) async {
    final body = <String, dynamic>{
      'boqName': boqName,
      'type': 'insulation_piping',
      if (items != null) 'items': items,
      if (directTotalRMT != null) 'directTotalRMT': directTotalRMT,
      if (directTotalArea != null) 'directTotalArea': directTotalArea,
      if (timeline != null) 'timeline': timeline,
    };

    final resp = await _dio.post('/site/$siteId/boq/manual', data: body);
    return BoqListItem.fromJson(resp.data['data'] as Map<String, dynamic>);
  }

  // ── Update BOQ (name / status / timeline) ─────────────────────────────────
  //
  // API endpoint 14: PUT /site/:site/boq/:boqId/update
  // Accepts boqName, status, and/or timeline as JSON object.

  Future<void> updateBoq({
    required String siteId,
    required String boqId,
    String? boqName,
    String? status,
    Map<String, dynamic>? timeline,
  }) async {
    final body = <String, dynamic>{
      if (boqName != null) 'boqName': boqName,
      if (status != null) 'status': status,
      if (timeline != null) 'timeline': timeline,
    };
    await _dio.put('/site/$siteId/boq/$boqId/update', data: body);
  }

  // ── Update BOQ Status ─────────────────────────────────────────────────────

  Future<void> updateBoqStatus({
    required String siteId,
    required String boqId,
    required String status,
  }) async {
    await _dio.put('/site/$siteId/boq/$boqId/status', data: {'status': status});
  }

  // ── Delete BOQ ────────────────────────────────────────────────────────────

  Future<void> deleteBoq({
    required String siteId,
    required String boqId,
  }) async {
    await _dio.delete('/site/$siteId/boq/$boqId');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION APIs
  // ─────────────────────────────────────────────────────────────────────────

  Future<NotificationPreferences> getNotificationPreferences() async {
    final resp = await _dio.get('/notifications/preferences');
    return NotificationPreferences.fromJson(
        resp.data['data'] as Map<String, dynamic>);
  }

  Future<NotificationPreferences> updateNotificationPreferences({
    required Map<String, dynamic> globalSettings,
  }) async {
    final resp = await _dio.put(
      '/notifications/preferences',
      data: {'globalSettings': globalSettings},
    );
    return NotificationPreferences.fromJson(
        resp.data['data'] as Map<String, dynamic>);
  }

  Future<NotificationPreferences> resetNotificationPreferences() async {
    final resp = await _dio.delete('/notifications/preferences');
    return NotificationPreferences.fromJson(
        resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> updateSiteNotificationPreferences({
    required String siteId,
    required Map<String, dynamic> preferences,
  }) async {
    await _dio.put('/notifications/sites/$siteId', data: preferences);
  }

  Future<List<NotificationHistoryItem>> getNotificationHistory({
    int limit = 50,
    String? siteId,
    String? boqId,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (siteId != null) 'siteId': siteId,
      if (boqId != null) 'boqId': boqId,
    };
    final resp = await _dio.get(
      '/notifications/history',
      queryParameters: queryParams,
    );
    final rawList = resp.data['data'] as List<dynamic>;
    return rawList
        .map((e) => NotificationHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationStats> getNotificationStats({int days = 30}) async {
    final resp = await _dio.get(
      '/notifications/stats',
      queryParameters: {'days': days},
    );
    return NotificationStats.fromJson(
        resp.data['data'] as Map<String, dynamic>);
  }

  Future<void> sendTestNotification({String? date}) async {
    await _dio.post(
      '/notifications/test',
      data: date != null ? {'date': date} : null,
    );
  }
}
