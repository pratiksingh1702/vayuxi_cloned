import 'package:hive/hive.dart';

part 'download_language.g.dart';

@HiveType(typeId: 2)
class DownloadLanguage extends HiveObject {
  @HiveField(0)
  final String code;

  @HiveField(1)
  final String version;

  DownloadLanguage({
    required this.code,
    required this.version,
  });
}
