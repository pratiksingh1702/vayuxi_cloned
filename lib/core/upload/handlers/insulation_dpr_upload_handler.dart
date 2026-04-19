import '../models/upload_job.dart';
import 'upload_handler.dart';
import '../../../features/modules/all_Modules/dpr/dpr_insu/service/insulation_dpr_service.dart';

class InsulationDprUploadHandler implements UploadHandler {
  @override
  String get moduleId => 'dpr_insu';

  @override
  Future<Map<String, dynamic>> execute({
    required UploadJob job,
    required ProgressCallback onProgress,
  }) async {
    onProgress(0.05, 'Preparing insulation DPR payload...');

    final metadata = job.metadata;
    final payload = Map<String, dynamic>.from(metadata['updateData'] ?? {});

    if (payload.isEmpty) {
      throw Exception('Missing insulation DPR payload in upload metadata.');
    }

    final insulationId = metadata['insulationId']?.toString();
    final siteId = metadata['siteId']?.toString() ?? '';
    final teamId = metadata['teamId']?.toString() ?? '';

    onProgress(0.6, 'Submitting insulation DPR to server...');

    if (insulationId == null || insulationId.isEmpty) {
      if (siteId.isEmpty || teamId.isEmpty) {
        throw Exception('Missing siteId/teamId for insulation DPR create API.');
      }
      final response = await InsulationDprApi.createInsulationDpr(
        data: payload,
        siteId: siteId,
        teamId: teamId,
      );
      onProgress(1.0, 'Finalizing upload...');
      return {
        'mode': 'create',
        'insulationId': response?.id,
        'response': response?.toJson(),
      };
    }

    final response = await InsulationDprApi.updateInsulationDpr(
      dprId: insulationId,
      data: payload,
    );

    onProgress(1.0, 'Finalizing upload...');
    return {
      'mode': 'update',
      'insulationId': insulationId,
      'response': response?.toJson(),
    };
  }
}
