import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/api/requestQueue.dart';
import '../../application/providers/notification_list_notifier.dart';
import '../../application/providers/notification_providers.dart';
import '../../data/models/notification_model.dart';
import '../widgets/notification_tile.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context, unreadCount),
          state.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (s) => s.notifications.isEmpty
                ? const SliverFillRemaining(child: _EmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == s.notifications.length) {
                          return s.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                      child:
                                          CircularProgressIndicator.adaptive()),
                                )
                              : const SizedBox.shrink();
                        }
                        return AnimatedNotificationTile(
                          key: ValueKey(s.notifications[index].id),
                          notification: s.notifications[index],
                          index: index,
                        );
                      },
                      childCount: s.notifications.length + 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, int unreadCount) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Updates'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(notificationListProvider.notifier).markAllAsRead(),
          child: const Text('Mark all read'),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () =>
              ref.read(notificationListProvider.notifier).refresh(),
        ),
        IconButton(
          icon: const Icon(Icons.delete_sweep_rounded),
          tooltip: 'Clear All',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear All Notifications'),
                content: const Text(
                    'Are you sure you want to delete all notifications?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ref
                  .read(notificationListProvider.notifier)
                  .clearAllNotifications();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.cloud_off_rounded),
          tooltip: 'Clear API Queue',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear API Queue'),
                content: const Text(
                    'This will delete all offline saved API requests. Use this only if you want to discard pending changes.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear Queue'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await RequestQueue.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('API Queue cleared')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

class AnimatedNotificationTile extends StatefulWidget {
  const AnimatedNotificationTile({
    super.key,
    required this.notification,
    required this.index,
  });
  final NotificationModel notification;
  final int index;

  @override
  State<AnimatedNotificationTile> createState() =>
      _AnimatedNotificationTileState();
}

class _AnimatedNotificationTileState extends State<AnimatedNotificationTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: NotificationTile(notification: widget.notification),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('All caught up!',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('No new notifications',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}
