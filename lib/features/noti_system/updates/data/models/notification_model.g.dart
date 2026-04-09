// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationModelImpl(
      id: json['id'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      priority: $enumDecodeNullable(
              _$NotificationPriorityEnumMap, json['priority']) ??
          NotificationPriority.medium,
      media: json['media'] == null
          ? null
          : NotificationMedia.fromJson(json['media'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
        _$NotificationModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
      'priority': _$NotificationPriorityEnumMap[instance.priority]!,
      'media': instance.media,
      'metadata': instance.metadata,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.system: 'system',
  NotificationType.promo: 'promo',
  NotificationType.alert: 'alert',
  NotificationType.update: 'update',
  NotificationType.social: 'social',
  NotificationType.transaction: 'transaction',
  NotificationType.custom: 'custom',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.medium: 'medium',
  NotificationPriority.high: 'high',
};
