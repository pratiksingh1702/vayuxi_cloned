import 'package:isar_community/isar.dart';

import '../../../../../core/local/isar_db.dart';
import '../models/notification_isar.dart';
import '../models/notification_model.dart';
import 'notification_repository.dart';

class LocalNotificationRepository implements NotificationRepository {
  bool _seeded = false;

  Future<void> _seedIfEmpty() async {
    if (_seeded) return;
    _seeded = true;

    final existingCount = await AppIsarDB.isar.updateNotificationIsars.count();
    if (existingCount > 0) return;

    // Keep first-run UX populated while still persisting everything to Isar.
    // This can be removed once server-driven notifications are always available.
    final seeds = <NotificationModel>[];
    if (seeds.isEmpty) return;

    await AppIsarDB.isar.writeTxn(() async {
      await AppIsarDB.isar.updateNotificationIsars
          .putAllById(seeds.map(UpdateNotificationIsar.fromModel).toList());
    });
  }

  @override
  Future<List<NotificationModel>> fetchNotifications({
    int page = 0,
    int limit = 20,
  }) async {
    await _seedIfEmpty();
    final start = page * limit;
    final list = await AppIsarDB.isar.updateNotificationIsars
        .where()
        .sortByTimestampDesc()
        .offset(start)
        .limit(limit)
        .findAll();

    return list.map((item) => item.toModel()).toList(growable: false);
  }

  @override
  Future<void> markAsRead(String id) async {
    await AppIsarDB.isar.writeTxn(() async {
      final record = await AppIsarDB.isar.updateNotificationIsars.getById(id);
      if (record == null) return;
      record.isRead = true;
      await AppIsarDB.isar.updateNotificationIsars.putById(record);
    });
  }

  @override
  Future<void> markAllAsRead() async {
    final records =
        await AppIsarDB.isar.updateNotificationIsars.where().findAll();
    if (records.isEmpty) return;

    await AppIsarDB.isar.writeTxn(() async {
      for (final record in records) {
        record.isRead = true;
      }
      await AppIsarDB.isar.updateNotificationIsars.putAll(records);
    });
  }

  @override
  Future<void> deleteNotification(String id) async {
    await AppIsarDB.isar.writeTxn(() async {
      await AppIsarDB.isar.updateNotificationIsars.deleteById(id);
    });
  }

  @override
  Future<void> addNotification(NotificationModel notification) async {
    await AppIsarDB.isar.writeTxn(() async {
      await AppIsarDB.isar.updateNotificationIsars
          .putById(UpdateNotificationIsar.fromModel(notification));
    });
  }

  @override
  Future<void> clearNotifications() async {
    await AppIsarDB.isar.writeTxn(() async {
      await AppIsarDB.isar.updateNotificationIsars.clear();
    });
  }

  @override
  Stream<List<NotificationModel>> watchNotifications() {
    final query =
        AppIsarDB.isar.updateNotificationIsars.where().sortByTimestampDesc();
    return query.watch(fireImmediately: true).map(
          (items) =>
              items.map((item) => item.toModel()).toList(growable: false),
        );
  }
}
