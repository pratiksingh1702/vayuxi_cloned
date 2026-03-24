import 'package:isar/isar.dart';

part 'cached_image.g.dart';

@collection
class CachedImage {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String serverUrl;

  late String localPath;

  DateTime cachedAt = DateTime.now();
}