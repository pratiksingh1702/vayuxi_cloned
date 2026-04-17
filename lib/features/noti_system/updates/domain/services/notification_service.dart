import 'package:firebase_messaging/firebase_messaging.dart';

import '../../data/models/notification_model.dart';
import '../../data/models/notification_priority.dart';
import '../../data/models/notification_type.dart';
import '../../data/repositories/local_notification_repository.dart';

class NotificationIngestionService {
  NotificationIngestionService._();

  static final LocalNotificationRepository _repository =
      LocalNotificationRepository();

  static Future<void> persistRemoteMessage(RemoteMessage message) async {
    final model = fromRemoteMessage(message);
    await _repository.addNotification(model);
  }

  static NotificationModel fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final now = DateTime.now();

    final rawTimestamp = data['timestamp']?.toString();
    final timestamp = DateTime.tryParse(rawTimestamp ?? '') ?? now;

    final id = data['id']?.toString().trim();
    final messageId = message.messageId?.trim();
    final resolvedId = (id != null && id.isNotEmpty)
        ? id
        : (messageId ?? 'fcm_${now.microsecondsSinceEpoch}');

    return NotificationModel(
      id: resolvedId,
      type: _parseType(data['type']?.toString()),
      title: (notification?.title ?? data['title']?.toString() ?? 'New update')
          .trim(),
      description:
          (notification?.body ?? data['body']?.toString() ?? '').trim(),
      timestamp: timestamp,
      priority: _parsePriority(data['priority']?.toString()),
      metadata: {
        ...data,
        'source': 'fcm',
        if (message.messageId != null) 'messageId': message.messageId,
      },
    );
  }

  static NotificationType _parseType(String? raw) {
    if (raw == null || raw.isEmpty) return NotificationType.update;
    try {
      return NotificationType.values.byName(raw.toLowerCase());
    } catch (_) {
      return NotificationType.update;
    }
  }

  static NotificationPriority _parsePriority(String? raw) {
    if (raw == null || raw.isEmpty) return NotificationPriority.medium;
    try {
      return NotificationPriority.values.byName(raw.toLowerCase());
    } catch (_) {
      return NotificationPriority.medium;
    }
  }
}
