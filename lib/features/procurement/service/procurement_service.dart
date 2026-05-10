import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/procurement_model.dart';

class ProcurementService {
  final Dio _dio = DioClient.dio;

  // Material Requests
  Future<List<ProcurementRequest>> getRequests(String siteId, {String? workType, String? status}) async {
    final res = await _dio.get('/site/$siteId/procurement/requests', queryParameters: {
      if (workType != null) 'workType': workType,
      if (status != null) 'status': status,
    });
    return (res.data as List).map((e) => ProcurementRequest.fromJson(e)).toList();
  }

  Future<ProcurementRequest> createRequest(String siteId, ProcurementRequest request) async {
    final res = await _dio.post('/site/$siteId/procurement/requests', data: request.toJson());
    return ProcurementRequest.fromJson(res.data);
  }

  Future<void> approveRequest(String siteId, String requestId, String comments) async {
    await _dio.post('/site/$siteId/procurement/requests/$requestId/approve', data: {'comments': comments});
  }

  // Vendors
  Future<List<Vendor>> getVendors(String siteId, {String? workType, String? material}) async {
    final res = await _dio.get('/site/$siteId/procurement/vendors', queryParameters: {
      if (workType != null) 'workType': workType,
      if (material != null) 'material': material,
    });
    return (res.data as List).map((e) => Vendor.fromJson(e)).toList();
  }

  Future<Vendor> createVendor(String siteId, Vendor vendor) async {
    final res = await _dio.post('/site/$siteId/procurement/vendors', data: vendor.toJson());
    return Vendor.fromJson(res.data);
  }

  // Purchase Orders
  Future<List<PurchaseOrder>> getPurchaseOrders(String siteId, {String? workType, String? vendorId, String? status}) async {
    final res = await _dio.get('/site/$siteId/procurement/purchase-orders', queryParameters: {
      if (workType != null) 'workType': workType,
      if (vendorId != null) 'vendorId': vendorId,
      if (status != null) 'status': status,
    });
    return (res.data as List).map((e) => PurchaseOrder.fromJson(e)).toList();
  }

  Future<PurchaseOrder> createPurchaseOrder(String siteId, PurchaseOrder po) async {
    final res = await _dio.post('/site/$siteId/procurement/purchase-orders', data: po.toJson());
    return PurchaseOrder.fromJson(res.data);
  }

  Future<void> approvePurchaseOrder(String siteId, String poId, String comments) async {
    await _dio.post('/site/$siteId/procurement/purchase-orders/$poId/approve', data: {'comments': comments});
  }
}
