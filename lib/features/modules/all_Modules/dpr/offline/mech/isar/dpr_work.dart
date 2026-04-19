import 'package:isar_community/isar.dart';

part 'dpr_work.g.dart';

@collection
class DprIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String dprId; // backend id OR local generated id (uuid)

  @Index()
  late String siteId;

  @Index()
  late String teamId;

  late String dprName;
  late String workType; // mechanical_work / insulation_work

  late String dataJson; // store whole DPR json

  late bool isSynced;
  late bool isDeleted;

  late DateTime createdAt;
  late DateTime updatedAt;
}
