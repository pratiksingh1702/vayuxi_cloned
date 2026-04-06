import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/eqip_insu.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/data/local/cache_image_dao.dart';

import '../../../../../../core/api/dio.dart';

class MaterialImageUploadService {
  static final MaterialImageUploadService _instance =
      MaterialImageUploadService._internal();
  factory MaterialImageUploadService() => _instance;
  MaterialImageUploadService._internal();

  final CachedImageDao _cacheDao = CachedImageDao();

  /// materialId → latest staged File (only for NEW/UNUPLOADED images)
  final Map<String, File> _pendingImages = {};

  /// materialId → List of local paths (for tracking which local path corresponds to which URL)
  final Map<String, List<String>> _stagedImagePaths = {};

  // ─────────────────────────────────────────────
  // STAGING
  // ─────────────────────────────────────────────

  void stageImage({required String materialId, required File imageFile}) {
    _pendingImages[materialId] = imageFile;
    _stagedImagePaths.putIfAbsent(materialId, () => []).add(imageFile.path);
    debugPrint('📷 Staged image for [$materialId]: ${imageFile.path}');
  }

  void unstageImage(String materialId) {
    _pendingImages.remove(materialId);
    _stagedImagePaths.remove(materialId);
  }

  bool hasStagedImage(String materialId) => _pendingImages.containsKey(materialId);

  File? getStagedFile(String materialId) => _pendingImages[materialId];

  bool get hasPendingUploads => _pendingImages.isNotEmpty;

  int get pendingCount => _pendingImages.length;

  void clearAll() {
    _pendingImages.clear();
    _stagedImagePaths.clear();
    debugPrint('🧹 Cleared all staged images');
  }

  // ─────────────────────────────────────────────
  // PROCESS IMAGES BEFORE SUBMIT
  // ─────────────────────────────────────────────

  /// Process all equipment materials:
  /// - For each local image, check if already uploaded (has server URL in cache)
  /// - If uploaded, use cached server URL
  /// - If not uploaded, stage for upload
  /// Returns: Map of materialId -> List of final image URLs (server + staged)
  Future<Map<String, List<String>>> processMaterialImages(
    List<EquipmentMaterial> materials,
  ) async {
    final Map<String, List<String>> resultUrls = {};

    for (final material in materials) {
      final List<String> finalImageUrls = [];

      for (final imagePath in material.image) {
        // Check if it's already a remote URL
        if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
          finalImageUrls.add(imagePath);
          debugPrint('✅ Already remote URL: $imagePath');
          continue;
        }

        // Check if local file has a cached server URL
        final serverUrl = await _cacheDao.getServerUrl(imagePath);

        if (serverUrl != null && serverUrl.isNotEmpty) {
          // Already uploaded, use server URL
          finalImageUrls.add(serverUrl);
          debugPrint('✅ Found cached server URL: $imagePath -> $serverUrl');
        } else {
          // Not uploaded yet, stage for upload
          final file = File(imagePath);
          if (await file.exists()) {
            stageImage(materialId: material.id, imageFile: file);
            // Add a placeholder, will be replaced after upload
            finalImageUrls.add('__pending_${material.id}_${imagePath.hashCode}__');
            debugPrint('📷 Staged for upload: $imagePath');
          } else {
            debugPrint('⚠️ File not found: $imagePath');
          }
        }
      }

      resultUrls[material.id] = finalImageUrls;
    }

    return resultUrls;
  }

  // ─────────────────────────────────────────────
  // BATCH UPLOAD
  // ─────────────────────────────────────────────

  /// Uploads all staged images in ONE request.
  /// Returns: materialId → [aws_url, ...]
  /// Call this right before building the DPR payload.
  Future<Map<String, List<String>>> uploadAllStagedImages() async {
    if (_pendingImages.isEmpty) return {};

    debugPrint('📤 Batch uploading ${_pendingImages.length} image(s)...');

    final formData = FormData();
    final dataEntries = <Map<String, dynamic>>[];
    int index = 0;

    // Track which file index corresponds to which material and local path
    final Map<int, String> indexToMaterialId = {};
    final Map<int, String> indexToLocalPath = {};

    for (final entry in _pendingImages.entries) {
      final materialId = entry.key;
      final file = entry.value;
      final fileName = file.path.split('/').last;

      formData.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(file.path, filename: fileName),
      ));

      indexToMaterialId[index] = materialId;
      indexToLocalPath[index] = file.path;

      dataEntries.add({
        'id': materialId,
        'fileIndexes': [index],
      });

      index++;
    }

    // API expects 'data' as a JSON string in the form field
    formData.fields.add(MapEntry('data', jsonEncode(dataEntries)));

    final response = await DioClient.dio.post<List<dynamic>>(
      '/upload/batch-simple',
      queryParameters: {'folder': 'documents'},
      data: formData,
    );

    final results = response.data ?? [];
    final urlMap = <String, List<String>>{};

    for (final item in results) {
      final id = item['id'] as String;
      final urls = (item['urls'] as List<dynamic>).map((u) => u.toString()).toList();
      urlMap[id] = urls;
      debugPrint('✅ Got URLs for [$id]: $urls');

      // Save the mapping to cache for future use
      final localPaths = _stagedImagePaths[id] ?? [];
      for (int i = 0; i < urls.length && i < localPaths.length; i++) {
        await _cacheDao.save(serverUrl: urls[i], localPath: localPaths[i]);
        debugPrint('💾 Cached: ${localPaths[i]} -> ${urls[i]}');
      }
    }

    return urlMap;
  }

  // ─────────────────────────────────────────────
  // REPLACE PLACEHOLDERS IN MATERIALS
  // ─────────────────────────────────────────────

  /// Replace placeholders in materials with actual uploaded URLs
  List<EquipmentMaterial> replacePlaceholdersWithUrls(
    List<EquipmentMaterial> materials,
    Map<String, List<String>> uploadedUrls,
  ) {
    return materials.map((material) {
      final urls = uploadedUrls[material.id];
      if (urls == null) return material;

      final updatedImages = <String>[];
      int urlIndex = 0;

      for (final imagePath in material.image) {
        if (imagePath.startsWith('__pending_') && urlIndex < urls.length) {
          updatedImages.add(urls[urlIndex]);
          urlIndex++;
        } else {
          updatedImages.add(imagePath);
        }
      }

      return material.copyWith(image: updatedImages);
    }).toList();
  }
}
