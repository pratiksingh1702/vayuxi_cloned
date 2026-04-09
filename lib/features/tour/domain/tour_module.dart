// lib/features/tour/domain/tour_module.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// TOUR MODULE — the "Brain" unit
// ─────────────────────────────────────────────────────────────────────────────
//
// A TourModule groups a set of TourStep objects for one feature area
// (e.g. Site Setup, Rate Setup, Manpower, etc.).
//
// Each module tracks its own completion independently so users can:
// - Replay just the Site tour without resetting others.
// - Have module completion badges per-feature.
// ─────────────────────────────────────────────────────────────────────────────

import 'tour_step_model.dart';

class TourModule {
  /// Stable identifier — matches the SharedPreferences key suffix.
  /// Example: "site" → key = "tour_module_site_done"
  final String id;

  /// Display name shown in Buddy's header / completion screen.
  final String name;

  /// Short description shown on the module completion badge.
  final String description;

  /// Emoji for the module badge on completion.
  final String emoji;

  /// The ordered list of steps that make up this module's tour.
  final List<TourStep> steps;

  const TourModule({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.steps,
  });

  int get totalSteps => steps.length;
}
