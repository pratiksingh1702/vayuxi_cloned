import 'notification_action.dart';

class ApiAction extends NotificationAction {
  const ApiAction({
    required super.label,
    required this.endpoint,
    this.method = 'POST',
    this.body = const {},
    super.isPrimary,
  }) : super(actionType: 'api');

  final String endpoint;
  final String method;
  final Map<String, dynamic> body;

  @override
  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'label': label,
        'endpoint': endpoint,
        'method': method,
        'body': body,
        'isPrimary': isPrimary,
      };
}