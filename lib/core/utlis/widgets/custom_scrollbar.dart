import 'package:flutter/material.dart';

class CustomScrollbar extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final double thickness;
  final Radius radius;
  final bool thumbVisibility;
  final bool interactive;
  final bool enabled;

  const CustomScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thickness = 7.0,
    this.radius = const Radius.circular(999),
    this.thumbVisibility = true,
    this.interactive = true,
    this.enabled = true,
  });

  @override
  State<CustomScrollbar> createState() => _CustomScrollbarState();
}

class _CustomScrollbarState extends State<CustomScrollbar> {
  ScrollController? _fallbackController;

  ScrollController get _effectiveController {
    return widget.controller ?? (_fallbackController ??= ScrollController());
  }

  @override
  void didUpdateWidget(covariant CustomScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == null && widget.controller != null) {
      _fallbackController?.dispose();
      _fallbackController = null;
    }
  }

  @override
  void dispose() {
    _fallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final cs = Theme.of(context).colorScheme;
    final controller = _effectiveController;
    final baseThickness = widget.thickness;

    return ScrollbarTheme(
      data: ScrollbarTheme.of(context).copyWith(
        thumbVisibility: WidgetStateProperty.all(widget.thumbVisibility),
        trackVisibility: WidgetStateProperty.all(widget.thumbVisibility),
        interactive: widget.interactive,
        radius: widget.radius,
        minThumbLength: 44,
        thickness: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) return baseThickness + 3;
          if (states.contains(WidgetState.hovered)) return baseThickness + 2;
          return baseThickness;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return cs.primary.withValues(alpha: 0.9);
          }
          if (states.contains(WidgetState.hovered)) {
            return cs.primary.withValues(alpha: 0.72);
          }
          return cs.primary.withValues(alpha: 0.48);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final alpha = states.contains(WidgetState.hovered) ? 0.16 : 0.09;
          return cs.onSurface.withValues(alpha: alpha);
        }),
        trackBorderColor: WidgetStateProperty.all(
          cs.outlineVariant.withValues(alpha: 0.34),
        ),
      ),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: widget.thumbVisibility,
        trackVisibility: widget.thumbVisibility,
        interactive: widget.interactive,
        radius: widget.radius,
        child: PrimaryScrollController(
          controller: controller,
          child: widget.child,
        ),
      ),
    );
  }
}
