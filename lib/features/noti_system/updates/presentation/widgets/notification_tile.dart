import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/notification_list_notifier.dart';
import '../../application/providers/notification_providers.dart';
import '../../data/models/notification_model.dart';
import '../navigation/updates_routes.dart';
import 'notification_action_button.dart';
import 'notification_media_widget.dart';
import 'priority_indicator.dart';
import 'unread_badge.dart';

enum _NotificationMenuAction { remindLater, delete }

class NotificationTile extends ConsumerWidget {
  const NotificationTile({super.key, required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: notification.isRead
                ? theme.colorScheme.surface
                : theme.colorScheme.primaryContainer.withOpacity(0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ref.read(notificationListProvider.notifier).markAsRead(notification.id);
              UpdatesRoutes.goDetail(context, notification);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PriorityIndicator(priority: notification.priority),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(notification.timestamp),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                UnreadBadge(isRead: notification.isRead),
                                PopupMenuButton<_NotificationMenuAction>(
                                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: _NotificationMenuAction.remindLater,
                                      child: Text('Remind in 1 hour'),
                                    ),
                                    PopupMenuItem(
                                      value: _NotificationMenuAction.delete,
                                      child: Text('Delete'),
                                    ),
                                  ],
                                  onSelected: (value) => _onMenuSelected(context, ref, value),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.description,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (notification.media != null) ...[
                    const SizedBox(height: 10),
                    NotificationMediaWidget(media: notification.media!),
                  ],
                  if (notification.actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: notification.actions
                          .map((a) => NotificationActionButton(
                                action: a,
                                notificationId: notification.id,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  Future<void> _onMenuSelected(
    BuildContext context,
    WidgetRef ref,
    _NotificationMenuAction action,
  ) async {
    switch (action) {
      case _NotificationMenuAction.delete:
        await ref
            .read(notificationListProvider.notifier)
            .deleteNotification(notification.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification deleted')),
          );
        }
        return;
      case _NotificationMenuAction.remindLater:
        await ref
            .read(notificationListProvider.notifier)
            .remindLater(notification, delay: const Duration(hours: 1));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder set for 1 hour later')),
          );
        }
        return;
    }
  }
}
