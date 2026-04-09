import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

/// The type of raw action this step requires from the user.
enum TourActionType { tap, view, create, select, input, navigate }

/// Current status of the entire tour engine.
enum TourStatus { idle, running, paused, completed }

/// What the Buddy should do while waiting for an action.
enum BuddyWaitMode {
  /// Pulse gently – user just needs to tap something.
  tap,
  /// Glow strongly – user must complete a task (create/upload).
  task,
  /// Static – informational step, moves on its own.
  info,
}

/// Preferred initial placement of buddy panel for a step.
enum BuddyPlacement {
  top,
  bottom,
}

// ─────────────────────────────────────────────────────────────────────────────
// TOUR STEP
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one guided step inside a [TourModule].
///
/// ### Engine Role
/// `TourController` reads this to:
/// - Know which route the step belongs to (for smart navigation).
/// - Know which [showcaseKey] to highlight with ShowcaseView.
/// - Know which [requiredEvent] to wait for before auto-advancing.
/// - Know what voice message to speak via TTS.
/// - Show a [hintMessage] if the user is stuck.
///
/// ### Brain Role
/// `site_registry.dart` (and future module registries) populate these
/// instances. The engine never knows about "Site" – it only reads
/// the abstract `TourStep` fields.
class TourStep {
  /// Unique step identifier (e.g., `"site_add_tap"`).
  final String id;

  /// The GoRouter location this step lives on.
  /// Engine will auto-navigate here if the user is elsewhere.
  final String route;

  /// Showcase key that wraps the UI widget to highlight.
  /// Assign this key to a `Showcase(key: ..., child: ...)` widget.
  final GlobalKey showcaseKey;

  /// Short title shown in the Buddy bubble header.
  final String title;

  /// Full message shown in the Buddy chat bubble.
  final String buddyMessage;

  /// Spoken aloud by TTS. Defaults to [buddyMessage] if null.
  final String? voiceMessage;

  /// Hint spoken/shown if the user remains idle for [hintDelaySeconds].
  final String? hintMessage;

  /// Delay (seconds) before the hint is shown. Default = 8s.
  final int hintDelaySeconds;

  /// The TourEvent that causes this step to auto-complete.
  /// If null → the step is informational and can be dismissed
  /// manually (Buddy shows a "Got it" button).
  final String? requiredEvent;

  /// Controls Buddy's visual waiting animation.
  final BuddyWaitMode waitMode;

  /// Whether `ShowcaseView` should auto-highlight on step entry.
  final bool autoShowcase;

  /// Optional description label under the progress indicator.
  final String? progressLabel;

  /// Preferred initial buddy placement for this step.
  final BuddyPlacement buddyPlacement;

  const TourStep({
    required this.id,
    required this.route,
    required this.showcaseKey,
    required this.title,
    required this.buddyMessage,
    this.voiceMessage,
    this.hintMessage,
    this.hintDelaySeconds = 8,
    this.requiredEvent,
    this.waitMode = BuddyWaitMode.tap,
    this.autoShowcase = true,
    this.progressLabel,
    this.buddyPlacement = BuddyPlacement.bottom,
  });

  /// Spoken text (falls back to buddyMessage).
  String get ttsText => voiceMessage ?? buddyMessage;

  /// True when this step expects a concrete user-task event.
  bool get isTaskDriven => requiredEvent != null;
}
