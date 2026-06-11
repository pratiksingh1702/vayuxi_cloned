# ERP Tour Architecture

## Summary

Phase 1 uses a package-agnostic tour layer owned by `features/tour/`.
The app keeps `showcaseview` only behind `TourPackageAdapter`, so the
spotlight renderer can be replaced later without changing tour definitions.

## Phase 1

- Welcome tour.
- Daily Entry tab tour.
- Setup tab tour.
- Reports tab tour.
- More tab tour.

These are high-level introductions only. They explain what each tab and visible
module list is for. They do not force a user through Site, Rate, Team, or DPR.

## Phase 2

Module tours become independent assets registered by id. Examples:

- Site Details Tour
- Rate Setup Tour
- Attendance Tour
- Expense Tour
- Inventory Tour
- DPR Tour

Adding a module tour should require a definition file, registration, and target
keys on the screen being explained.

## Package Strategy

- `showcaseview`: already installed, active, good spotlight adapter for Phase 1.
- `tutorial_coach_mark`: viable fallback if the adapter changes later.
- `feature_discovery`: too tied to Material feature discovery and package-owned
  persistence for this app's role-aware modular model.
- `flutter_onboarding_slider`: suited to full-screen onboarding slides, not
  contextual in-app module tours.

## Migration Notes

The old `TourCheckpoint` flow created a global sequence from setup navigation
into specific modules. Phase 1 removes that behavior from `ModuleScreenV2` and
uses independent completion keys:

- `phase1_tour_welcome_done`
- `phase1_tour_daily_entry_done`
- `phase1_tour_setup_done`
- `phase1_tour_reports_done`
- `phase1_tour_more_done`

Old deep Site onboarding is intentionally not auto-started in Phase 1. It should
be rebuilt later as a Phase 2 module tour if needed.
