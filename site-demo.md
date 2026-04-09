# Site Module Onboarding - Implemented Flow

This document describes the current implemented, task-driven Site onboarding flow and where each step is wired in code.

## Architecture

- `TourModule`: feature-level module container.
- `TourStep`: route + showcase key + buddy/voice copy + required event.
- `TourController`: event-driven state machine with hint timer + TTS integration.
- `VoiceAssistantService`: wraps `flutter_tts` for speak/replay/mute.
- `SiteRegistry`: single source of truth for Site module steps and keys.

## Implemented Site Steps

| Step | Route | Action | Event |
| --- | --- | --- | --- |
| 1 | `/select-module` | Tap Site card in Setup tab | `TourEvents.siteModuleTapped` |
| 2 | `/site` | Tap Add card | `TourEvents.addSiteTapped` |
| 3 | `/site-entry-select` | Tap Import Sheet | `TourEvents.importSheetTapped` |
| 4 | `/site-import` | Download template | `TourEvents.sampleDownloaded` |
| 5 | `/site-import` | Upload and import file successfully | `TourEvents.siteFileImported` |

## File Wiring Map

- Registry + step definitions:
  - `lib/features/tour/registry/site_registry.dart`
- Event constants:
  - `lib/features/tour/domain/tour_events.dart`
- Engine + progression:
  - `lib/features/tour/domain/tour_controller.dart`
- Auto-start module:
  - `lib/features/tour/domain/tour_scrope.dart`
- Module screen step-1 showcase + event emission:
  - `lib/features/modules/screen/module_screen.dart`
- Step-2 showcase + event emission:
  - `lib/features/modules/all_Modules/site_Details/screens/view_add_site.dart`
- Step-3 showcase + event emission:
  - `lib/features/modules/all_Modules/site_Details/screens/site_entry_select_page.dart`
- Step-4 and step-5 showcase + event emission:
  - `lib/features/modules/all_Modules/site_Details/screens/site_import.dart`
- Buddy UI + action lock:
  - `lib/features/tour/screen/buddy_overlay.dart`

## Sidebar Replay Controls

Drawer now includes a `Restart Demo` button with:

1. `Complete Demo`: resets all `tour_*` keys and restarts from Site module.
2. `Site Module Demo`: replays only Site module progress.

Implemented in:

- `lib/core/utlis/widgets/sidebar.dart`

## Validation Checklist

1. Open drawer -> tap `Restart Demo` -> choose `Complete Demo`.
2. Verify step 1 highlights Site card in Setup tab.
3. Tap Site card -> step 2 appears on Add card.
4. Tap Add -> step 3 appears on Import Sheet.
5. Tap Import Sheet -> step 4 highlights Download button.
6. Download template -> step 5 highlights upload box.
7. Upload/import success -> module completes.
