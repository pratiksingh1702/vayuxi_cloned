import 'package:isar/isar.dart';

part 'dynamic_fields.g.dart';

@embedded
class DynamicFieldIsar {
  late String key;
  late String label;
  String? valueJson; // store dynamic safely
  late String unit;
  late String displayText;
}
