import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import '../local/cache_image_dao.dart';


class ImageCacheService {
  static final Dio _dio = Dio();
  static final CachedImageDao _dao = CachedImageDao();

  /// Returns local file path — checks Isar cache first, downloads only if missing
  static Future<String> cacheImage({
    required String url,
    required String fileName,
  }) async {
    // 🔥 STEP 1: Check Isar for existing mapping
    final existing = await _dao.getLocalPath(url);
    if (existing != null && await File(existing).exists()) {
      return existing; // ✅ already downloaded, reuse across all sites
    }

    // 🔥 STEP 2: Download fresh
    final dir = await _imageDir();
    final file = File('${dir.path}/$fileName');

    try {
      if (!await file.exists()) {
        final encodedUrl = Uri.encodeFull(url);
        await _dio.download(encodedUrl, file.path);
      }
    } catch (e) {
      debugPrint("Image download failed: $url → $e");
    }

    // 🔥 STEP 3: Persist mapping to Isar
    await _dao.save(serverUrl: url, localPath: file.path);

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
