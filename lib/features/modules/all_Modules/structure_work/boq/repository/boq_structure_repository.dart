import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/api/dio.dart';
import '../models/boq_structure_model.dart';

class BOQStructureRepository {
  // GET /api/v1/site/{siteId}/boq-structure
  Future<List<BOQStructure>> getAllBOQs(String siteId) async {
    final res = await DioClient.dio.get('/site/$siteId/boq-structure');
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((e) => BOQStructure.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // GET /api/v1/site/{siteId}/boq-structure/{boqId}
  Future<BOQStructure> getBOQDetail(String siteId, String boqId) async {
    final res = await DioClient.dio.get('/site/$siteId/boq-structure/$boqId');
    return BOQStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // GET /api/v1/site/{siteId}/boq-structure/{boqId}/items
  Future<BOQStructure> getBOQItems(String siteId, String boqId) async {
    final res =
        await DioClient.dio.get('/site/$siteId/boq-structure/$boqId/items');
    return BOQStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  // POST /api/v1/site/{siteId}/boq-structure/upload (multipart)
  Future<BOQStructure> uploadBOQExcel(String siteId, PlatformFile file,
      {String workType = 'fabrication'}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
        contentType: DioMediaType('application',
            'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ),
      'workType': workType,
    });

    final res = await DioClient.dio.post(
      '/site/$siteId/boq-structure/upload',
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
    return BOQStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<BOQStructure> createManualBOQ(
    String siteId, {
    required String boqName,
    String type = 'structure_work',
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await DioClient.dio.post(
      '/site/$siteId/boq-structure',
      data: {
        'boqName': boqName,
        'type': type,
        'items': items,
      },
    );

    return BOQStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<BOQStructure> updateBOQItem(
    String siteId,
    String boqId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final res = await DioClient.dio.put(
      '/site/$siteId/boq-structure/$boqId/items/$itemId',
      data: data,
    );

    return BOQStructure.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteBOQItem(
    String siteId,
    String boqId,
    String itemId,
  ) async {
    await DioClient.dio.delete(
      '/site/$siteId/boq-structure/$boqId/items/$itemId',
    );
  }
}
