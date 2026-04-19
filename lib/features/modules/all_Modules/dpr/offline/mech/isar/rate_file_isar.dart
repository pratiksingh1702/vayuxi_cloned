import 'package:isar_community/isar.dart';

import 'dynamic_fields.dart';

part 'rate_file_isar.g.dart';

@collection
class RateFileAnalysisIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String rateFileId;

  @Index()
  late String siteId;

  late String fileName;
  late String status;
  late String detectedFieldsJson;

  late String uploadDate;

  late DateTime syncedAt;
}

@collection
class RateFileMaterialIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String materialId;

  @Index()
  late String siteId;

  @Index()
  late String rateFileId;

  late String materialName;
  late String image;
  late String uom;
  late String calculationCategory;
  late String rawMaterialName;
  late String normalizedMaterialName;

  List<DynamicFieldIsar> dynamicFields = [];

  late String designationJoined; // store list as string
  late String approvalStatus;

  late String normalizedMoc;
}

@collection
class RateVariantIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String variantKey;
  // ex: "$materialId|$moc|$floor|$uom|$rate"

  @Index()
  late String siteId;

  @Index()
  late String materialId;

  late String moc;
  late String floor;
  late String uom;
  late double rate;
  late String remarks;
}
