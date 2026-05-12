# Structure Work Module — Complete Architecture & Functionality Documentation

> **Project:** FE-V2-Vayuxi (Flutter App)  
> **Module Path:** `lib/features/modules/all_Modules/structure_work/`  
> **Generated:** May 2026

---

## Table of Contents

1. [High-Level Overview](#1-high-level-overview)
2. [Folder Structure & File Map](#2-folder-structure--file-map)
3. [Architecture & Design Patterns](#3-architecture--design-patterns)
4. [Work Type System & Integration](#4-work-type-system--integration)
5. [BOQ Module — Full Flow](#5-boq-module--full-flow)
6. [DPR Setup Module — Full Flow](#6-dpr-setup-module--full-flow)
7. [DPR Entry Module — Full Flow](#7-dpr-entry-module--full-flow)
8. [Reports Module — Full Flow](#8-reports-module--full-flow)
9. [Data Models — Detailed Reference](#9-data-models--detailed-reference)
10. [Providers & State Management](#10-providers--state-management)
11. [Repositories & API Endpoints](#11-repositories--api-endpoints)
12. [Offline Support (Isar)](#12-offline-support-isar)
13. [Routing & Navigation](#13-routing--navigation)
14. [Screen-by-Screen Functionality](#14-screen-by-screen-functionality)
15. [Data Flow Diagrams](#15-data-flow-diagrams)
16. [DPR Entry Download Sheet Flow](#16-dpr-entry-download-sheet-flow)
17. [What Can Be Implemented / Pending](#17-what-can-be-implemented--pending)
18. [API Quick Reference Table](#18-api-quick-reference-table)

---

## 1. High-Level Overview

The **Structure Work** module is a complete sub-system within the Vayuxi PEB (Pre-Engineered Building) construction management app. It handles:

- **BOQ (Bill of Quantities)** — Upload, view, and track structure components (assembly marks, quantities, weights, dimensions)
- **DPR Setup** — Pre-configure assembly cards locally (offline-first via Isar) that serve as templates for daily entry
- **DPR Entry** — Daily Progress Report creation/update where workers log how many units of each assembly mark were used that day
- **Reports** — Download measurement sheets, abstract sheets, summary sheets, and detailed DPR reports in PDF/Excel format

### How it Fits in the App

```
WorkCategoryScreen (work_cat.dart)
  └── User selects "Structure Work" → typeProvider = "structure_work"
      └── ModuleScreenV2 (4 tabs: Daily Entry | Setup | Reports | More)
          ├── Daily Entry Tab
          │   ├── Attendance
          │   ├── Structure Erection DPR → /site-list/dpr → DprFlowGate → DprStructureFlowGate → DprStructureCreateScreen
          │   ├── Expense
          │   └── Inventory Entry
          ├── Setup Tab
          │   ├── Site Details
          │   ├── Manpower Details
          │   ├── Create Team
          │   ├── Inventory Setup
          │   ├── BOQ (Upload/View) → /site-list/structure-boq → ViewAddBoqScreen
          │   └── Structure Erection Setup → /site-list/structure-dpr-setup → DPRSetupListScreen
          └── Reports Tab
              ├── Summary & Analysis
              ├── DPR Sheets → /site-list/dprReport → DateRangeSelection → SheetDownloadPage
              └── ... other reports
```

---

## 2. Folder Structure & File Map

```
lib/features/modules/all_Modules/structure_work/
│
├── boq/                                    # BOQ (Bill of Quantities) sub-module
│   ├── isar/
│   │   ├── boq_structure_isar.dart         # Isar collections: BOQStructureIsar, BOQItemIsar
│   │   └── boq_structure_isar.g.dart       # Auto-generated Isar code
│   ├── models/
│   │   └── boq_structure_model.dart        # BOQStructure, BOQStructureItem (API models)
│   ├── providers/
│   │   ├── boq_structure_provider.dart     # BOQStructureNotifier + boqStructureProvider + boqItemsProvider
│   │   └── saved_boq_provider.dart         # SavedBOQNotifier (Isar ↔ API sync) + savedBOQProvider
│   ├── repository/
│   │   └── boq_structure_repository.dart   # API calls: getAllBOQs, getBOQDetail, getBOQItems, uploadBOQExcel
│   └── screens/
│       ├── boq_structure_dashboard.dart    # Main BOQ dashboard with stats, card list, upload FAB
│       ├── boq_detail_screen.dart          # Single BOQ detail with item table
│       ├── boq_entry_select.dart           # Entry point to add BOQ (manual/import)
│       ├── boq_import_sheet.dart           # Excel import UI
│       ├── boq_item_details.dart           # Single BOQ item detailed view
│       ├── boq_item_list.dart              # List all items across BOQs
│       └── view_add_boq.dart               # View/Add BOQ selector (2-card grid)
│
├── dpr/                                    # DPR (Daily Progress Report) sub-module
│   ├── models/
│   │   └── dpr_structure_model.dart        # DPRStructure, DPRStructureItem (API models)
│   ├── providers/
│   │   ├── dpr_structure_provider.dart     # DPRStructureNotifier + dprStructureProvider
│   │   └── dpr_entry_provider.dart         # DprEntryNotifier + dprEntryProvider (local card management)
│   ├── repository/
│   │   └── dpr_structure_repository.dart   # API calls: CRUD DPR, downloadSheet
│   └── screens/
│       ├── dpr_structure_create_screen.dart # Main DPR create/edit screen (1542 lines — most complex screen)
│       ├── dpr_structure_detail_screen.dart # View single DPR detail + delete
│       ├── dpr_structure_flow_gate.dart     # Entry gate → routes to DprStructureCreateScreen
│       └── dpr_structure_list_screen.dart   # List all DPRs with date filters
│
├── dpr_setup/                              # DPR Setup (offline-first assembly card templates)
│   ├── isar/
│   │   ├── assembly_card_isar.dart         # Isar collection: AssemblyCardIsar
│   │   └── assembly_card_isar.g.dart       # Auto-generated
│   ├── providers/
│   │   ├── dpr_setup_providers.dart        # assemblyCardsProvider (family by siteId)
│   │   └── card_config.dart                # assemblyCardConfigProvider (card edit state)
│   ├── screens/
│   │   ├── dpr_setup_list_screen.dart      # Setup screen with card editor + suggestion tab
│   │   ├── create_assembly_card_screen.dart # Detailed card creation/edit form
│   │   └── err.txt                         # Error log
│   ├── services/
│   │   └── dpr_setup_service.dart          # Isar CRUD service for AssemblyCardIsar
│   └── widgets/
│       └── assembly_card_widget.dart       # Reusable assembly card UI widget
│
└── reports/                                # Reports sub-module
    ├── structure_dpr_report_list_screen.dart # DPR report list with team/date filters
    └── structure_sheet_download_page.dart    # Delegates to SheetDownloadPage
```

---

## 3. Architecture & Design Patterns

### State Management: Riverpod

| Pattern | Usage |
|---------|-------|
| `StateNotifierProvider` | Primary state holders (`boqStructureProvider`, `dprStructureProvider`, `dprEntryProvider`, `assemblyCardsProvider`) |
| `FutureProvider.family` | One-shot fetches (`boqItemsProvider`) |
| `Provider` | Singletons (repositories) |
| `StateNotifierProvider.family` | Site-scoped providers (`assemblyCardsProvider(siteId)`) |

### Data Layer

```
Screen → Provider (StateNotifier) → Repository → DioClient (HTTP) → Backend API
                                  ↘ Isar (Local DB) ← SavedBOQProvider (sync)
```

### Offline-First Strategy

- **BOQ data** is synced to **Isar** via `SavedBOQNotifier.fetchAndSync()` — loads from local first, then syncs with remote
- **Assembly setup cards** are stored **only in Isar** via `DPRSetupService` — no server persistence yet
- **DPR entries** are created via API only — offline queue handled by `DioClient` interceptor
- **Sheet downloads** require online connectivity (binary data from API)

---

## 4. Work Type System & Integration

### WorkType Enum (`lib/typeProvider/work_type.dart`)

```dart
enum WorkType {
  mechanical,   // 'mechanical_work'
  insulation,   // 'insulation_work'
  structure,    // 'structure_work'
  civil,        // 'civil_work'
  roofing,      // 'roofing_work'
  fabrication;  // 'fabrication_work'
}
```

### Key Properties for Structure Work

| Property | Value |
|----------|-------|
| `apiValue` | `'structure_work'` |
| `displayName` | `'Structure Erection'` |
| `accentColor` | `Color(0xFFFF9800)` (Orange) |
| `imagePath` | `'assets/images/struc.png'` |
| `subtitle` | `'Heavy Steel Erection'` |
| `hasDprSetup` | `true` |
| `hasRateCard` | `false` |
| `hasBOQ` | `true` |

### typeProvider (`lib/typeProvider/type_provider.dart`)

```dart
final typeProvider = StateNotifierProvider<TypeNotifier, String?>(...);
// Stores raw API string like 'structure_work'

final workTypeProvider = Provider<WorkType?>(...);
// Derived: WorkType.fromApiValue(ref.watch(typeProvider))
```

### How Structure Work Gets Activated

1. User selects "Structure Work" on `WorkCategoryScreen` (`work_cat.dart`)
2. `typeProvider` is set to `'structure_work'`
3. `ModuleScreenV2` reads `typeProvider` and dynamically builds modules:
   - **Daily Entry** → Shows "Structure Erection DPR" card (route: `/site-list/dpr`)
   - **Setup** → Shows "BOQ" card (route: `/site-list/structure-boq`) + "Structure Erection Setup" (route: `/site-list/structure-dpr-setup`)
   - No "Rate Card" shown (structure work uses BOQ instead)

---

## 5. BOQ Module — Full Flow

### 5.1 User Journey

```
ModuleScreenV2 (Setup Tab)
  → "BOQ" card tapped
    → Route: /site-list/structure-boq
      → ViewAddBoqScreen
        ├── "View" → BoqItemListScreen (list all items across all BOQs)
        └── "Add" → BoqEntrySelectScreen
              ├── Manual Entry
              └── Import Excel → BoqImportSheet → uploadBOQExcel API
```

**Alternative entry** (from `BOQStructureDashboard`):
```
ModuleScreenV2 (Setup Tab)
  → Some flows lead to BOQStructureDashboard
    → Displays all BOQs as cards
    → FAB "Upload BOQ" → file picker → upload
    → Tap BOQ card → BOQDetailScreen (item table)
```

### 5.2 BOQ Data Model

**`BOQStructure`** (parent):
- `id`, `boqName`, `boqNumber`, `siteId`, `siteName`
- `items` → List of `BOQStructureItem`
- Aggregate stats: `totalQuantity`, `totalNetWeight`, `totalItems`, `usedQuantity`, `remainingQuantity`, `progressPercentage`
- `status` → `'draft'` | `'active'` | `'completed'`

**`BOQStructureItem`** (child):
- `id`, `assemblyMark`, `typeDescription`
- `quantity`, `availableQty`, `usedQty`, `remainingQty`
- Dimensions: `length`, `width`, `height`
- Weight: `netWeightPerUnit`, `totalNetWeight`
- `progressPercentage`

### 5.3 BOQ Upload Flow

1. User taps "Upload BOQ" FAB on `BOQStructureDashboard`
2. Bottom sheet opens → user picks `.xlsx`/`.xls` file via `file_picker`
3. File displayed with name + size
4. User confirms → `boqStructureProvider.notifier.uploadBOQ(siteId, file)`
5. Repository sends `POST /site/{siteId}/boq-structure/upload` as `multipart/form-data`
6. Body includes `file` + `workType: 'fabrication'`
7. Response parsed as `BOQStructure` → prepended to provider state list
8. Cache invalidated → success snackbar shown

### 5.4 Offline BOQ Sync (Isar)

**`SavedBOQNotifier.fetchAndSync(siteId)`**:
1. Load from Isar (`BOQStructureIsar` collection)
2. Fetch remote BOQs via API
3. Upsert remote data into Isar (by `serverId`)
4. Sync items for first BOQ via `syncItems(siteId, boqId)` 
5. Reload from Isar → update state

**Isar Collections:**
- `BOQStructureIsar` — BOQ metadata (linked to items via `IsarLinks`)
- `BOQItemIsar` — Individual assembly items (linked by `boqServerId`)

---

## 6. DPR Setup Module — Full Flow

### 6.1 Purpose

Pre-configure an **assembly card template** locally. This card stores:
- Which assembly mark to track
- Its description, quantity, weight, dimensions
- Links to BOQ item for auto-sync

This card is then **reflected into the DPR Entry screen** as a pre-filled card, so the user doesn't have to re-enter details daily.

### 6.2 User Journey

```
ModuleScreenV2 (Setup Tab)
  → "Structure Erection Setup" card tapped
    → Route: /site-list/structure-dpr-setup
      → DPRSetupListScreen
        ├── "Structure" Tab → Shows active setup card (AssemblyCardWidget)
        │   ├── User enters Assembly Mark → auto-syncs with BOQ items
        │   ├── User enters Quantity → saved to Isar
        │   └── Actions: Reset, Delete, Copy, Edit details
        └── "Suggestion" Tab → Placeholder ("Coming soon")
```

### 6.3 How Assembly Card Sync Works

When user types an **Assembly Mark** in the Setup card:

1. `_onCardUpdate(mark, qty, boqState)` is called
2. Searches all loaded BOQs (`boqStructureProvider`) for matching `assemblyMark` (case-insensitive)
3. **If found:**
   - Auto-populates: `description`, `netWeightPerUnit`, `totalNetWeight`, `length/width/height`, `availableQty`, `remainingQty`
   - Sets `boqId` and `boqItemId` for linking
4. **If not found:**
   - Just stores the raw mark + quantity (manual mode)
5. Card is saved to Isar via `assemblyCardsProvider.notifier.addCard()` or `updateCard()`

### 6.4 Single Card Enforcement

The setup enforces **only one active card per site**:
```dart
// In AssemblyCardNotifier.addCard():
final existing = await _service.getLocalAssemblyCards(siteId);
for (final ec in existing) {
  await _service.deleteAssemblyCardLocal(ec.isarId);
}
await _service.saveAssemblyCardLocal(card);
```

### 6.5 Storage

- **Isar Collection:** `AssemblyCardIsar`
- **Service:** `DPRSetupService` (Isar CRUD operations)
- **Provider:** `assemblyCardsProvider` (family by `siteId`)
- **No server sync yet** — `syncAssemblyCards()` is a placeholder

---

## 7. DPR Entry Module — Full Flow

### 7.1 This is the Core Screen — `DprStructureCreateScreen`

This is the most complex screen (1542 lines). It handles **creation, viewing, and updating** of daily progress reports.

### 7.2 Entry Point

```
User taps "Structure Erection DPR" on Daily Entry tab
  → Route: /site-list/dpr
    → Router checks type == 'structure_work'
      → DprFlowGate → DprStructureFlowGate → DprStructureCreateScreen
```

### 7.3 Screen Initialization

On load (`initState`):
1. `dprEntryProvider.notifier.initialize(siteId)` — loads unique work descriptions from Isar
2. `savedBOQProvider.notifier.fetchAndSync(siteId)` — syncs BOQ data
3. `_fetchDprsForDate(selectedDate)` — fetches existing DPRs for today

### 7.4 Smart Auto-Load Logic

When DPRs are fetched for the selected date:
- If DPRs exist → **auto-loads the most recent one** (sorted by `updatedAt` then `createdAt`)
- Populates: DPR name, plant, location, MOC, size, unit
- Shows existing items from that DPR in the card list
- User can switch between existing DPRs via dropdown

If no DPRs exist → resets to fresh entry mode

### 7.5 Card Types in the Entry Screen

The card list displays **three categories** of items:

| # | Category | Source | Editable |
|---|----------|--------|----------|
| 1 | **Setup Cards** | From `_localSetupCards` (DPR Setup module via Isar) | Mark: Yes, Qty: Yes |
| 2 | **Active (New) Cards** | From `dprEntryProvider.activeCards` (added via FAB) | Mark: Yes, Qty: Yes |
| 3 | **Existing Items** | From `_latestDpr.items` (server DPR data) | Mark: No, Qty: Yes |

### 7.6 Adding New Items

Two ways to add items:
1. **FAB (+)** → `dprEntryProvider.notifier.addEmptyCard(siteId)` — creates blank card with qty=1
2. **Add button in search bar** → same as FAB

### 7.7 BOQ Auto-Sync on Mark Entry

When user types an assembly mark in any card:
```
_syncCardWithBOQ(card, mark, qty, boqState)
  → Search all saved BOQs for matching assemblyMark
  → If found:
    → Populate: description, weight, dimensions, boqId, boqItemId
    → Validate: qty <= remainingQty (show error toast if exceeded)
    → Calculate: totalNetWeight = netWeightPerUnit × qty
  → If not found:
    → Manual mode: just store mark + qty
```

### 7.8 DPR Submission Flow

```
User taps "Submit DPR Entry"
  → Collect all items from: setupCards + activeCards
  → Validate:
    ├── All cards must have non-empty assemblyMark
    └── Quantity must not exceed remaining BOQ quantity
  → Build items payload: [{assemblyMark, qtyUsed}, ...]
  → If _isUpdate (existing DPR selected):
    → PUT /site/{siteId}/dpr-structure/{dprId}
  → If new:
    → POST /site/{siteId}/dpr-structure
  → On success:
    ├── HapticFeedback.heavyImpact()
    ├── Success toast
    ├── onSuccess callback
    └── context.pop()
```

### 7.9 Inline Edit of Existing Items

Existing DPR items (category 3) support **inline quantity editing**:
1. User changes qty in the card
2. `onUpdate` builds updated items array preserving all other items
3. Calls `dprStructureProvider.notifier.updateDPR(siteId, dprId, items: updatedItems, replaceMode: true)`
4. On success → re-fetches DPRs for date

### 7.10 Search, Filter & Sort

- **Search:** Filter cards by assembly mark or description (real-time)
- **Filter by category:** Setup Cards, New Entries, Existing Items
- **Sort options:** Name (A-Z/Z-A), Mark (A-Z), Weight (desc), Latest (createdAt desc)
- Filter UI: Bottom sheet with chips + "Apply Filters" button

### 7.11 Additional Fields

| Field | Controller | API Field |
|-------|-----------|-----------|
| DPR Name | `_workNameController` | `dprName` |
| Plant | `_plantController` | `plant` |
| Location | `_floorController` | `location` |
| MOC | `_mocController` | `moc` |
| Size | `_sizeController` | `size` |
| Unit | `_selectedUnit` (dropdown) | `unit` |

---

## 8. Reports Module — Full Flow

### 8.1 DPR Report List

```
ModuleScreenV2 (Reports Tab)
  → "DPR Sheets" card (route: /site-list/dprReport)
    → DateRangeSelectionScreen
      → Routes to SheetDownloadPage (which handles structure_work internally)
```

### 8.2 Structure DPR Report List Screen

`StructureDprReportListScreen` provides:
- Date range filtering (start/end date pickers)
- Team filtering (if teams exist for the site)
- DPR list with cards showing: name, number, date, status, totals
- Tap DPR card → opens `DprStructureCreateScreen` with `initialDpr` for editing

### 8.3 Sheet Download

`StructureSheetDownloadPage` delegates to the main `SheetDownloadPage`, which detects the work type.

**Sheet types available:**
| Sheet Type | Format | Description |
|------------|--------|-------------|
| `measurement` | PDF / Excel | Detailed measurement data |
| `abstract` | PDF / Excel | Abstract summary |
| `summary` | PDF / Excel | High-level summary |
| `detailed` | Excel only | Comprehensive DPR export |

**API:** `GET /site/{siteId}/structure-work/sheets?fromDate=&toDate=&sheetType=&format=`

Returns binary data (`Uint8List`) → saved to device / shared

---

## 9. Data Models — Detailed Reference

### BOQStructureItem

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Server `_id` |
| `assemblyMark` | `String` | Component identifier (e.g., "C1", "B2") |
| `typeDescription` | `String` | Description text |
| `quantity` | `double` | Total BOQ quantity |
| `availableQty` | `double` | Currently available |
| `length` | `double?` | Dimension in mm |
| `width` | `double?` | Dimension in mm |
| `height` | `double?` | Dimension in mm |
| `netWeightPerUnit` | `double?` | Weight per piece (kg) |
| `totalNetWeight` | `double?` | Total weight for this item |
| `usedQty` | `double` | Quantity used in DPRs so far |
| `remainingQty` | `double` | `quantity - usedQty` |
| `progressPercentage` | `double` | `(usedQty / quantity) * 100` |

### BOQStructure

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Server `_id` |
| `boqName` | `String` | BOQ display name |
| `boqNumber` | `String` | BOQ reference number |
| `siteId` | `String?` | Linked site (can be populated object) |
| `siteName` | `String?` | Site name (from populated siteId) |
| `items` | `List<BOQStructureItem>` | All items in this BOQ |
| `totalQuantity` | `double` | Sum of all item quantities |
| `totalNetWeight` | `double` | Sum of all item weights |
| `totalItems` | `int` | Count of items |
| `usedQuantity` | `double` | Sum of used quantities |
| `remainingQuantity` | `double` | Sum of remaining |
| `progressPercentage` | `double` | Overall progress |
| `status` | `String` | `'draft'` / `'active'` / `'completed'` |
| `uploadedAt` | `String?` | ISO timestamp |

### DPRStructureItem

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Server `_id` |
| `assemblyMark` | `String` | Which assembly component |
| `qtyUsed` | `double` | Quantity logged this DPR |
| `netWeightPerUnit` | `double?` | Weight per unit |
| `totalNetWeight` | `double?` | Total weight for this item |
| `length/width/height` | `double?` | Dimensions |
| `availableQty` | `double?` | BOQ available |
| `remainingQty` | `double?` | BOQ remaining |

### DPRStructure

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Server `_id` |
| `dprName` | `String` | Report name |
| `dprNumber` | `String` | Auto-generated number |
| `siteId/siteName` | `String?` | Linked site (populated) |
| `company/type` | `String?` | Company and work type |
| `items` | `List<DPRStructureItem>` | Items logged |
| `totalQtyUsed` | `double` | Sum of all qtyUsed |
| `totalNetWeight` | `double` | Sum of all weights |
| `date` | `DateTime?` | DPR date |
| `status` | `String` | `'draft'`/`'submitted'`/`'approved'`/`'rejected'` |
| `remarks` | `String?` | Optional notes |
| `createdByName` | `String?` | From populated createdBy |
| `teamId/teamName` | `String?` | Linked team (populated) |
| `plant/location/moc` | `String?` | Additional metadata |
| `size/unit` | `double?/String?` | Size specification |
| `createdAt/updatedAt` | `DateTime?` | Timestamps |

### AssemblyCardIsar (Offline Setup)

| Field | Type | Description |
|-------|------|-------------|
| `isarId` | `Id` | Auto-increment Isar ID |
| `siteId` | `String` | Indexed — site scope |
| `boqItemId` | `String` | Indexed — linked BOQ item |
| `boqId` | `String` | Indexed — linked BOQ |
| `assemblyMark` | `String` | Component mark |
| `description` | `String` | Description |
| `quantity` | `double` | Quantity for setup |
| `availableQty` | `double` | BOQ available |
| `length/width/height` | `double?` | Dimensions |
| `netWeightPerUnit` | `double?` | Weight per unit |
| `totalNetWeight` | `double?` | Total weight |
| `usedQty` | `double` | Used so far |
| `remainingQty` | `double` | Remaining |
| `progressPercentage` | `double` | Progress |
| `createdAt` | `DateTime` | When created |
| `isSynced` | `bool` | Sync status |
| `remarks` | `String?` | `@ignore` — not persisted in Isar |

---

## 10. Providers & State Management

### Provider Map

| Provider | Type | Key |
|----------|------|-----|
| `boqStructureRepositoryProvider` | `Provider<BOQStructureRepository>` | Singleton |
| `boqStructureProvider` | `StateNotifierProvider<BOQStructureNotifier, BOQStructureState>` | Global |
| `boqItemsProvider` | `FutureProvider.family` | `(siteId, boqId)` |
| `savedBOQProvider` | `StateNotifierProvider<SavedBOQNotifier, SavedBOQState>` | Global |
| `dprStructureRepositoryProvider` | `Provider<DPRStructureRepository>` | Singleton |
| `dprStructureProvider` | `StateNotifierProvider<DPRStructureNotifier, DPRStructureState>` | Global |
| `dprEntryProvider` | `StateNotifierProvider<DprEntryNotifier, DprEntryState>` | Global |
| `assemblyCardsProvider` | `StateNotifierProvider.family` | By `siteId` |
| `assemblyCardConfigProvider` | `StateNotifierProvider.family.autoDispose` | By `{siteId, card}` |
| `dprSetupServiceProvider` | `Provider<DPRSetupService>` | Singleton |

### State Classes

**BOQStructureState:**
```
boqs: List<BOQStructure>
selectedBOQ: BOQStructure?
isLoading: bool
isUploading: bool
error: String?
```

**DPRStructureState:**
```
dprs: List<DPRStructure>
selectedDPR: DPRStructure?
isLoading: bool
isSaving: bool
error: String?
filterStartDate: DateTime?
filterEndDate: DateTime?
```

**DprEntryState:**
```
activeCards: List<AssemblyCardIsar>
availableWorkNames: List<String>
selectedWorkName: String?
isLoading: bool
error: String?
```

**SavedBOQState:**
```
boqs: List<BOQStructure>
isLoading: bool
error: String?
```

---

## 11. Repositories & API Endpoints

### BOQStructureRepository

| Method | HTTP | Endpoint | Description |
|--------|------|----------|-------------|
| `getAllBOQs(siteId)` | GET | `/site/{siteId}/boq-structure` | List all BOQs for site |
| `getBOQDetail(siteId, boqId)` | GET | `/site/{siteId}/boq-structure/{boqId}` | Single BOQ metadata |
| `getBOQItems(siteId, boqId)` | GET | `/site/{siteId}/boq-structure/{boqId}/items` | BOQ with all items |
| `uploadBOQExcel(siteId, file, workType)` | POST | `/site/{siteId}/boq-structure/upload` | Upload Excel (multipart) |

### DPRStructureRepository

| Method | HTTP | Endpoint | Description |
|--------|------|----------|-------------|
| `createDPR(siteId, ...)` | POST | `/site/{siteId}/dpr-structure` | Create new DPR |
| `getDPRList(siteId, ...)` | GET | `/site/{siteId}/dpr-structure` | List DPRs (with date filters) |
| `getDPRDetail(siteId, dprId)` | GET | `/site/{siteId}/dpr-structure/{dprId}` | Single DPR detail |
| `updateDPR(siteId, dprId, ...)` | PUT | `/site/{siteId}/dpr-structure/{dprId}` | Update DPR |
| `deleteDPR(siteId, dprId)` | DELETE | `/site/{siteId}/dpr-structure/{dprId}` | Delete DPR |
| `downloadSheet(siteId, ...)` | GET | `/site/{siteId}/structure-work/sheets` | Download report (bytes) |

### Request/Response Patterns

**Create DPR Body:**
```json
{
  "items": [{"assemblyMark": "C1", "qtyUsed": 5}],
  "dprName": "Structure Work",
  "date": "2026-05-12T00:00:00.000",
  "remarks": "...",
  "plant": "Plant A",
  "location": "Floor 2",
  "moc": "MS",
  "size": 100,
  "unit": "mm"
}
```

**Update DPR Body (replaceMode):**
```json
{
  "replaceMode": true,
  "items": [{"assemblyMark": "C1", "qtyUsed": 8}],
  "dprName": "Updated Name"
}
```

**Download Sheet Query:**
```
?fromDate=2026-01-01&toDate=2026-05-12&sheetType=measurement&format=excel
```

---

## 12. Offline Support (Isar)

### Isar Collections

| Collection | Purpose | Indexes |
|------------|---------|---------|
| `BOQStructureIsar` | Cached BOQ metadata | `serverId` (unique), `siteId` |
| `BOQItemIsar` | Cached BOQ items | `serverId`, `boqServerId` |
| `AssemblyCardIsar` | DPR Setup templates | `siteId`, `boqItemId`, `boqId` |

### Sync Strategy

```
              ┌─────────────┐
              │  Remote API  │
              └──────┬───────┘
                     │ fetchAndSync()
              ┌──────▼───────┐
              │  SavedBOQ    │
              │  Notifier    │
              └──────┬───────┘
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼───┐  ┌────▼───┐  ┌───▼────┐
    │ Isar   │  │ State  │  │ DPR    │
    │ Write  │  │ Update │  │ Entry  │
    └────────┘  └────────┘  │Provider│
                            └────────┘
```

1. `fetchAndSync(siteId)` → load Isar → fetch API → upsert Isar → reload Isar → update state
2. `DprEntryProvider` reads from `savedBOQProvider` state for BOQ item lookup
3. `AssemblyCardIsar` is purely local — managed by `DPRSetupService`

---

## 13. Routing & Navigation

### Route Definitions (in `app_router.dart`)

| Route | Module Case | Screen |
|-------|-------------|--------|
| `/site-list/dpr` | `'dpr'` + type == `'structure_work'` | `DprFlowGate` → `DprStructureFlowGate` → `DprStructureCreateScreen` |
| `/site-list/structure-boq` | `'structure-boq'` | `ViewAddBoqScreen` |
| `/site-list/structure-dpr-setup` | `'structure-dpr-setup'` | `DPRSetupListScreen` |
| `/site-list/dprReport` | `'dprReport'` | `DateRangeSelectionScreen` → `SheetDownloadPage` |
| `/create-assembly-card` | Direct push | `CreateAssemblyCardScreen` |

### Flow Gate Chain

```
DprFlowGate
  ├── type == 'structure_work' → DprStructureFlowGate
  │                                └── DprStructureCreateScreen
  ├── type == 'mechanical_work' → MechanichalStepperScreen
  ├── type == 'insulation_work' → StepInsulationScreen
  └── (others) → DprTeamScreen
```

---

## 14. Screen-by-Screen Functionality

### BOQStructureDashboard
- **Stats row:** Total BOQs, Total Items, Total Weight (MT)
- **BOQ cards:** Glass-morphism design with circular progress indicator, status chip, mini-stats
- **Upload FAB:** Pulsing animation, file picker bottom sheet
- **Stagger animation:** Cards fade in sequentially
- **States:** Loading (shimmer), Empty (illustration + CTA), Error (message + retry)

### BOQDetailScreen
- **Summary card:** Total items, progress bar, total weight
- **Item list:** Expandable cards with assembly mark, dimensions, weight
- **Color-coded progress:** Green (>50%), Amber (20-50%), Red (<20%)

### ViewAddBoqScreen
- **2-card grid:** View (→ BoqItemListScreen) | Add (→ BoqEntrySelectScreen)
- **Info card** explaining each option

### DPRSetupListScreen
- **Tab bar:** Structure | Suggestion
- **Single active card** with assembly card widget
- **Auto-init:** Creates card if none exists
- **BOQ sync:** Fetches BOQs on load for mark lookup
- **Actions:** Refresh, Reset, Delete

### DprStructureCreateScreen
- **Date selector** with blue chip
- **DPR info card:** Name (editable), Plant, Location, MOC fields
- **DPR selector dropdown** for existing DPRs on same date
- **"New Entry" button** to reset all fields
- **Card list** with search + filter + sort
- **FAB** to add empty cards
- **Submit button** with loading state and validation
- **Haptic feedback** on success

### DprStructureListScreen
- **Date filter chips:** All, Today, Week, Month
- **DPR cards:** Date, number, total qty, weight, status badge
- **FAB:** Add DPR
- **Pulse animation** on FAB

### DprStructureDetailScreen
- **Header:** DPR name, date, status
- **Items table:** Assembly mark, qty used, weight
- **Actions:** Delete with confirmation, Edit (opens create screen pre-filled)

### StructureDprReportListScreen
- **Team selection guard:** If teams exist, must select team first
- **Date filtering:** Start/end date pickers
- **Team chips:** Multi-select team filter
- **DPR report cards:** Tap opens create screen with initial DPR
- **Pull-to-refresh**

---

## 15. Data Flow Diagrams

### BOQ Upload → DPR Entry Flow

```
1. UPLOAD BOQ
   User uploads Excel → API creates BOQ with items
   ↓
2. ISAR SYNC
   SavedBOQNotifier fetches → stores in Isar
   ↓
3. DPR SETUP (Optional)
   User creates assembly card → enters mark → auto-syncs from BOQ
   → Card saved to Isar (AssemblyCardIsar)
   ↓
4. DPR ENTRY
   Screen loads → reads setup cards from Isar + BOQ data from savedBOQProvider
   → User enters qty per assembly mark
   → Validates: qty <= remainingQty from BOQ
   ↓
5. SUBMIT DPR
   POST /dpr-structure → creates DPR on server
   → BOQ quantities updated server-side (usedQty++, remainingQty--)
   ↓
6. REPORTS
   GET /structure-work/sheets → downloads binary sheet
   → Saved to device or shared
```

### State Flow for DPR Create Screen

```
┌──────────────────────────────────────────────────────────────────┐
│                    DprStructureCreateScreen                       │
│                                                                  │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ dprStructure │  │ dprEntry     │  │ savedBOQ             │   │
│  │ Provider     │  │ Provider     │  │ Provider             │   │
│  │              │  │              │  │                      │   │
│  │ dprs[]       │  │ activeCards[]│  │ boqs[]               │   │
│  │ isSaving     │  │ workNames[] │  │ (items with marks)   │   │
│  │ error        │  │ isLoading    │  │                      │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                      │               │
│         ▼                 ▼                      ▼               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 Card List (3 sections)                     │   │
│  │  1. Setup Cards (from _localSetupCards / Isar)            │   │
│  │  2. Active Cards (from dprEntryProvider.activeCards)       │   │
│  │  3. Existing Items (from _latestDpr.items / API)          │   │
│  └──────────────────────────┬────────────────────────────────┘   │
│                              │ onUpdate(mark, qty)               │
│                              ▼                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              _syncCardWithBOQ()                            │   │
│  │  Searches savedBOQProvider for matching assemblyMark       │   │
│  │  → Auto-fills description, weight, dimensions              │   │
│  │  → Validates qty <= remainingQty                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              _submitDPR()                                  │   │
│  │  Collects setupCards + activeCards → validates → API call  │   │
│  │  → Creates or Updates DPR → pop on success                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 16. DPR Entry Download Sheet Flow

### How Sheet Download Works End-to-End

```
User on Reports Tab
  → Taps "DPR Sheets" card
    → Route: /site-list/dprReport
      → Router case 'dprReport':
        → DateRangeSelectionScreen
          → User selects start + end date
            → Routes to SheetDownloadPage (Routes.dprReportDownload)
              → SheetDownloadPage detects typeProvider
                → For structure_work: uses DPRStructureRepository.downloadSheet()
                → API: GET /site/{siteId}/structure-work/sheets
                  → Query params: fromDate, toDate, sheetType, format
                  → Response: binary data (Uint8List)
                → Save to device / share via share_plus
```

### StructureSheetDownloadPage

Currently a **thin wrapper** that delegates to `SheetDownloadPage`:
```dart
class StructureSheetDownloadPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SheetDownloadPage(
      selectedStartDate: selectedStartDate,
      selectedEndDate: selectedEndDate,
    );
  }
}
```

### Sheet Types & Formats

| Sheet Type | PDF | Excel | Description |
|------------|-----|-------|-------------|
| `measurement` | ✅ | ✅ | Detailed measurement data per assembly |
| `abstract` | ✅ | ✅ | Abstract/summary view |
| `summary` | ✅ | ✅ | High-level progress summary |
| `detailed` | ❌ | ✅ | Full detailed DPR export (Excel only) |

---

## 17. What Can Be Implemented / Pending

### Currently Implemented ✅

| Feature | Status | Files |
|---------|--------|-------|
| BOQ Upload (Excel) | ✅ Done | `boq_structure_dashboard.dart`, `boq_import_sheet.dart` |
| BOQ View/List | ✅ Done | `boq_structure_dashboard.dart`, `boq_detail_screen.dart`, `boq_item_list.dart` |
| BOQ Isar Offline Sync | ✅ Done | `saved_boq_provider.dart`, `boq_structure_isar.dart` |
| DPR Setup (Assembly Card) | ✅ Done | `dpr_setup_list_screen.dart`, `create_assembly_card_screen.dart` |
| DPR Create/Edit | ✅ Done | `dpr_structure_create_screen.dart` |
| DPR List with Filters | ✅ Done | `dpr_structure_list_screen.dart` |
| DPR Detail View | ✅ Done | `dpr_structure_detail_screen.dart` |
| DPR Delete | ✅ Done | `dpr_structure_detail_screen.dart` |
| Sheet Download | ✅ Done | `dpr_structure_repository.dart`, `structure_sheet_download_page.dart` |
| DPR Report List | ✅ Done | `structure_dpr_report_list_screen.dart` |
| Work Type Integration | ✅ Done | `work_type.dart`, `type_provider.dart`, `module_screen_v2.dart` |
| Router Integration | ✅ Done | `app_router.dart` |
| BOQ-to-DPR Sync | ✅ Done | Mark lookup in `_syncCardWithBOQ()` |
| Qty Validation | ✅ Done | `qty <= remainingQty` check |
| Search/Filter/Sort | ✅ Done | In `dpr_structure_create_screen.dart` |

### Pending / Can Be Improved 🔧

| Feature | Status | Description | Where to Implement |
|---------|--------|-------------|-------------------|
| **DPR Setup Server Sync** | ⏳ Placeholder | `syncAssemblyCards()` is TODO | `dpr_setup_service.dart` |
| **Suggestion Tab** | ⏳ Placeholder | "Coming soon" in DPR Setup | `dpr_setup_list_screen.dart` Tab 2 |
| **Multiple Setup Cards** | ❌ Enforced single | Currently only 1 card per site | `dpr_setup_providers.dart` — remove single-card enforcement |
| **BOQ Manual Entry** | ⏳ Partial | `BoqEntrySelectScreen` exists but manual BOQ item creation may be incomplete | `boq_entry_select.dart` |
| **BOQ Delete** | ❌ Not implemented | No delete BOQ API call in repository | Add `deleteBOQ()` to `boq_structure_repository.dart` |
| **BOQ Edit** | ❌ Not implemented | Cannot edit BOQ items after upload | Add `updateBOQItem()` to repository |
| **DPR Approval Workflow** | ⏳ Status exists | Model has `approved`/`rejected` but no UI for approval | Add approval buttons in `dpr_structure_detail_screen.dart` |
| **Offline DPR Queue** | ✅ Auto (DioClient) | POST/PUT/DELETE queued by DioClient | Already handled |
| **Offline GET Cache** | ⏳ Basic | `_cache` in BOQStructureNotifier; SavedBOQ has Isar | Extend to DPR list caching |
| **Sheet Download for Structure** | ⏳ Delegates | `StructureSheetDownloadPage` just wraps `SheetDownloadPage` — needs structure-specific sheet type UI | Customize sheet type grid for structure work |
| **Progress Tracking Dashboard** | ❌ Not built | No centralized progress view across all BOQs | Create new `StructureProgressDashboard` screen |
| **Photo/Attachment on DPR** | ❌ Not implemented | No image upload for DPR entries | Add image field to DPR create |
| **Team-Based DPR Entry** | ⏳ Partial | `teamId` field exists in DPR model but DPR create doesn't show team selector | Add team dropdown to `DprStructureCreateScreen` |
| **Remarks per Item** | ⏳ UI only | `remarks` on `AssemblyCardIsar` is `@ignore` — not persisted or sent to API | Add to Isar schema + API payload |
| **BOQ Import Validation** | ❌ Client-side | No pre-upload Excel validation | Add column format check before upload |
| **Real-time Progress Updates** | ❌ Polling only | No WebSocket/push for BOQ qty changes | Consider adding `RefreshIndicator` + periodic polling |
| **Export DPR as PDF** | ⏳ Via Sheets API | Available via `downloadSheet(sheetType: 'detailed', format: 'pdf')` | Already available (but `detailed` is Excel-only) |
| **i18n / Translation Keys** | ⏳ Partial | Some labels are hardcoded English | Add keys to language module |

---

## 18. API Quick Reference Table

| Action | Method | Endpoint | Body/Params |
|--------|--------|----------|-------------|
| List BOQs | `GET` | `/site/{siteId}/boq-structure` | — |
| BOQ Detail | `GET` | `/site/{siteId}/boq-structure/{boqId}` | — |
| BOQ Items | `GET` | `/site/{siteId}/boq-structure/{boqId}/items` | — |
| Upload BOQ | `POST` | `/site/{siteId}/boq-structure/upload` | `multipart: file, workType` |
| Create DPR | `POST` | `/site/{siteId}/dpr-structure` | `{items, dprName, date, remarks, teamId, plant, location, moc, size, unit}` |
| List DPRs | `GET` | `/site/{siteId}/dpr-structure` | `?startDate=&endDate=` |
| DPR Detail | `GET` | `/site/{siteId}/dpr-structure/{dprId}` | — |
| Update DPR | `PUT` | `/site/{siteId}/dpr-structure/{dprId}` | `{items, dprName, remarks, status, replaceMode, plant, location, moc, size, unit}` |
| Delete DPR | `DELETE` | `/site/{siteId}/dpr-structure/{dprId}` | — |
| Download Sheet | `GET` | `/site/{siteId}/structure-work/sheets` | `?fromDate=&toDate=&sheetType=&format=` |

**Base URL:** `https://be-vayuxi-chi.vercel.app/api/v1`  
**Auth:** Bearer token (auto-injected by DioClient interceptor from SharedPreferences `auth_token`)

---

*This document covers the complete Structure Work module architecture, data flow, screen functionality, offline strategy, API integration, and identifies all implemented features plus pending improvements.*
