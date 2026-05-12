import 'package:untitled2/core/api/dio.dart';
import '../models/structure_pm_entry_model.dart';

class StructurePmRepository {
  Future<StructurePmEntryData> getEntry(
    String siteId, {
    required String date,
  }) async {
    final res = await DioClient.dio.get(
      '/site/$siteId/structure-work/pm-entry',
      queryParameters: {'date': date},
    );

    return StructurePmEntryData.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<bool> saveEntry(
    String siteId, {
    required String date,
    required List<StructurePmResourceRow> rows,
  }) async {
    final entries = rows
        .where((row) => row.actualQty > 0 || row.remarks.trim().isNotEmpty)
        .map((row) => {
              'resourceId': row.id,
              'actualQty': row.actualQty,
              'remarks': row.remarks.trim(),
            })
        .toList();

    final res = await DioClient.dio.post(
      '/site/$siteId/structure-work/pm-entry',
      data: {
        'date': date,
        'entries': entries,
      },
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }
}
