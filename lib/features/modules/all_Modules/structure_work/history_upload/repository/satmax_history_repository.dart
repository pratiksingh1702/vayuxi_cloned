import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:untitled2/core/api/dio.dart';

class SatmaxHistoryUploadResult {
  final int importedRows;
  final int skippedRows;
  final int hiddenRowsIncluded;
  final num totalQuantity;
  final num totalNetWeightMT;

  const SatmaxHistoryUploadResult({
    required this.importedRows,
    required this.skippedRows,
    required this.hiddenRowsIncluded,
    required this.totalQuantity,
    required this.totalNetWeightMT,
  });

  factory SatmaxHistoryUploadResult.fromJson(Map<String, dynamic> json) {
    return SatmaxHistoryUploadResult(
      importedRows: _asInt(json['importedRows']),
      skippedRows: _asInt(json['skippedRows']),
      hiddenRowsIncluded: _asInt(json['hiddenRowsIncluded']),
      totalQuantity: _asNum(json['totalQuantity']),
      totalNetWeightMT: _asNum(json['totalNetWeightMT']),
    );
  }
}

class SatmaxHistoryRecord {
  final String id;
  final String fileName;
  final int importedRows;
  final int skippedRows;
  final int hiddenRowsIncluded;
  final num totalQuantity;
  final num totalNetWeightMT;
  final DateTime? uploadedAt;

  const SatmaxHistoryRecord({
    required this.id,
    required this.fileName,
    required this.importedRows,
    required this.skippedRows,
    required this.hiddenRowsIncluded,
    required this.totalQuantity,
    required this.totalNetWeightMT,
    this.uploadedAt,
  });

  factory SatmaxHistoryRecord.fromJson(Map<String, dynamic> json) {
    return SatmaxHistoryRecord(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fileName: (json['fileName'] ?? 'History Upload').toString(),
      importedRows: _asInt(json['importedRows']),
      skippedRows: _asInt(json['skippedRows']),
      hiddenRowsIncluded: _asInt(json['hiddenRowsIncluded']),
      totalQuantity: _asNum(json['totalQuantity']),
      totalNetWeightMT: _asNum(json['totalNetWeightMT']),
      uploadedAt: DateTime.tryParse((json['uploadedAt'] ?? '').toString()),
    );
  }
}

class SatmaxHistoryRepository {
  Future<List<SatmaxHistoryRecord>> getHistory(String siteId) async {
    final res = await DioClient.dio.get(
      '/site/$siteId/boq-structure/satmax-main-frame-history',
    );
    final data = res.data['data'];
    if (data is List) {
      return data
          .map((item) =>
              SatmaxHistoryRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SatmaxHistoryUploadResult> uploadHistory(
    String siteId,
    PlatformFile file,
  ) async {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception(
          'Selected file is empty. Please choose the Excel file again.');
    }

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.name,
        contentType: DioMediaType(
          'application',
          'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ),
    });

    final res = await DioClient.dio.post(
      '/site/$siteId/boq-structure/satmax-main-frame-history',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return SatmaxHistoryUploadResult.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}
