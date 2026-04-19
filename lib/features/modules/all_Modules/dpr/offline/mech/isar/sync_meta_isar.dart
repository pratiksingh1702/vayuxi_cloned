import 'package:isar_community/isar.dart';

part 'sync_meta_isar.g.dart';

@collection
class SyncMetaIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key; // ex: "ratefile:$siteId" OR "dpr:$siteId:$teamId"

  late DateTime lastSyncAt;
}
