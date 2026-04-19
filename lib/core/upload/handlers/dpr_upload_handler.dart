import '../../../features/modules/all_Modules/dpr/providers/dprService.dart';
import '../../../features/modules/all_Modules/dpr/providers/service/rate_upload_material_dpr.dart';
import '../models/upload_job.dart';
import 'upload_handler.dart';

class DprUploadHandler implements UploadHandler {
  @override
  String get moduleId => 'dpr';

  @override
  Future<Map<String, dynamic>> execute({
    required UploadJob job,
    required ProgressCallback onProgress,
  }) async {
    final metadata = job.metadata;

    final siteId = (metadata['siteId'] ?? '').toString().trim();
    final teamId = (metadata['teamId'] ?? '').toString().trim();
    final mechanicalId = (metadata['mechanicalId'] ?? '').toString().trim();

    final rawUpdate = metadata['updateData'];
    if (rawUpdate is! Map) {
      throw Exception('metadata.updateData is required for DPR upload');
    }

    final updateData = Map<String, dynamic>.from(rawUpdate);

    onProgress(0.05, 'Preparing DPR payload...');

    if (siteId.isEmpty) {
      throw Exception('metadata.siteId is required for DPR upload');
    }
    if (teamId.isEmpty) {
      throw Exception('metadata.teamId is required for DPR upload');
    }

    if (mechanicalId.isEmpty) {
      onProgress(0.4, 'Creating DPR...');
      final response = await RateUploadApi.createDprMechanicalV2(
        siteId: siteId,
        teamId: teamId,
        data: updateData,
      );

      onProgress(1.0, 'DPR created');
      return {
        'success': true,
        'mode': 'create',
        'statusCode': response.statusCode,
        'data': response.data,
      };
    }

    onProgress(0.4, 'Updating DPR...');
    await DprApi.updateDprWork(
      data: updateData,
      mechanicalId: mechanicalId,
    );

    onProgress(1.0, 'DPR updated');
    return {
      'success': true,
      'mode': 'update',
      'mechanicalId': mechanicalId,
    };
  }
}
