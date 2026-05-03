# DPR Structure Refactoring Plan (Design Sync with Insulation)

This document outlines the architecture for the new Structural DPR interface, which will mirror the "testing.dart" (Insulation) design.

## 1. Data Architecture

### Frontend (Offline Storage - Isar)
- **Assembly Cards (Setup)**: `AssemblyCardIsar` stores the "Master" definitions for cards (Mark, Description, Total Qty, Weights, Dimensions). These are created in the "Setup" phase.
- **DPR Entries**: `DPRStructureIsar` (to be created) will store the daily progress. It contains:
    - `siteId`, `date`, `workDescription` (Scope).
    - A list of `MaterialEntries` (Mark, Qty Reported, Reference to Setup Card).
- **BOQ Reference**: `BOQStructureItem` is used for validation when creating ad-hoc cards.

### Backend Storage
- **DPR Records**: Stores the processed progress, linked to the site and BOQ.
- **Metadata**: Stores the weights and dimensions reported for analytical purposes.

## 2. UI Components

### Top Section (Header & Context)
- **Date Selector**: Standard date picker.
- **Work Description Dropdown**: 
    - Shows all "Work Descriptions" (Scopes) reported for the selected date.
    - Allows adding a "New Work Description" (e.g., "Main Building Steel", "Warehouse Roof").
    - Selecting an entry reloads the card list for that specific scope.

### Card List (Main Body)
- **Card Population**: 
    - When a "Work Description" is selected, the screen fetches all setup cards (`AssemblyCardIsar`) for the site.
    - Any cards already part of an existing DPR for this date/scope are pre-filled with their reported Qty.
- **Inline Editing**: Use the `AssemblyCardWidget` (redesigned in previous steps) which allows editing Mark and Qty directly.

### Ad-hoc Card Creation
- A "Search/Add" bar at the bottom or top.
- User types an **Assembly Mark**.
- **Logic**: 
    1. Search local `BOQStructureItem`s for the site.
    2. If found: Auto-create a temporary `AssemblyCardIsar` entry with BOQ values (Weight, Dimensions) and add it to the active list.
    3. If NOT found: Alert the user ("Mark not found in BOQ").

## 3. State Management (Riverpod)

- **`structuralDprProvider`**: A `StateNotifier` that holds the current state of the screen:
    - `selectedDate`, `selectedWorkDescription`.
    - `activeCards`: A list of cards being edited.
- **`saveDpr` Action**: 
    - Validates totals against BOQ remaining limits.
    - Saves to Isar.
    - Triggers background sync to backend.

## 4. Implementation Steps

1.  **Define Isar Models**: Ensure `DPRStructureIsar` is defined to support offline saving.
2.  **Create Provider**: Build the `StructuralDprNotifier` to handle the dropdown logic and card list management.
3.  **Refactor Screen**: Replace the 3-step form in `DprStructureCreateScreen` with a single-page scrolling layout matching `testing.dart`.
4.  **Integrate Ad-hoc Logic**: Implement the BOQ lookup for adding new marks.
5.  **Final Polish**: Ensure the "Blue Box" styling and left-right card design are consistent.

---
**Does this plan align with your requirements for the Structural DPR flow?**
