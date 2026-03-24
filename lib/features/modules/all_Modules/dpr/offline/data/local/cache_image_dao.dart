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
    final entry = CachedImage()
      ..serverUrl = serverUrl
      ..localPath = localPath
      ..cachedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.cachedImages.put(entry);
    });
  }
}