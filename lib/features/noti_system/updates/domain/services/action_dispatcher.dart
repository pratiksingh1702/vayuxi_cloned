import 'package:flutter/material.dart' hide CallbackAction;
import 'package:go_router/go_router.dart';
import '../../data/actions/api_action.dart';
import '../../data/actions/callback_action.dart';
import '../../data/actions/external_link_action.dart';
import '../../data/actions/navigate_action.dart';
import '../../data/actions/notification_action.dart';
import 'action_handler_registry.dart';

/// Single entry point for all notification action execution.
/// UI never navigates or calls APIs directly — it dispatches here.
class ActionDispatcher {
  const ActionDispatcher({required this.router, required this.registry});

  final GoRouter router; // or your NavigationService abstraction
  final ActionHandlerRegistry registry;

  Future<void> dispatch(NotificationAction action) async {
    switch (action) {
      case NavigateAction(:final route, :final params):
        router.push(route, extra: params.isNotEmpty ? params : null);
        return;

      case CallbackAction(:final handlerKey, :final payload):
        final handler = registry.resolve(handlerKey);
        if (handler != null) {
          await handler(payload);
        } else {
          debugPrint('[ActionDispatcher] No handler for key: $handlerKey');
        }
        return;

      case ApiAction(:final endpoint, :final method, :final body):
        // Inject your API client here
        debugPrint('[ActionDispatcher] API $method $endpoint body=$body');
        return;

      case ExternalLinkAction(:final url):
        // Use url_launcher
        debugPrint('[ActionDispatcher] Open URL: $url');
        return;

      default:
        debugPrint(
            '[ActionDispatcher] Unknown action type: ${action.actionType}');
        return;
    }
  }
}
