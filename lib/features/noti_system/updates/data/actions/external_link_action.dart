import 'notification_action.dart';

class ExternalLinkAction extends NotificationAction {
  const ExternalLinkAction({
    required super.label,
    required this.url,
    super.isPrimary,
  }) : super(actionType: 'external_link');

  final String url;

  @override
  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'label': label,
        'url': url,
        'isPrimary': isPrimary,
      };
}