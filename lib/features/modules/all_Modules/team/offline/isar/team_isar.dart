import 'package:isar/isar.dart';
import '../../model/teamModel.dart';


part 'team_isar.g.dart';

@collection
class TeamIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;         // backend _id
  late String siteId;     // ✅ important for filtering
  late String type;       // ✅ important for filtering

  late String teamName;
  String? teamLeadId;
  late List<String> teamMemberIds;

  late String company;
  late bool isDeleted;

  String? createdAt;
  String? updatedAt;
  String? teamLeadImage;

  TeamModel toModel() => TeamModel(
    id: id,
    teamName: teamName,
    teamLeadId: teamLeadId,
    teamMemberIds: teamMemberIds,
    company: company,
    isDeleted: isDeleted,
    type: type,
    createdAt: createdAt,
    updatedAt: updatedAt,
    teamLeadImage: teamLeadImage,
  );

  static TeamIsar fromModel(TeamModel model, String siteId) {
    final t = TeamIsar();
    t.id = model.id;
    t.siteId = siteId;
    t.type = model.type;
    t.teamName = model.teamName;
    t.teamLeadId = model.teamLeadId;
    t.teamMemberIds = model.teamMemberIds;
    t.company = model.company;
    t.isDeleted = model.isDeleted;
    t.createdAt = model.createdAt;
    t.updatedAt = model.updatedAt;
    t.teamLeadImage = model.teamLeadImage;
    return t;
  }
}
