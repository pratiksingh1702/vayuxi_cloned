import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final Dio _dio = Dio();

  /// Returns local file path
  static Future<String> cacheImage({
    required String url,
    required String fileName,
  }) async {
    final dir = await _imageDir();
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      return file.path; // ✅ already cached
    }

    try {
      final encodedUrl = Uri.encodeFull(url);
      await _dio.download(encodedUrl, file.path);
    } catch (e) {
      debugPrint("Image download failed: $url");
    }


    return file.path;
  }

  static Future<Directory> _imageDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/material_images');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir;
  }
}
