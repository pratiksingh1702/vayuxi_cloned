import 'dart:io';
import 'package:dio/dio.dart';
import '../model/ai_analyze_model.dart';

class AudioAnalyzeService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://3.108.219.253/vayuxi-ERP",
  ));

  static Future<AudioAnalysis> uploadAudio(File file) async {
    try {
      final formData = FormData.fromMap({
        "audio_file": await MultipartFile.fromFile(
          file.path,
          filename: file.path.split("/").last,
        ),
      });

      final response = await _dio.post(
        "/audio/analyze",
        data: formData,
        options: Options(
          headers: {"accept": "application/json"},
          contentType: "multipart/form-data",
        ),
      );
      print("RAW RESPONSE: ${response.data}");


      return AudioAnalysis.fromJson(response.data);
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }
}
