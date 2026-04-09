import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_priority.dart';
import '../widgets/notification_action_button.dart';
import '../widgets/notification_media_widget.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: 'notification_card_${notification.id}',
      transitionOnUserGestures: true,
      createRectTween: (begin, end) =>
          MaterialRectArcTween(begin: begin, end: end),
      flightShuttleBuilder: _heroShuttle,
      child: Material(
        color: theme.colorScheme.surface,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: notification.media != null ? 280 : 120,
                flexibleSpace: FlexibleSpaceBar(
                  background: notification.media != null
                      ? NotificationMediaWidget(
                          media: notification.media!,
                          isExpanded: true,
                        )
                      : null,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 14),
                  title: Text(
                    notification.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: notification.media != null ? Colors.white : null,
                      shadows: notification.media != null
                          ? [const Shadow(blurRadius: 6, color: Colors.black54)]
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MetaRow(notification: notification),
                    const SizedBox(height: 20),
                    Text(
                      notification.description,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                    ),
                    if (notification.metadata.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _MetadataSection(metadata: notification.metadata),
                    ],
                  ]),
                ),
              ),
            ],
          ),
          bottomSheet: notification.actions.isNotEmpty
              ? _StickyActions(notification: notification)
              : null,
        ),
      ),
    );
  }

  Widget _heroShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final heroWidget = direction == HeroFlightDirection.push
        ? toHeroContext.widget as Hero
        : fromHeroContext.widget as Hero;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubicEmphasized,
      reverseCurve: Curves.easeOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      child: Material(
        color: Colors.transparent,
        child: heroWidget.child,
      ),
      builder: (context, child) {
        final t = curved.value;
        return Opacity(
          opacity: 0.88 + (0.12 * t),
          child: Transform.scale(
            scale: 0.985 + (0.015 * t),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _TypeChip(type: notification.type.name),
        const Spacer(),
        _PriorityChip(priority: notification.priority),
        const SizedBox(width: 10),
        Text(
          DateFormat('MMM d, y • h:mm a').format(notification.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(type.toUpperCase()),
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final NotificationPriority priority;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (priority) {
      NotificationPriority.high => (Colors.red.shade600, 'HIGH'),
      NotificationPriority.medium => (Colors.orange.shade600, 'MED'),
      NotificationPriority.low => (Colors.green.shade600, 'LOW'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.metadata});
  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        ...metadata.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('${e.key}: ',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('${e.value}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: notification.actions
            .map((a) => NotificationActionButton(
                  action: a,
                  notificationId: notification.id,
                ))
            .toList(),
      ),
    );
  }
}
