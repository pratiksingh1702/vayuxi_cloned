import 'package:isar_community/isar.dart';

@collection
class DprItemIsar {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String dprId;

  late String designation; // piping/equipment

  late String materialName;
  late String uom;
  late String moc;
  late String floor;

  late double qty;
  late double length;
  late double weight;
  late double rate;

  // rate-file tracking
  late bool isFromRateFile;
  String? rateFileId;
  String? rateMaterialId;
  String? rateVariantId;
}
