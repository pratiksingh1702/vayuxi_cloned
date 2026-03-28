import 'package:flutter/material.dart';

class CustomScrollbar extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final double thickness;
  final Radius radius;
  final bool thumbVisibility;
  final bool interactive;

  /// 🔥 NEW: toggle scrollbar on/off
  final bool enabled;

  const CustomScrollbar({
    super.key,
    required this.child,
    this.controller,
    this.thickness = 6.0,
    this.radius = const Radius.circular(10),
    this.thumbVisibility = true,
    this.interactive = true,
    this.enabled = true, // default ON
  });

  @override
  Widget build(BuildContext context) {
    // ❌ If disabled → return child directly (zero overhead)
    if (!enabled) {
      return child;
    }

    final ctrl = controller ?? ScrollController();

    return Scrollbar(
      controller: ctrl,
      thumbVisibility: thumbVisibility,
      thickness: thickness,
      interactive: interactive,
      radius: radius,
      child: PrimaryScrollController(
        controller: ctrl,
        child: child,
      ),
    );
  }
}