import 'package:dio/dio.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/quotation_model.dart';

class QuotationService {
  final Dio _dio = DioClient.dio;

  Future<List<QuotationModel>> getQuotations({String? leadId, String? status}) async {
    final res = await _dio.get('/quotations', queryParameters: {
      if (leadId != null) 'leadId': leadId,
      if (status != null) 'status': status,
    });
    return (res.data as List).map((e) => QuotationModel.fromJson(e)).toList();
  }

  Future<QuotationModel> createQuotation(QuotationModel quotation) async {
    final res = await _dio.post('/quotations', data: quotation.toJson());
    return QuotationModel.fromJson(res.data);
  }

  Future<QuotationModel> getQuotationById(String id) async {
    final res = await _dio.get('/quotations/$id');
    return QuotationModel.fromJson(res.data);
  }

  Future<void> updateQuotationStatus(String id, String status) async {
    await _dio.patch('/quotations/$id/status', data: {'status': status});
  }

  Future<QuotationModel> reviseQuotation(String id, Map<String, dynamic> revisionData) async {
    final res = await _dio.post('/quotations/$id/revise', data: revisionData);
    return QuotationModel.fromJson(res.data);
  }

  Future<String> generatePdf(String id) async {
    final res = await _dio.get('/quotations/$id/pdf');
    return res.data['pdfUrl'];
  }
}
