import 'dart:convert';

import 'package:isar/isar.dart';

import 'notification_media.dart';
import 'notification_model.dart';
import 'notification_priority.dart';
import 'notification_type.dart';

part 'notification_isar.g.dart';

@collection
class UpdateNotificationIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String id;

  @Index()
  late DateTime timestamp;

  late String type;
  late String title;
  late String description;
  late bool isRead;
  late String priority;
  String? mediaUrl;
  String? mediaType;
  String? mediaThumbnailUrl;
  String? mediaAltText;
  late String metadataJson;

  static UpdateNotificationIsar fromModel(NotificationModel model) {
    final entity = UpdateNotificationIsar();
    entity.id = model.id;
    entity.timestamp = model.timestamp;
    entity.type = model.type.name;
    entity.title = model.title;
    entity.description = model.description;
    entity.isRead = model.isRead;
    entity.priority = model.priority.name;
    entity.mediaUrl = model.media?.url;
    entity.mediaType = model.media?.type.name;
    entity.mediaThumbnailUrl = model.media?.thumbnailUrl;
    entity.mediaAltText = model.media?.altText;
    entity.metadataJson = jsonEncode(model.metadata);
    return entity;
  }

  NotificationModel toModel() {
    Map<String, dynamic> metadata;
    try {
      final decoded = jsonDecode(metadataJson);
      metadata =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      metadata = <String, dynamic>{};
    }

    NotificationMedia? media;
    if (mediaUrl != null && mediaType != null) {
      media = NotificationMedia(
        url: mediaUrl!,
        type: _mediaTypeFromName(mediaType!),
        thumbnailUrl: mediaThumbnailUrl,
        altText: mediaAltText,
      );
    }

    return NotificationModel(
      id: id,
      type: _typeFromName(type),
      title: title,
      description: description,
      timestamp: timestamp,
      isRead: isRead,
      priority: _priorityFromName(priority),
      media: media,
      metadata: metadata,
    );
  }

  NotificationType _typeFromName(String raw) {
    try {
      return NotificationType.values.byName(raw);
    } catch (_) {
      return NotificationType.custom;
    }
  }

  NotificationPriority _priorityFromName(String raw) {
    try {
      return NotificationPriority.values.byName(raw);
    } catch (_) {
      return NotificationPriority.medium;
    }
  }

  NotificationMediaType _mediaTypeFromName(String raw) {
    try {
      return NotificationMediaType.values.byName(raw);
    } catch (_) {
      return NotificationMediaType.image;
    }
  }
}
