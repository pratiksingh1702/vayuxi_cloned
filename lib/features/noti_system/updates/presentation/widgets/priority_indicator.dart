import 'package:flutter/material.dart';
import '../../data/models/notification_priority.dart';

class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({super.key, required this.priority});
  final NotificationPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: _color(priority),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _color(NotificationPriority p) => switch (p) {
        NotificationPriority.high => const Color(0xFFE53935),
        NotificationPriority.medium => const Color(0xFFFB8C00),
        NotificationPriority.low => const Color(0xFF43A047),
      };
}