/// Base class for all notification actions.
/// Functions are never stored directly — actions are pure data
/// dispatched to [ActionDispatcher] at execution time.
abstract class NotificationAction {
  const NotificationAction({
    required this.label,
    required this.actionType,
    this.isPrimary = false,
  });

  final String label;
  final String actionType; // used by dispatcher to route
  final bool isPrimary;

  Map<String, dynamic> toJson();
}