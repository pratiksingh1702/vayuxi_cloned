import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/notification_media.dart';

class NotificationMediaWidget extends StatelessWidget {
  const NotificationMediaWidget({
    super.key,
    required this.media,
    this.isExpanded = false,
  });
  final NotificationMedia media;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isExpanded ? 0 : 12),
      child: switch (media.type) {
        NotificationMediaType.image ||
        NotificationMediaType.gif =>
          CachedNetworkImage(
            imageUrl: media.url,
            fit: isExpanded ? BoxFit.cover : BoxFit.cover,
            height: isExpanded ? 260 : 160,
            width: double.infinity,
            placeholder: (_, __) => Container(
              height: isExpanded ? 260 : 160,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Center(child: CircularProgressIndicator.adaptive()),
            ),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
        NotificationMediaType.video => _VideoPlaceholder(height: isExpanded ? 260 : 160),
      },
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.black87,
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}