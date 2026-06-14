import 'notification_action.dart';

class NavigateAction extends NotificationAction {
  const NavigateAction({
    required super.label,
    required this.route,
    this.params = const {},
    super.isPrimary,
  }) : super(actionType: 'navigate');

  final String route;
  final Map<String, dynamic> params;

  @override
  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'label': label,
        'route': route,
        'params': params,
        'isPrimary': isPrimary,
      };
}