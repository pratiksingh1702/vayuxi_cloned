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
    debugPrint("📥 Incoming URL to cache: $url");

    try {
      // Check Isar for existing mapping
      final existing = await _dao.getLocalPath(url);
      if (existing != null) {
        final file = File(existing);
        if (await file.exists()) {
          debugPrint("✅ Using cached image: $existing");
          return existing;
        } else {
          debugPrint("⚠️ Cached path exists but file missing: $existing");
          // Remove stale cache entry
          await _dao.delete(url);
        }
      }

      // Download fresh
      final dir = await _imageDir();
      final file = File('${dir.path}/$fileName');

      // Ensure directory exists
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      debugPrint("🔄 Downloading: $url to ${file.path}");
      final encodedUrl = Uri.encodeFull(url);

      await _dio.download(
        encodedUrl,
        file.path,

      );

      if (await file.exists()) {
        debugPrint("✅ Downloaded successfully: ${file.path}");
        // Persist mapping
        await _dao.save(serverUrl: url, localPath: file.path);
        return file.path;
      } else {
        throw Exception("File not created after download");
      }
    } catch (e) {
      debugPrint("❌ Image cache failed for $url: $e");
      return ''; // Return empty string on failure
    }
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
