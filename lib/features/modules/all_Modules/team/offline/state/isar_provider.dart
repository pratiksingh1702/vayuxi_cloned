import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../isar/team_isar.dart'; // TeamIsar collection file

class TeamIsarDB {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    // ✅ prevent multiple open
    final existing = Isar.getInstance('team_db');
    if (existing != null) {
      isar = existing;
      return;
    }

    isar = await Isar.open(
      [TeamIsarSchema], // ✅ ONLY TEAM
      directory: dir.path,
      name: 'team_db',
    );
  }
}
