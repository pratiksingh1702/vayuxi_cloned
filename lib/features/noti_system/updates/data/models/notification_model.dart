import 'package:freezed_annotation/freezed_annotation.dart';
import '../actions/notification_action.dart';
import 'notification_media.dart';
import 'notification_priority.dart';
import 'notification_type.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required NotificationType type,
    required String title,
    required String description,
    required DateTime timestamp,
    @Default(false) bool isRead,
    @Default(NotificationPriority.medium) NotificationPriority priority,
    NotificationMedia? media,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default([])
    List<NotificationAction> actions,
    @Default({}) Map<String, dynamic> metadata,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
