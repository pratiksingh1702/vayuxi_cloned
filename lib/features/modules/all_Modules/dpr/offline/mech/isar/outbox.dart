import 'package:isar_community/isar.dart';

part 'outbox.g.dart';

enum OutboxType {
  createDpr,
  updateDpr,
  deleteDpr,
}

@collection
class OutboxIsar {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String siteId;

  @Index()
  late String teamId;

  late int type; // store OutboxType.index

  late String payloadJson;
  late DateTime createdAt;

  late bool isDone;
  late String? error;
}
