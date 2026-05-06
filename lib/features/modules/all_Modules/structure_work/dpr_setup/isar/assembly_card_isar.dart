import 'package:isar_community/isar.dart';

part 'assembly_card_isar.g.dart';

@collection
class AssemblyCardIsar {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String siteId;

  @Index()
  late String boqItemId;

  @Index()
  late String boqId;

  late String assemblyMark;
  late String description;
  late double quantity;
  late double availableQty;
  late double? length;
  late double? width;
  late double? height;
  late double? netWeightPerUnit;
  late double? totalNetWeight;
  late double usedQty;
  late double remainingQty;
  late double progressPercentage;

  // Metadata
  late DateTime createdAt;
  late bool isSynced;

  @ignore
  String? remarks;
}
