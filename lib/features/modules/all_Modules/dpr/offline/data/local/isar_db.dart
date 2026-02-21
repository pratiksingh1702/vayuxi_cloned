import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'local_material.dart';

class IsarDB {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [LocalMaterialSchema],
      directory: dir.path,
    );
  }
}
