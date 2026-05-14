import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:untitled2/core/api/requestQueueModel.dart';

import '../../data/models/notification_model.dart';
import '../../data/models/notification_priority.dart';
import '../../data/models/notification_type.dart';
import '../../data/repositories/local_notification_repository.dart';

class NotificationIngestionService {
  NotificationIngestionService._();

  static final LocalNotificationRepository _repository =
      LocalNotificationRepository();
  static const String _syncSource = 'sync_queue';

  static Future<void> persistRemoteMessage(RemoteMessage message) async {
    final model = fromRemoteMessage(message);
    await _repository.addNotification(model);
  }

  static Future<void> persistQueuedRequest(QueuedRequest request) async {
    final now = DateTime.now();
    final context = _buildRequestContext(request);

    final model = NotificationModel(
      id: _syncNotificationId(request.id),
      type: NotificationType.update,
      title: 'Saved offline',
      description:
          'Your ${context['taskLabel']} is safely saved. We will send it automatically when internet is back.',
      timestamp: now,
      priority: NotificationPriority.high,
      metadata: {
        ...context,
        'source': _syncSource,
        'syncStatus': 'queued',
        'queuedAt': now.toIso8601String(),
      },
    );

    await _repository.addNotification(model);
  }

  static Future<void> persistSyncSuccess(QueuedRequest request) async {
    await _repository.deleteNotification(_syncNotificationId(request.id));
  }

  static Future<void> persistSyncRunning(QueuedRequest request) async {}

  static Future<void> persistSyncRetryFailed(
    QueuedRequest request,
    String message,
  ) async {
    final now = DateTime.now();
    final context = _buildRequestContext(request);

    final model = NotificationModel(
      id: _syncNotificationId(request.id),
      type: NotificationType.update,
      title: 'Waiting for internet',
      description:
          'We could not send your ${context['taskLabel']} yet. It is still saved and we will try again automatically.',
      timestamp: now,
      priority: NotificationPriority.medium,
      metadata: {
        ...context,
        'source': _syncSource,
        'syncStatus': 'retry_failed',
        'lastTriedAt': now.toIso8601String(),
        'friendlyReason': _friendlyRetryReason(message),
      },
    );

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

  static String _syncNotificationId(String requestId) => 'sync_$requestId';

  static Map<String, dynamic> _buildRequestContext(QueuedRequest request) {
    final taskLabel = _humanTaskLabel(request.method, request.path);

    return {
      'requestId': request.id,
      'taskLabel': taskLabel,
      if (request.query != null && request.query!.isNotEmpty)
        'query': _jsonSafeMap(request.query!),
      if (request.data != null && request.data!.isNotEmpty)
        'data': _jsonSafeMap(request.data!),
      if (request.files != null && request.files!.isNotEmpty)
        'files': request.files!
            .map((f) => {
                  'field': f['key']?.toString() ?? '',
                  'name': f['filename']?.toString() ?? '',
                })
            .toList(),
    };
  }

  static Map<String, dynamic> _jsonSafeMap(Map<dynamic, dynamic> input) {
    final safe = <String, dynamic>{};

    input.forEach((key, value) {
      final stringKey = key.toString();

      if (value == null || value is String || value is num || value is bool) {
        safe[stringKey] = value;
        return;
      }

      if (value is Map) {
        safe[stringKey] = _jsonSafeMap(value);
        return;
      }

      if (value is List) {
        safe[stringKey] = value.map((item) {
          if (item == null || item is String || item is num || item is bool) {
            return item;
          }
          if (item is Map) return _jsonSafeMap(item);
          return item.toString();
        }).toList();
        return;
      }

      safe[stringKey] = value.toString();
    });

    return safe;
  }

  static String _humanTaskLabel(String method, String path) {
    final lower = path.toLowerCase();

    var section = 'record';
    if (lower.contains('dpr')) section = 'daily progress update';
    if (lower.contains('site')) section = 'site details';
    if (lower.contains('manpower')) section = 'manpower entry';
    if (lower.contains('rate')) section = 'rate entry';
    if (lower.contains('team')) section = 'team details';
    if (lower.contains('expense')) section = 'expense entry';
    if (lower.contains('inventory')) section = 'inventory entry';

    switch (method.toUpperCase()) {
      case 'POST':
        return 'new $section';
      case 'PUT':
      case 'PATCH':
        return 'changes to $section';
      case 'DELETE':
        return 'deletion of $section';
      case 'GET':
        return '$section refresh';
      default:
        return '$section update';
    }
  }

  static String _friendlyRetryReason(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('timeout')) {
      return 'Internet was too slow while sending. We will try again automatically.';
    }
    if (lower.contains('socket') || lower.contains('network')) {
      return 'Internet connection looks unstable right now. We will try again automatically.';
    }
    if (lower.contains('server')) {
      return 'Could not complete this right now. We will try again automatically.';
    }
    return 'Could not send right now. We will try again automatically.';
  }
}
