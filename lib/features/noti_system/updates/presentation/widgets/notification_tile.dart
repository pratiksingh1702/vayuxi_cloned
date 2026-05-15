import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/notification_list_notifier.dart';
import '../../application/providers/notification_providers.dart';
import '../../data/models/notification_model.dart';
import '../navigation/updates_routes.dart';
import 'notification_action_button.dart';
import 'notification_media_widget.dart';
import 'unread_badge.dart';

class NotificationTile extends ConsumerWidget {
  const NotificationTile({super.key, required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSyncUpdate = notification.metadata['source'] == 'sync_queue';
    final syncStatus = notification.metadata['syncStatus']?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(notificationListProvider.notifier).markAsRead(notification.id);
          
          // Direct navigation for drafts
          final source = notification.metadata['source'];
          if (source == 'dpr_upload' || source == 'dpr_insu_upload') {
            final actions = notification.metadata['actions'] as List?;
            final editAction = actions?.firstWhere(
              (a) => a['label'] == 'Edit',
              orElse: () => null,
            );
            
            if (editAction != null) {
              final route = editAction['route'] as String;
              final params = editAction['params'] as Map<String, dynamic>?;
              context.push(route, extra: params);
              return;
            }
          }

          UpdatesRoutes.goDetail(context, notification);
        },
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              _buildMinimalIcon(isSyncUpdate, syncStatus, theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      notification.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black.withOpacity(0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!notification.isRead)
                const UnreadBadge(isRead: false),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.black.withOpacity(0.2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalIcon(bool isSync, String? status, ThemeData theme) {
    IconData icon = Icons.notifications_none_rounded;
    Color color = const Color(0xFF6366F1);
    Color bg = const Color(0xFFE0E7FF);

    if (isSync) {
      if (status == 'running') {
        icon = Icons.sync_rounded;
        color = Colors.blue;
        bg = Colors.blue.withOpacity(0.1);
      } else if (status == 'success') {
        icon = Icons.check_circle_outline_rounded;
        color = Colors.green;
        bg = Colors.green.withOpacity(0.1);
      } else if (status == 'retry_failed') {
        icon = Icons.error_outline_rounded;
        color = Colors.orange;
        bg = Colors.orange.withOpacity(0.1);
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  String _formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);
}
