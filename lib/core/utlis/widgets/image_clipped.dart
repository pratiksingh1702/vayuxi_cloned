import 'package:flutter/material.dart';

class CornerClippedScreenSimple extends StatelessWidget {
  final Widget child;

  final double cornerRadius;

  final Color? color;

  const CornerClippedScreenSimple({
    Key? key,
    required this.child,
    this.color,
    this.cornerRadius = 15.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        color ?? (isDark ? cs.surface : cs.surfaceContainerLowest);

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            "assets/images/Firefly_A seamless pattern on a white background, featuring various simple, breathable, blue  303856.webp",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(color: resolvedColor),
          ),
        ),

        // Theme-aware overlay tint, aligned with custom app bar treatment.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? cs.surfaceContainerHigh : cs.surface)
                      .withValues(alpha: isDark ? 0.92 : 0.94),
                  cs.surface.withValues(alpha: isDark ? 0.80 : 0.82),
                  (isDark ? cs.surfaceContainer : cs.surfaceContainerLowest)
                      .withValues(alpha: isDark ? 0.88 : 0.90),
                ],
              ),
            ),
          ),
        ),

        // Clipped Content using Container with BorderRadius
        Positioned.fill(
          child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(cornerRadius),
                topRight: Radius.circular(cornerRadius),
              ),
              child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: resolvedColor,
                  ),
                  child: child)),
        ),
      ],
    );
  }
}
