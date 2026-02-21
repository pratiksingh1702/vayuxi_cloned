import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

enum TourActionType { tap, view, create, select }
enum TourStatus { idle, running, paused, completed }

class TourStep {
  final String id;
  final String route; // GoRouter location OR name (use location for stability)
  final GlobalKey showcaseKey;

  final String buddyMessage;
  final String? title;
  final TourActionType actionType;

  /// If set, engine may navigate there when user taps NEXT.
  final String? nextRoute;

  /// Optional: if true, TourController should auto-run Showcase on screen.
  final bool autoShowcase;

  const TourStep({
    required this.id,
    required this.route,
    required this.showcaseKey,
    required this.buddyMessage,
    this.title,
    this.actionType = TourActionType.tap,
    this.nextRoute,
    this.autoShowcase = true,
  });
}
