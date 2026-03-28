import 'package:flutter/cupertino.dart';
import 'package:isar/isar.dart';
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

  Future<void> save({
    required String serverUrl,
    required String localPath,
  }) async {
    // Check if entry already exists
    final existing = await _isar.cachedImages
        .filter()
        .serverUrlEqualTo(serverUrl)
        .findFirst();

    await _isar.writeTxn(() async {
      if (existing != null) {
        // Update existing entry
        existing.localPath = localPath;
        existing.cachedAt = DateTime.now();
        await _isar.cachedImages.put(existing);
        debugPrint("📝 Updated cached image: $serverUrl -> $localPath");
      } else {
        // Create new entry
        final entry = CachedImage()
          ..serverUrl = serverUrl
          ..localPath = localPath
          ..cachedAt = DateTime.now();
        await _isar.cachedImages.put(entry);
        debugPrint("💾 Saved new cached image: $serverUrl -> $localPath");
      }
    });
  }

  // Optional: Add method to delete stale entries
  Future<void> delete(String serverUrl) async {
    final existing = await _isar.cachedImages
        .filter()
        .serverUrlEqualTo(serverUrl)
        .findFirst();

    if (existing != null) {
      await _isar.writeTxn(() async {
        await _isar.cachedImages.delete(existing.id);
        debugPrint("🗑️ Deleted cached image entry: $serverUrl");
      });
    }
  }

  // Optional: Add cleanup method for old/unused cache entries
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