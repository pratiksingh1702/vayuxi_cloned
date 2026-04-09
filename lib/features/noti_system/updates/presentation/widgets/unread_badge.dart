import 'package:flutter/material.dart';

class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.isRead});
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    if (isRead) return const SizedBox.shrink();
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}