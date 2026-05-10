import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/dispatch_model.dart';

class DispatchService {
  final Dio _dio = DioClient.dio;

  Future<List<DispatchModel>> getDispatches(String siteId, {String? workType, String? deliveryStatus}) async {
    final res = await _dio.get('/site/$siteId/peb-dispatch', queryParameters: {
      if (workType != null) 'workType': workType,
      if (deliveryStatus != null) 'deliveryStatus': deliveryStatus,
    });
    return (res.data as List).map((e) => DispatchModel.fromJson(e)).toList();
  }

  Future<DispatchModel> createDispatch(String siteId, DispatchModel dispatch) async {
    final res = await _dio.post('/site/$siteId/peb-dispatch', data: dispatch.toJson());
    return DispatchModel.fromJson(res.data);
  }

  Future<void> updateDispatch(String siteId, String dispatchId, Map<String, dynamic> data) async {
    await _dio.put('/site/$siteId/peb-dispatch/$dispatchId', data: data);
  }

  Future<void> deleteDispatch(String siteId, String dispatchId) async {
    await _dio.delete('/site/$siteId/peb-dispatch/$dispatchId');
  }
}

class HandoverService {
  final Dio _dio = DioClient.dio;

  Future<List<HandoverModel>> getHandovers(String siteId, {String? workType, String? status}) async {
    final res = await _dio.get('/site/$siteId/peb-handover', queryParameters: {
      if (workType != null) 'workType': workType,
      if (status != null) 'status': status,
    });
    return (res.data as List).map((e) => HandoverModel.fromJson(e)).toList();
  }

  Future<HandoverModel> createHandover(String siteId, HandoverModel handover) async {
    final res = await _dio.post('/site/$siteId/peb-handover', data: handover.toJson());
    return HandoverModel.fromJson(res.data);
  }

  Future<void> updateHandover(String siteId, String handoverId, Map<String, dynamic> data) async {
    await _dio.put('/site/$siteId/peb-handover/$handoverId', data: data);
  }

  Future<void> approveHandover(String siteId, String handoverId, String workType) async {
    await _dio.post('/site/$siteId/peb-handover/approve', data: {
      'handoverId': handoverId,
      'workType': workType,
    });
  }
}
