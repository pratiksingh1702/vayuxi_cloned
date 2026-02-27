import 'package:isar/isar.dart';

@collection
class RateMaterialIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String materialId;      // server lineItem id

  @Index()
  late String siteId;

  late String designation;     // piping/equipment
  late String materialName;
  late String rawMaterialName;
  late String normalizedMaterialName;

  late String image;
  late String approvalStatus;  // approved/rejected/suggested
  late String calculationCategory;
  late String normalizedMoc;

  DateTime? updatedAt;
}
