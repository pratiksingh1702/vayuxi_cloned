import 'package:flutter/cupertino.dart';
import 'package:isar_community/isar.dart';
import 'package:untitled2/core/local/isar_db.dart';
import 'cached_image.dart';

class CachedImageDao {
  Isar get _isar => AppIsarDB.isar;

  Future<String?> getLocalPath(String serverUrl) async {
    final result = await _isar.cachedImages
        .filter()
        .serverUrlEqualTo(serverUrl)
        .findFirst();
    return result?.localPath;
  }

  // ✅ NEW: Get server URL from local path
  Future<String?> getServerUrl(String localPath) async {
    final result = await _isar.cachedImages
        .filter()
        .localPathEqualTo(localPath)
        .findFirst();
    return result?.serverUrl;
  }

  // ✅ NEW: Get or create mapping between local path and server URL
  Future<String?> getOrCreateServerUrl(String localPath, {String? serverUrl}) async {
    // First, try to find existing mapping
    final existing = await _isar.cachedImages
        .filter()
        .localPathEqualTo(localPath)
        .findFirst();
    
    if (existing != null && existing.serverUrl.isNotEmpty) {
      debugPrint('✅ Found cached server URL for $localPath -> ${existing.serverUrl}');
      return existing.serverUrl;
    }
    
    // If serverUrl provided, save it
    if (serverUrl != null && serverUrl.isNotEmpty) {
      await save(
        serverUrl: serverUrl,
        localPath: localPath,
      );
      return serverUrl;
    }
    
    return null;
  }

  Future<void> save({
    required String serverUrl,
    required String localPath,
  }) async {
    // Check if entry already exists
    final existing = await _isar.cachedImages
        .filter()
        .localPathEqualTo(localPath)
        .findFirst();

    await _isar.writeTxn(() async {
      if (existing != null) {
        // Update existing entry
        existing.serverUrl = serverUrl;
        existing.localPath = localPath;
        existing.cachedAt = DateTime.now();
        await _isar.cachedImages.put(existing);
        debugPrint("📝 Updated cached image: $localPath -> $serverUrl");
      } else {
        // Create new entry
        final entry = CachedImage()
          ..serverUrl = serverUrl
          ..localPath = localPath
          ..cachedAt = DateTime.now();
        await _isar.cachedImages.put(entry);
        debugPrint("💾 Saved new cached image: $localPath -> $serverUrl");
      }
    });
  }

  Future<void> delete(String localPath) async {
    final existing = await _isar.cachedImages
        .filter()
        .localPathEqualTo(localPath)
        .findFirst();

    if (existing != null) {
      await _isar.writeTxn(() async {
        await _isar.cachedImages.delete(existing.id);
        debugPrint("🗑️ Deleted cached image entry: $localPath");
      });
    }
  }

  Future<int> cleanupOldCache({Duration olderThan = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(olderThan);

    final oldEntries = await _isar.cachedImages
        .filter()
        .cachedAtLessThan(cutoff)
        .findAll();

    if (oldEntries.isEmpty) return 0;

    final idsToDelete = oldEntries.map((e) => e.id).toList();

    await _isar.writeTxn(() async {
      await _isar.cachedImages.deleteAll(idsToDelete);
    });

    debugPrint("🧹 Cleaned up ${idsToDelete.length} old cache entries");
    return idsToDelete.length;
  }
}