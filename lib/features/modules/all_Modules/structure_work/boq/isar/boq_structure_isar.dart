import 'package:isar_community/isar.dart';

part 'boq_structure_isar.g.dart';

@collection
class BOQStructureIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String serverId;

  @Index()
  late String siteId;

  late String boqName;
  late String boqNumber;
  late double totalQuantity;
  late double totalNetWeight;
  late int totalItems;
  late double usedQuantity;
  late double remainingQuantity;
  late double progressPercentage;
  late String status;
  late DateTime? uploadedAt;

  // Link to items
  final items = IsarLinks<BOQItemIsar>();
}

@collection
class BOQItemIsar {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String serverId;

  @Index()
  late String boqServerId;

  late String assemblyMark;
  late double quantity;
  late double availableQty;
  late double usedQty;
  late double remainingQty;
  late double? length;
  late double? width;
  late double? height;
  late double? netWeightPerUnit;
  late double? totalNetWeight;
  late double progressPercentage;
}
