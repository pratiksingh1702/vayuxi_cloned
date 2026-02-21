import 'package:isar/isar.dart';
import '../../../../../../core/local/isar_db.dart';
import 'team_isar.dart';

class TeamLocalStorage {
  Isar get isar => AppIsarDB.isar;



  Future<List<TeamIsar>> getTeams({
    required String type,
    required String siteId,
  }) async {
    return await isar.teamIsars
        .filter()
        .typeEqualTo(type)
        .and()
        .siteIdEqualTo(siteId)
        .and()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<void> saveTeams({
    required String type,
    required String siteId,
    required List<TeamIsar> teams,
  }) async {
    await isar.writeTxn(() async {
      await isar.teamIsars.putAll(teams);
    });
  }

  Future<void> deleteTeamsNotIn({
    required String type,
    required String siteId,
    required Set<String> keepIds,
  }) async {
    final all = await isar.teamIsars
        .filter()
        .typeEqualTo(type)
        .and()
        .siteIdEqualTo(siteId)
        .findAll();

    final toDelete = all.where((t) => !keepIds.contains(t.id)).toList();

    if (toDelete.isEmpty) return;

    await isar.writeTxn(() async {
      for (final item in toDelete) {
        await isar.teamIsars.delete(item.isarId);
      }
    });
  }
}
