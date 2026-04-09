// lib/features/tour/domain/tour_events.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// TOUR EVENT SYSTEM
// ─────────────────────────────────────────────────────────────────────────────
//
// This is the "glue" between the app's feature screens and the Tour Engine.
//
// HOW TO USE:
//   Anywhere in the app (e.g., after a successful API call or a button tap),
//   call:
//     ref.read(tourControllerProvider.notifier).onEvent(TourEvents.addSiteTapped);
//
// The TourController will compare this event ID against the current step's
// `requiredEvent` field. If they match, the step is completed automatically.
//
// ADDING A NEW MODULE:
//   Simply add new const Strings in the appropriate group below.
//   No changes needed to the Engine.
// ─────────────────────────────────────────────────────────────────────────────

class TourEvents {
  TourEvents._(); // prevent instantiation

  // ── Global / Cross-module ─────────────────────────────────────────────────
  static const String moduleScreenOpened    = 'module_screen_opened';
  static const String setupTabTapped        = 'setup_tab_tapped';

  // ── Site Module ───────────────────────────────────────────────────────────
  /// Emitted when the user taps the "Site Details" card on ModuleScreen.
  static const String siteModuleTapped      = 'site_module_tapped';

  /// Emitted when the user taps the "Add" card on SiteSelectCardGrid.
  static const String addSiteTapped         = 'add_site_tapped';

  /// Emitted when the user taps the "Import Sheet" card on SiteEntrySelectCardGrid.
  static const String importSheetTapped     = 'import_sheet_tapped';

  /// Emitted when the user taps "Download Sample Template".
  static const String sampleDownloaded      = 'site_sample_downloaded';

  /// Emitted when the user selects a local file in site import screen.
  static const String siteFileSelected      = 'site_file_selected';

  /// Emitted when the user successfully uploads and imports a site file.
  static const String siteFileImported      = 'site_file_imported';

  // ── Rate Module ───────────────────────────────────────────────────────────
  static const String rateModuleTapped      = 'rate_module_tapped';
  static const String rateCreated           = 'rate_created';

  // ── Manpower Module ───────────────────────────────────────────────────────
  static const String manpowerModuleTapped  = 'manpower_module_tapped';
  static const String manpowerAdded         = 'manpower_added';

  // ── Team Module ───────────────────────────────────────────────────────────
  static const String teamModuleTapped      = 'team_module_tapped';
  static const String teamCreated           = 'team_created';

  // ── DPR Module ────────────────────────────────────────────────────────────
  static const String dprModuleTapped       = 'dpr_module_tapped';
  static const String dprEntryAdded         = 'dpr_entry_added';
}
