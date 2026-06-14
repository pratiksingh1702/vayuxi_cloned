import 'notification_action.dart';

/// Callbacks are resolved by key via [ActionHandlerRegistry].
/// Never store a Function() directly in the model.
class CallbackAction extends NotificationAction {
  const CallbackAction({
    required super.label,
    required this.handlerKey,
    this.payload = const {},
    super.isPrimary,
  }) : super(actionType: 'callback');

  final String handlerKey;
  final Map<String, dynamic> payload;

  @override
  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'label': label,
        'handlerKey': handlerKey,
        'payload': payload,
        'isPrimary': isPrimary,
      };
}