import 'package:isar_community/isar.dart';

@collection
class RateVariantIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String variantId;     // if server provides unique variant id
  // else generate local unique: "$materialId|$moc|$floor|$uom"

  @Index()
  late String materialId;

  @Index()
  late String siteId;

  late String moc;
  late String floor;
  late String uom;
  late double rate;
  late String remarks;
}
