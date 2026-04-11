// Stub for future REST/WebSocket integration.
import '../models/notification_model.dart';
import 'notification_repository.dart';

class RemoteNotificationRepository implements NotificationRepository {
  // Inject Dio / http client here
  @override
  Future<List<NotificationModel>> fetchNotifications(
      {int page = 0, int limit = 20}) {
    throw UnimplementedError('Implement with your API client');
  }

  @override
  Future<void> markAsRead(String id) => throw UnimplementedError();
  @override
  Future<void> markAllAsRead() => throw UnimplementedError();
  @override
  Future<void> deleteNotification(String id) => throw UnimplementedError();
  @override
  Future<void> addNotification(NotificationModel n) =>
      throw UnimplementedError();
  @override
  Future<void> clearNotifications() => throw UnimplementedError();
  @override
  Stream<List<NotificationModel>> watchNotifications() =>
      throw UnimplementedError();
}
