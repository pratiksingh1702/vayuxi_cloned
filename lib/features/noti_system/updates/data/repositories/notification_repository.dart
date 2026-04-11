import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications(
      {int page = 0, int limit = 20});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> addNotification(NotificationModel notification);
  Future<void> clearNotifications();
  Stream<List<NotificationModel>> watchNotifications(); // WebSocket-ready
}
