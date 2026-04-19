import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../actions/api_action.dart';
import '../actions/callback_action.dart';
import '../actions/external_link_action.dart';
import '../actions/navigate_action.dart';
import '../actions/notification_action.dart';
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
    final metadata = Map<String, dynamic>.from(model.metadata);
    if (model.actions.isNotEmpty) {
      metadata['actions'] = model.actions.map((a) => a.toJson()).toList();
    }
    entity.metadataJson = jsonEncode(metadata);
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

    final actions = _actionsFromMetadata(metadata);

    return NotificationModel(
      id: id,
      type: _typeFromName(type),
      title: title,
      description: description,
      timestamp: timestamp,
      isRead: isRead,
      priority: _priorityFromName(priority),
      media: media,
      actions: actions,
      metadata: metadata,
    );
  }

  List<NotificationAction> _actionsFromMetadata(Map<String, dynamic> metadata) {
    final rawActions = metadata['actions'];
    if (rawActions is! List) return const [];

    final actions = <NotificationAction>[];
    for (final raw in rawActions) {
      if (raw is! Map) continue;
      final action = _actionFromJson(Map<String, dynamic>.from(raw));
      if (action != null) actions.add(action);
    }
    return actions;
  }

  NotificationAction? _actionFromJson(Map<String, dynamic> json) {
    final type = (json['actionType'] ?? '').toString();
    final label = (json['label'] ?? '').toString();
    final isPrimary = json['isPrimary'] == true;

    switch (type) {
      case 'navigate':
        return NavigateAction(
          label: label,
          route: (json['route'] ?? '').toString(),
          params: Map<String, dynamic>.from(json['params'] ?? {}),
          isPrimary: isPrimary,
        );
      case 'callback':
        return CallbackAction(
          label: label,
          handlerKey: (json['handlerKey'] ?? '').toString(),
          payload: Map<String, dynamic>.from(json['payload'] ?? {}),
          isPrimary: isPrimary,
        );
      case 'api':
        return ApiAction(
          label: label,
          endpoint: (json['endpoint'] ?? '').toString(),
          method: (json['method'] ?? 'POST').toString(),
          body: Map<String, dynamic>.from(json['body'] ?? {}),
          isPrimary: isPrimary,
        );
      case 'external_link':
        return ExternalLinkAction(
          label: label,
          url: (json['url'] ?? '').toString(),
          isPrimary: isPrimary,
        );
      default:
        return null;
    }
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
