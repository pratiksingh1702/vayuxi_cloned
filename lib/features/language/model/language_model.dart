import 'package:hive/hive.dart';

part 'language_model.g.dart';

@HiveType(typeId: 1)
class LanguageModule extends HiveObject {
  @HiveField(0)
  final String languageCode;

  @HiveField(1)
  final String moduleName;

  @HiveField(2)
  final Map<String, dynamic> content;

  LanguageModule({
    required this.languageCode,
    required this.moduleName,
    required this.content,
  });
}
