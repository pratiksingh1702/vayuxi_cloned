import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/notification_providers.dart';
import '../../data/actions/notification_action.dart';

class NotificationActionButton extends ConsumerWidget {
  const NotificationActionButton({
    super.key,
    required this.action,
    required this.notificationId,
  });
  final NotificationAction action;
  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dispatcher = ref.read(actionDispatcherProvider);
    final theme = Theme.of(context);

    return action.isPrimary
        ? FilledButton(
            onPressed: () => dispatcher.dispatch(action),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(action.label),
          )
        : OutlinedButton(
            onPressed: () => dispatcher.dispatch(action),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: theme.colorScheme.outline),
            ),
            child: Text(action.label),
          );
  }
}