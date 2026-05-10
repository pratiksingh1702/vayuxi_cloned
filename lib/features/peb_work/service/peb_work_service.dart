import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/peb_dpr_model.dart';

class PebWorkService {
  final Dio _dio = DioClient.dio;

  // DPR Setup
  Future<List<PebDprSetup>> getDprSetups(String siteId, {String? workType, String? section}) async {
    final res = await _dio.get('/site/$siteId/peb-dpr-setup', queryParameters: {
      if (workType != null) 'workType': workType,
      if (section != null) 'section': section,
    });
    return (res.data as List).map((e) => PebDprSetup.fromJson(e)).toList();
  }

  Future<PebDprSetup> createDprSetup(String siteId, PebDprSetup setup) async {
    final res = await _dio.post('/site/$siteId/peb-dpr-setup', data: setup.toJson());
    return PebDprSetup.fromJson(res.data);
  }

  Future<void> updateDprSetup(String siteId, String setupId, Map<String, dynamic> data) async {
    await _dio.put('/site/$siteId/peb-dpr-setup/$setupId', data: data);
  }

  Future<void> deleteDprSetup(String siteId, String setupId) async {
    await _dio.delete('/site/$siteId/peb-dpr-setup/$setupId');
  }

  // DPR Entry
  Future<List<PebDprEntry>> getDprEntries(String siteId, {String? workType, String? date, String? section}) async {
    final res = await _dio.get('/site/$siteId/dpr-peb', queryParameters: {
      if (workType != null) 'workType': workType,
      if (date != null) 'date': date,
      if (section != null) 'section': section,
    });
    return (res.data as List).map((e) => PebDprEntry.fromJson(e)).toList();
  }

  Future<PebDprEntry> createDprEntry(String siteId, PebDprEntry entry) async {
    final res = await _dio.post('/site/$siteId/dpr-peb', data: entry.toJson());
    return PebDprEntry.fromJson(res.data);
  }

  Future<void> updateDprEntry(String siteId, String dprId, Map<String, dynamic> data) async {
    await _dio.put('/site/$siteId/dpr-peb/$dprId', data: data);
  }

  Future<void> deleteDprEntry(String siteId, String dprId) async {
    await _dio.delete('/site/$siteId/dpr-peb/$dprId');
  }
}
