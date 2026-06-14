import 'package:isar_community/isar.dart';

@collection
class LocalMaterial {
  Id id = Isar.autoIncrement;

  // Server identity
  String? serverId;

  // Domain
  late String siteId;
  late String domain; // insulation | mechanical
  late String designation; // piping | equipment

  // Data
  late String name;
  String? uom;
  List<String> images = [];

  // Sync control
  bool isDirty = false;      // modified locally
  bool isDeleted = false;   // soft delete
  DateTime updatedAt = DateTime.now();
}
