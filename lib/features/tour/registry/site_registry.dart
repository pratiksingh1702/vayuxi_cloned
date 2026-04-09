// lib/features/tour/registry/site_registry.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// SITE MODULE BRAIN
// ─────────────────────────────────────────────────────────────────────────────
//
// This is the ONLY file you edit when you want to change the Site tour.
// It defines:
//   1. GlobalKeys  → assigned to Showcase-wrapped widgets in the UI.
//   2. TourSteps   → each step's voice message, hint, and required event.
//   3. SiteModule  → the assembled TourModule used by TourController.
//
// HOW TO ADD A NEW MODULE:
//   Copy this file → rename to rate_registry.dart, manpower_registry.dart, etc.
//   Fill in the steps and keys. Engine needs zero changes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:untitled2/core/router/routes.dart';

import '../domain/tour_events.dart';
import '../domain/tour_module.dart';
import '../domain/tour_step_model.dart';

class SiteRegistry {
  SiteRegistry._(); // singleton-like namespace, not a class to instantiate

  // ── 1. Showcase GlobalKeys ─────────────────────────────────────────────────
  //
  // Place each key on the corresponding Showcase widget in the target screen.
  // Naming: <screen>_<widget>_key

  /// ModuleScreen → the "Site Details" grid card.
  static final siteModuleCardKey = GlobalKey(debugLabel: 'site_module_card');

  /// SiteSelectCardGrid → the "Add" card.
  static final addSiteCardKey = GlobalKey(debugLabel: 'site_add_card');

  /// SiteEntrySelectCardGrid → the "Import Sheet" card.
  static final importSheetCardKey = GlobalKey(debugLabel: 'site_import_card');

  /// SiteImportCsvScreen → the "Download Sample" button.
  static final downloadSampleKey = GlobalKey(debugLabel: 'site_download_btn');

  /// SiteImportCsvScreen → the file upload box.
  static final uploadBoxKey = GlobalKey(debugLabel: 'site_upload_box');

  /// SiteImportCsvScreen → final upload button.
  static final uploadFileButtonKey =
      GlobalKey(debugLabel: 'site_upload_file_btn');

  // ── 2. Steps ───────────────────────────────────────────────────────────────

  // ✅ Site tour starts on /site route (view/add site screen)
  // Step 1 is Add Site card tap

  static final TourStep step2_tapAdd = TourStep(
    id: 'site_tap_add',
    route: Routes.site,
    showcaseKey: addSiteCardKey,
    title: 'View or Add 🏠',
    buddyMessage:
        "Great! You can View your existing sites — or Add a new one.\nLet's tap Add to create your first site!",
    voiceMessage:
        "Great job! You have two options here. You can view your existing sites, or add a brand new one. For now, let's tap on Add.",
    hintMessage: "Tap the Add card — it's on the right side.",
    hintDelaySeconds: 8,
    requiredEvent: TourEvents.addSiteTapped,
    waitMode: BuddyWaitMode.tap,
    autoShowcase: true,
    progressLabel: 'Choose Add',
  );

  static final TourStep step3_tapImport = TourStep(
    id: 'site_tap_import',
    route: Routes.siteEntrySelect,
    showcaseKey: importSheetCardKey,
    title: 'Import is Easiest ✨',
    buddyMessage:
        "Two ways to add a site:\n• Manual Entry (type all details)\n• Import Sheet (upload a file — fastest! 🚀)\n\nTap Import Sheet — I'll guide you through it.",
    voiceMessage:
        "You can enter site details manually, or import from a file — which is much faster! Let's tap Import Sheet.",
    hintMessage: "Tap the Import Sheet card on the right.",
    hintDelaySeconds: 8,
    requiredEvent: TourEvents.importSheetTapped,
    waitMode: BuddyWaitMode.tap,
    autoShowcase: true,
    progressLabel: 'Choose Import',
  );

  static final TourStep step4_downloadSample = TourStep(
    id: 'site_download_sample',
    route: Routes.siteImport, // SiteImportCsvScreen route
    showcaseKey: downloadSampleKey,
    title: 'Get the Template 📥',
    buddyMessage:
        "Before uploading, we need your file in the right format.\n\n✅ If you have a site file already → skip to upload!\n📥 Recommended: Download our template first, fill it, then upload.",
    voiceMessage:
        "If you already have a site data file, great! Otherwise, I recommend downloading our sample template first. Fill it in, and then upload. It ensures everything imports perfectly.",
    hintMessage: "Tap the Download Sample button at the top.",
    hintDelaySeconds: 12,
    requiredEvent: TourEvents.sampleDownloaded,
    waitMode: BuddyWaitMode.task,
    autoShowcase: true,
    progressLabel: 'Download Template',
    buddyPlacement: BuddyPlacement.bottom,
  );

  static final TourStep step5_selectFile = TourStep(
    id: 'site_select_file',
    route: Routes.siteImport,
    showcaseKey: uploadBoxKey,
    title: 'Select Your File 📂',
    buddyMessage:
        'Now tap the file box and choose your filled template file.',
    voiceMessage:
        'Great. Please select your filled template file from device storage.',
    hintMessage: 'Tap the upload area and select your Excel or CSV file.',
    hintDelaySeconds: 10,
    requiredEvent: TourEvents.siteFileSelected,
    waitMode: BuddyWaitMode.task,
    autoShowcase: true,
    progressLabel: 'Select File',
    buddyPlacement: BuddyPlacement.bottom,
  );

  static final TourStep step6_uploadFile = TourStep(
    id: 'site_upload_file',
    route: Routes.siteImport,
    showcaseKey: uploadFileButtonKey,
    title: 'Upload Your File 🚀',
    buddyMessage:
        'Perfect. Now tap Upload Site File to import data into your site setup.',
    voiceMessage:
        'Perfect. Press the upload button now to import your selected file.',
    hintMessage: 'Tap Upload Site File button to finish this setup.',
    hintDelaySeconds: 10,
    requiredEvent: TourEvents.siteFileImported,
    waitMode: BuddyWaitMode.task,
    autoShowcase: true,
    progressLabel: 'Upload File',
    buddyPlacement: BuddyPlacement.bottom,
  );

  // ── 3. Assembled Module ────────────────────────────────────────────────────

  static final TourModule module = TourModule(
    id: 'site',
    name: 'Site Setup',
    description: 'Create and import your first construction site.',
    emoji: '🏗️',
    steps: [
      // ✅ Start directly at step 2 (Add site card on site list page)
      step2_tapAdd,
      step3_tapImport,
      step4_downloadSample,
      step5_selectFile,
      step6_uploadFile,
    ],
  );
}
