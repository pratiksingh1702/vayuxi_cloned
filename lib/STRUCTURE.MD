# 🏗️ STRUCTURE WORK FEATURE — FULL IMPLEMENTATION PROMPT

> **For AI/Developer implementing the `structure_work` module in the existing Flutter app.**
> Read every section. Do not skip. Every detail matters.

---

## 0. CONTEXT — WHO YOU ARE WORKING WITH

This is a **production Flutter app** using:
- **State management:** `flutter_riverpod`
- **Navigation:** `go_router`
- **HTTP client:** Custom `DioClient` (`lib/core/api/dio_client.dart`) with offline queue, bearer token auth, cookie jar
- **Architecture:** Feature-based folder structure under `lib/features/`
- **Work types:** Currently `mechanical_work` and `insulation_work` managed via `typeProvider`. You are adding `structure_work`.

The app already has:
- A `WorkCategoryScreen` where user selects work type
- A `ModuleScreenV2` with 4 tabs: Daily Entry, Setup, Reports, More
- A `DprFlowGate` that routes DPR based on work type
- A `SheetDownloadPage` for downloading reports
- A `GoRouter` in `appRouterProvider`

---

## 1. FOLDER STRUCTURE TO CREATE [DONE]

Create the following inside `lib/features/`:

```
lib/features/modules/all_Modules/structure_work/
├── boq/
│   ├── models/
│   │   └── boq_structure_model.dart          # BOQ + BOQItem data models
│   ├── providers/
│   │   └── boq_structure_provider.dart       # Riverpod providers for BOQ state
│   ├── repository/
│   │   └── boq_structure_repository.dart     # API calls via DioClient
│   └── screens/
│       ├── boq_structure_dashboard.dart      # List of all BOQs for selected site
│       ├── boq_detail_screen.dart            # Single BOQ detail with items table
│       └── boq_upload_screen.dart            # Excel upload UI (file picker)
│
└── dpr/
    ├── models/
    │   └── dpr_structure_model.dart          # DPR + DPRItem data models
    ├── providers/
    │   └── dpr_structure_provider.dart       # Riverpod providers for DPR state
    ├── repository/
    │   └── dpr_structure_repository.dart     # API calls via DioClient
    └── screens/
        ├── dpr_structure_list_screen.dart    # List DPR entries with filters
        ├── dpr_structure_create_screen.dart  # Create new DPR form
        ├── dpr_structure_detail_screen.dart  # View single DPR detail
        └── dpr_structure_flow_gate.dart      # Entry point (similar to DprFlowGate)
```

Also create a **shared report screen**:
```
lib/features/modules/all_Modules/structure_work/
└── reports/
    └── structure_sheet_download_page.dart   # Sheet download (mirrors SheetDownloadPage)
```

---

## 2. DATA MODELS [DONE]

### 2.1 `boq_structure_model.dart`

```dart
class BOQStructureItem {
  final String id;
  final String assemblyMark;
  final double quantity;
  final double availableQty;
  final double? length;
  final double? width;
  final double? height;
  final double? netWeightPerUnit;
  final double totalNetWeight;
  final double usedQty;
  final double remainingQty;
  final double progressPercentage;

  const BOQStructureItem({...});

  factory BOQStructureItem.fromJson(Map<String, dynamic> json) => BOQStructureItem(
    id: json['_id'],
    assemblyMark: json['assemblyMark'],
    quantity: (json['quantity'] as num).toDouble(),
    availableQty: (json['availableQty'] as num).toDouble(),
    length: (json['length'] as num?)?.toDouble(),
    width: (json['width'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
    netWeightPerUnit: (json['netWeightPerUnit'] as num?)?.toDouble(),
    totalNetWeight: (json['totalNetWeight'] as num).toDouble(),
    usedQty: (json['usedQty'] as num).toDouble(),
    remainingQty: (json['remainingQty'] as num).toDouble(),
    progressPercentage: (json['progressPercentage'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {...};
}

class BOQStructure {
  final String id;
  final String boqName;
  final String boqNumber;
  final String siteId;
  final List<BOQStructureItem> items;
  final double totalQuantity;
  final double totalNetWeight;
  final int totalItems;
  final double usedQuantity;
  final double remainingQuantity;
  final double progressPercentage;
  final String status; // 'draft' | 'active' | 'completed'
  final String uploadMethod; // 'excel' | 'manual'
  final String? excelFileName;
  final DateTime uploadedAt;

  factory BOQStructure.fromJson(Map<String, dynamic> json) => ...;
}
```

### 2.2 `dpr_structure_model.dart`

```dart
class DPRStructureItem {
  final String id;
  final String assemblyMark;
  final double qtyUsed;
  final double? netWeightPerUnit;
  final double totalNetWeight;
  final String boqItemId;

  factory DPRStructureItem.fromJson(Map<String, dynamic> json) => ...;
}

class DPRStructure {
  final String id;
  final String dprName;
  final String dprNumber;
  final String siteId;
  final String? teamId;
  final String boqId;
  final String boqName; // populated
  final List<DPRStructureItem> items;
  final double totalQtyUsed;
  final double totalNetWeight;
  final DateTime date;
  final String status; // 'draft' | 'submitted' | 'approved' | 'rejected'
  final String? remarks;
  final String? createdByName;
  final DateTime createdAt;

  factory DPRStructure.fromJson(Map<String, dynamic> json) => ...;
}
```

---

## 3. API REPOSITORY — BASE URLS [DONE]

All calls use the existing `DioClient.dio` which has `baseUrl = "https://be-vayuxi-chi.vercel.app/api/v1"`.

Auth token is automatically injected by the DioClient interceptor (reads from SharedPreferences key `auth_token`).

### 3.1 `boq_structure_repository.dart`

```dart
class BOQStructureRepository {
  // GET /site/{siteId}/boq-structure
  Future<List<BOQStructure>> getAllBOQs(String siteId) async {
    final res = await DioClient.dio.get('/site/$siteId/boq-structure');
    final List data = res.data['data'];
    return data.map((e) => BOQStructure.fromJson(e)).toList();
  }

  // GET /site/{siteId}/boq-structure/{boqId}
  Future<BOQStructure> getBOQDetail(String siteId, String boqId) async { ... }

  // GET /site/{siteId}/boq-structure/{boqId}/items
  Future<BOQStructure> getBOQItems(String siteId, String boqId) async { ... }

  // POST /site/{siteId}/boq-structure/upload (multipart/form-data)
  Future<BOQStructure> uploadBOQExcel(String siteId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
    });
    final res = await DioClient.dio.post(
      '/site/$siteId/boq-structure/upload',
      data: formData,
    );
    return BOQStructure.fromJson(res.data['data']);
  }
}
```

### 3.2 `dpr_structure_repository.dart`

```dart
class DPRStructureRepository {
  // POST /site/{siteId}/dpr-structure
  Future<DPRStructure> createDPR(String siteId, {
    required String boqId,
    required List<Map<String, dynamic>> items, // [{assemblyMark, qtyUsed, boqItemId}]
    DateTime? date,
    String? remarks,
    String? teamId,
  }) async { ... }

  // GET /site/{siteId}/dpr-structure (optional ?startDate=&endDate=&boqId=)
  Future<List<DPRStructure>> getDPRList(String siteId, {
    DateTime? startDate,
    DateTime? endDate,
    String? boqId,
  }) async { ... }

  // GET /site/{siteId}/dpr-structure/{dprId}
  Future<DPRStructure> getDPRDetail(String siteId, String dprId) async { ... }

  // PUT /site/{siteId}/dpr-structure/{dprId}
  Future<DPRStructure> updateDPR(String siteId, String dprId, Map<String, dynamic> body) async { ... }

  // DELETE /site/{siteId}/dpr-structure/{dprId}
  Future<void> deleteDPR(String siteId, String dprId) async { ... }

  // GET /site/{siteId}/structure-work/sheets?fromDate=&toDate=&sheetType=&format=
  // Returns Uint8List (binary)
  Future<Uint8List> downloadSheet(String siteId, {
    required String fromDate,  // YYYY-MM-DD
    required String toDate,
    required String sheetType, // measurement | abstract | summary | detailed
    required String format,    // pdf | excel
  }) async {
    final res = await DioClient.dio.get(
      '/site/$siteId/structure-work/sheets',
      queryParameters: {
        'fromDate': fromDate,
        'toDate': toDate,
        'sheetType': sheetType,
        'format': format,
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data);
  }
}
```

---

## 4. RIVERPOD PROVIDERS [DONE]

### 4.1 `boq_structure_provider.dart`

```dart
// Repository provider
final boqStructureRepositoryProvider = Provider((ref) => BOQStructureRepository());

// State class
class BOQStructureState {
  final List<BOQStructure> boqs;
  final BOQStructure? selectedBOQ;
  final bool isLoading;
  final String? error;
  // ...
}

// Notifier
class BOQStructureNotifier extends StateNotifier<BOQStructureState> { ... }

final boqStructureProvider = StateNotifierProvider<BOQStructureNotifier, BOQStructureState>(
  (ref) => BOQStructureNotifier(ref.read(boqStructureRepositoryProvider)),
);

// Helper: BOQ items for a specific BOQ (used in DPR create form)
final boqItemsProvider = FutureProvider.family<BOQStructure, ({String siteId, String boqId})>(
  (ref, args) => ref.read(boqStructureRepositoryProvider).getBOQItems(args.siteId, args.boqId),
);
```

### 4.2 `dpr_structure_provider.dart`

```dart
final dprStructureRepositoryProvider = Provider((ref) => DPRStructureRepository());

class DPRStructureState {
  final List<DPRStructure> dprs;
  final DPRStructure? selectedDPR;
  final bool isLoading;
  final String? error;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? filterBoqId;
}

class DPRStructureNotifier extends StateNotifier<DPRStructureState> {
  Future<void> fetchDPRList(String siteId) async { ... }
  Future<void> createDPR(String siteId, {...}) async { ... }
  Future<void> updateDPR(String siteId, String dprId, Map body) async { ... }
  Future<void> deleteDPR(String siteId, String dprId) async { ... }
  void setFilters({DateTime? start, DateTime? end, String? boqId}) { ... }
}

final dprStructureProvider = StateNotifierProvider<DPRStructureNotifier, DPRStructureState>(
  (ref) => DPRStructureNotifier(ref.read(dprStructureRepositoryProvider)),
);
```

---

## 5. TYPE PROVIDER — ENHANCEMENT [DONE]

### Current state (read carefully):

The `typeProvider` currently holds a raw string: `"mechanical_work"` or `"insulation_work"`.

### Problems to fix:
1. Raw strings everywhere = typo-prone
2. No enum, so no exhaustive switch checking
3. No helper methods

### Solution — create `lib/typeProvider/work_type.dart`:

```dart
enum WorkType {
  mechanical,
  insulation,
  structure;

  String get apiValue {
    switch (this) {
      case WorkType.mechanical: return 'mechanical_work';
      case WorkType.insulation: return 'insulation_work';
      case WorkType.structure: return 'structure_work';
    }
  }

  String get displayName {
    switch (this) {
      case WorkType.mechanical: return 'Mechanical Work';
      case WorkType.insulation: return 'Insulation Work';
      case WorkType.structure: return 'Structure Work';
    }
  }

  bool get hasDprSetup => this != WorkType.structure;
  bool get hasRateCard => this != WorkType.structure;
  bool get hasBOQ => this == WorkType.structure;

  static WorkType? fromApiValue(String? value) {
    switch (value) {
      case 'mechanical_work': return WorkType.mechanical;
      case 'insulation_work': return WorkType.insulation;
      case 'structure_work': return WorkType.structure;
      default: return null;
    }
  }
}
```

Then update `typeProvider` to store `WorkType?` instead of `String?`. All existing `.setType("mechanical_work")` calls change to `.setType(WorkType.mechanical)`. Update all switch/if-else blocks throughout the codebase to use `WorkType` enum. The `typeProvider.apiValue` is passed when the API needs the string.

**Important:** Keep backward compatibility. Provide a `typeStringProvider` convenience provider that returns `type?.apiValue` so existing code that reads a String still works without a full migration in one shot.

```dart
final typeStringProvider = Provider<String?>((ref) => ref.watch(typeProvider)?.apiValue);
```

---

## 6. WORK CATEGORY SCREEN — ADD STRUCTURE WORK CARD [DONE]

In `work_cat.dart` (`WorkCategoryScreen`), inside `_CategorySpotlightCard`, the `GridView.count` currently has `crossAxisCount: 2` with 2 cards.

**Change to 3 cards, crossAxisCount: 2, wrapping naturally.** Add a third `CompanyCard` for Structure Work:

```dart
CompanyCard(
  imagePath: 'assets/images/structure.webp', // add this asset OR use a network fallback
  companyName: 'Structure Work',
  subtitle: 'BOQ tracking, DPR entry and structural progress management.',
  accentColor: const Color(0xFF7B3F00), // deep brown/amber — premium feel
  elevationColor: elevationColor,
  isSelected: selectedImage == 'structure',
  onTap: onSelectStructure, // new callback
),
```

In `handlePress`, add:
```dart
} else if (id == "structure") {
  typeNotifier.setType(WorkType.structure); // updated enum
}
```

**UI note:** The grid should now show 3 cards. Use `crossAxisCount: 2` with 3 children so the layout wraps to 2 rows (2 + 1). Give the lone bottom card a `Center` wrapper or a `widthFactor: 0.5` so it doesn't stretch full width — or keep 3-column layout.

**Alternative (cleaner):** Switch `GridView.count(crossAxisCount: 2)` to a `Wrap` or a `Column` with two `Row`s: first row has Mechanical + Insulation, second row has Structure centered. This gives a premium asymmetric layout.

---

## 7. MODULE SCREEN V2 — STRUCTURE WORK MODULES [DONE]

In `module_screen_v2.dart`, the `_setupModules` list currently has:
```dart
ModuleItem(labelKey: 'rate_card', ...),      // KEEP for mechanical/insulation
ModuleItem(labelKey: 'dpr_setup_card', ...),  // KEEP for mechanical/insulation
```

**Change `_setupModules` to be dynamic based on `WorkType`:**

```dart
List<ModuleItem> get _setupModules {
  final type = ref.read(typeProvider); // or watch in build
  
  final base = [
    ModuleItem(labelKey: 'site_details_card', icon: Icons.location_city_rounded, iconColor: Colors.cyan, routeName: "/site"),
    ModuleItem(labelKey: 'manpower_details_card', icon: Icons.engineering_rounded, iconColor: Colors.deepOrange, routeName: "/manpower"),
    ModuleItem(labelKey: 'create_team_card', icon: Icons.groups_rounded, iconColor: Colors.purple, routeName: "/site-list/team"),
    ModuleItem(labelKey: 'inventory_setup_card', icon: Icons.warehouse_rounded, iconColor: Colors.brown, routeName: "/site-list/inv-setup"),
  ];

  if (type == WorkType.structure) {
    // Structure work: replace rate + dpr_setup with BOQ
    return [
      ...base,
      ModuleItem(
        labelKey: 'structure_boq_card', 
        icon: Icons.table_rows_rounded, 
        iconColor: const Color(0xFF7B3F00), 
        routeName: "/site-list/structure-boq",
      ),
    ];
  }

  // mechanical / insulation: keep rate + dpr_setup
  return [
    ...base,
    ModuleItem(labelKey: 'rate_card', icon: Icons.currency_rupee_rounded, iconColor: Colors.amber, routeName: "/site-list/rate"),
    ModuleItem(labelKey: 'dpr_setup_card', icon: Icons.settings_suggest_rounded, iconColor: Colors.blueGrey, routeName: "/site-list/addMoc"),
  ];
}
```

**Also update `_dailyEntryModules`:** For structure work, the DPR entry points to the structure DPR flow:

```dart
// DPR entry should always be present, but it routes differently based on type
// This is handled automatically by DprFlowGate (see section 8)
// No change needed in _dailyEntryModules list itself
```

**Also update `_reportModules`:** The `dpr_sheets_card` should route to the appropriate sheet download page. Since `SheetDownloadPage` already reads `typeProvider`, this works automatically. For structure work, you need to ensure `SheetDownloadPage` checks the type and calls structure-specific APIs (see Section 11).

---

## 8. DPR FLOW GATE — ADD STRUCTURE WORK [DONE]

In `dpr_flow_gate.dart`:

```dart
class DprFlowGate extends ConsumerWidget {
  final SiteModel site;
  const DprFlowGate({super.key, required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(typeProvider);
    final teamsCount = site.counts.teams;

    // Structure work has its own dedicated flow — always go direct
    if (type == WorkType.structure) {
      return DprStructureFlowGate(site: site);
    }

    if (teamsCount == 0) {
      return _buildDirectScreen(type);
    }
    return DprTeamScreen(site: site);
  }

  Widget _buildDirectScreen(WorkType? type) {
    if (type == WorkType.mechanical) {
      return MechanichalStepperScreen(siteId: site.id, teamId: "", teamName: null);
    }
    if (type == WorkType.insulation) {
      return StepInsulationScreen(siteId: site.id, teamId: "", name: site.siteName, teamName: null);
    }
    return const Scaffold(body: SizedBox.shrink());
  }
}
```

### `dpr_structure_flow_gate.dart`

```dart
class DprStructureFlowGate extends ConsumerWidget {
  final SiteModel site;
  const DprStructureFlowGate({super.key, required this.site});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Structure work DPR goes directly to the dashboard
    // which shows BOQ selection → item entry
    return DprStructureListScreen(siteId: site.id, siteName: site.siteName);
  }
}
```

---

## 9. ROUTER — SAFE ADDITIONS [DONE]

In `app_router.dart` (`appRouterProvider`), add these routes **inside the `routes: [...]` list**, after existing routes:

```dart
// ── Structure Work: BOQ ──────────────────────────────────────────────────────
GoRoute(
  path: '/site-list/structure-boq',
  builder: (context, state) {
    // Uses site-list dynamic route, handled in the existing 
    // '${Routes.siteList}/:module' builder with case 'structure-boq'
    // handled below — no separate top-level route needed
    // The SiteList builder switch already handles routing to BOQDashboard
    return const SizedBox.shrink(); // fallback, should not reach
  },
),

// ── Structure Work: DPR (direct deep-link if needed) ────────────────────────
GoRoute(
  path: '/structure-dpr/:siteId',
  builder: (context, state) {
    final siteId = state.pathParameters['siteId']!;
    final siteName = (state.extra as Map<String, dynamic>?)?['siteName'] ?? '';
    return DprStructureListScreen(siteId: siteId, siteName: siteName);
  },
),

// ── Structure Work: Sheet Download ──────────────────────────────────────────
GoRoute(
  path: Routes.structureReportDownload, // add to Routes class: '/structure-report'
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return StructureSheetDownloadPage(
      selectedStartDate: extra?['startDate'],
      selectedEndDate: extra?['endDate'],
    );
  },
),
```

**Also update the existing `'${Routes.siteList}/:module'` builder switch:**

```dart
case 'structure-boq':
  screen = BOQStructureDashboard(siteId: site.id, siteName: site.siteName);
  break;
```

**Add to `Routes` class:**
```dart
static const structureReportDownload = '/structure-report';
```

---

## 10. SCREEN IMPLEMENTATIONS — DETAILED SPEC [DONE]

### 10.1 `boq_structure_dashboard.dart`

**Purpose:** Shows all BOQs for a site. Primary entry for Structure Work setup.

**UI Requirements (PREMIUM — this is the hero screen):**
- Full-bleed gradient header with site name and a pulsing "Upload BOQ" FAB
- Stats row at top: Total BOQs | Total Items | Total Weight (animated counters on load)
- Each BOQ rendered as a **premium glass-morphism card** with:
  - BOQ name + number (top)
  - Animated circular progress indicator showing `progressPercentage`
  - Three mini-stats: Total Qty | Used Qty | Remaining Qty
  - Status chip (active = green, completed = blue, draft = grey)
  - Weight in MT formatted with 2 decimals
  - Tap → `BOQDetailScreen`
  - Long press → context menu (View Details / Delete)
- Empty state: Beautiful illustrated empty state with "Upload your first BOQ" CTA
- Pull-to-refresh
- Shimmer loading (use existing `ShimmerImage` widget)

**Upload BOQ flow:**
1. FAB tapped → bottom sheet appears
2. Bottom sheet shows: "Upload Excel File" card + file format info
3. Use `file_picker` package: `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx', 'xls'])`
4. After pick → show file name + size in bottom sheet
5. Confirm → call `boqStructureProvider.notifier.uploadBOQ(siteId, file)`
6. Loading overlay with progress text "Uploading BOQ..."
7. Success → dismiss, show snackbar with green tick, refresh list

### 10.2 `boq_detail_screen.dart`

**Purpose:** Shows all items in a BOQ.

**UI Requirements:**
- App bar with BOQ name + number
- Summary card at top: Total Items | Progress Bar | Total Weight
- Searchable/filterable item list
- Each item as an **expandable card** showing:
  - Assembly Mark (bold, large) + progress chip
  - Collapsed: Qty | Used | Remaining
  - Expanded: all dimensions (L × W × H) + weight per unit + total weight
  - Color-coded progress: green (>50%), amber (20-50%), red (<20%)
- Items sorted by `remainingQty DESC` by default
- Filter button: filter by assembly mark prefix

### 10.3 `dpr_structure_list_screen.dart`

**Purpose:** Shows all DPR entries + "Create DPR" button.

**UI Requirements:**
- Header with site name + date
- Date range filter chips (Today | This Week | This Month | Custom)
- BOQ filter dropdown
- DPR cards showing:
  - Date (formatted) + DPR number
  - BOQ name (linked)
  - Total Qty Used + Total Weight
  - Status badge (submitted/approved/rejected with color)
  - Swipe-to-delete with confirmation
  - Tap → detail screen
- FAB: "Add DPR" → `DprStructureCreateScreen`
- Empty state with illustration

### 10.4 `dpr_structure_create_screen.dart`

**Purpose:** Multi-step form to create a DPR entry.

**UI Requirements (multi-step, premium stepper):**

**Step 1 — Select BOQ:**
- Dropdown of all BOQs for site (load from provider)
- Show BOQ progress and remaining qty as subtitle
- Date picker (defaults to today)
- Optional team selector
- Optional remarks field

**Step 2 — Add Items:**
- Load BOQ items from `boqItemsProvider`
- Show items as a scrollable list
- Each item shows: Assembly Mark | Available Qty | input field for `qtyUsed`
- Input validation: `qtyUsed > 0` AND `qtyUsed <= availableQty`
- Running total at bottom: Total Qty This DPR | Total Weight
- Items with `availableQty == 0` shown greyed out (cannot select)
- Search/filter items by assembly mark

**Step 3 — Review & Submit:**
- Summary card
- List of items being submitted
- Total quantities
- "Submit DPR" button → loading → success animation → pop

### 10.5 `dpr_structure_detail_screen.dart`

**Purpose:** View a single DPR entry in full detail.

**UI Requirements:**
- Header: DPR name, date, status badge, created by
- BOQ reference card (tappable → BOQ detail)
- Items table: Assembly Mark | Qty Used | Weight
- Totals row at bottom
- Action bar: Edit (if submitted) | Delete (with confirmation dialog)
- Edit triggers `dpr_structure_create_screen` pre-filled

---

## 11. SHEET DOWNLOAD — STRUCTURE WORK [DONE]

The structure reporting is now integrated directly into the main `SheetDownloadPage` (`download_sheets.dart`) for a unified user experience.

1.  **Work Type Detection**: The page checks `typeProvider.state == 'structure_work'`.
2.  **Dynamic Report Grid**:
    *   **Structure Measurement Sheet** → `DPRStructureRepository().downloadSheet(siteId, sheetType: 'measurement', ...)`
    *   **Structure Abstract Sheet** → `sheetType: 'abstract'`
    *   **Structure Summary Sheet** → `sheetType: 'summary'`
    *   **Detailed DPR** → `sheetType: 'detailed'`, **Excel only**.
3.  **Unified Routing**: All DPR report requests route through `Routes.dprReportDownload`.

```dart
// In DPRStructureRepository:
Future<Uint8List> downloadSheet(String siteId, {
  required String fromDate,
  required String toDate,
  required String sheetType,
  required String format,
}) async {
  final res = await DioClient.dio.get(
    '/site/$siteId/structure-work/sheets',
    queryParameters: {
      'fromDate': fromDate,
      'toDate': toDate,
      'sheetType': sheetType,
      'format': format,
    },
    options: Options(responseType: ResponseType.bytes),
  );
  return Uint8List.fromList(res.data);
}
```

**Also update the existing `SheetDownloadPage`** (`download_sheets.dart`): When `type == 'structure_work'`, redirect to `StructureSheetDownloadPage` instead of showing mechanical/insulation sheets. Or better: in the `dprReport` router case, check type and route accordingly:

```dart
case 'dprReport':
  final type = container.read(typeProvider);
  if (type == WorkType.structure) {
    screen = DateRangeSelectionScreen(
      onDatesSelected: (start, end) => context.push(
        Routes.structureReportDownload,
        extra: {'startDate': start, 'endDate': end},
      ),
    );
  } else {
    screen = DateRangeSelectionScreen(
      onDatesSelected: (start, end) => context.push(
        Routes.dprReportDownload,
        extra: {'startDate': start, 'endDate': end},
      ),
    );
  }
  break;
```

---

## 12. LANGUAGE / TRANSLATION KEYS

Add these keys to the home language module (wherever `daily_entry_title`, `setup_title` etc. are defined):

```
structure_boq_card → "Structure BOQ"
structure_work_title → "Structure Work"
boq_upload_card → "Upload BOQ"
dpr_structure_card → "Structure DPR"
```

If using the existing `Translator` / `homeData` system, ensure these keys exist. If the language module doesn't support them yet, use hardcoded English strings for now with a `// TODO: i18n` comment.

---

## 13. ASSETS

Add an image for the Structure Work card. Options:
1. **Add asset:** `assets/images/structure.webp` — a construction/steel structure image
2. **Fallback network image:** Use `https://images.unsplash.com/photo-1587293852726-70cdb56c2866?w=600` (steel structure construction)

Update `pubspec.yaml` if adding local asset:
```yaml
assets:
  - assets/images/structure.webp
```

---

## 14. UI/UX DESIGN GUIDELINES — PREMIUM FEEL

The existing app already has a premium design system. Follow it strictly AND enhance it for Structure Work screens.

### Color Palette for Structure Work:
- **Primary accent:** `Color(0xFF7B3F00)` — rich amber/brown (steel/structure)
- **Secondary:** `Color(0xFFD4891A)` — warm gold
- **Progress high:** `Colors.green.shade600`
- **Progress mid:** `Colors.amber.shade600`
- **Progress low:** `Colors.red.shade400`

### Card Design Rules:
- Border radius: `22–28px` (consistent with existing CompanyCard)
- Subtle gradient: `cs.surface → cs.surfaceContainerLow`
- Border: `cs.outlineVariant.withOpacity(0.5)` 1px
- Shadow: `Colors.black.withOpacity(0.06)` blurRadius 16
- ALL cards use `AnimatedContainer` for state transitions

### Progress Indicators:
- Use `CircularProgressIndicator.adaptive` for item-level progress
- Use a custom `LinearProgressBar` widget with rounded ends and color interpolation for BOQ-level progress
- Animate from 0 to actual value on first load (use `TweenAnimationBuilder`)

### Loading States:
- ALWAYS show shimmer (use existing `ShimmerImage` widget)
- Never show a blank screen
- Shimmer must match the exact layout of the real content

### Error States:
- Use a consistent `_ErrorCard` widget: icon + message + retry button
- Never show raw error strings

### Empty States:
- Use illustrated empty states (can use Flutter's built-in `Icons` with large size + soft color)
- Always include a CTA button

### Animations:
- List items: staggered fade-in using `AnimationController` with `Interval`
- FAB: pulse animation (see existing `_pulseController` in ModuleScreenV2)
- Success: brief scale + check animation before popping

### Haptics:
- Add `HapticFeedback.lightImpact()` on card tap
- Add `HapticFeedback.mediumImpact()` on successful submit

---

## 15. ERROR HANDLING & OFFLINE SUPPORT

The existing `DioClient` has offline queue support. Structure work API calls go through the same `DioClient.dio`, so they automatically:
- Queue POST/PUT/DELETE calls when offline
- Retry when back online

For **GET calls** (reads), show cached data if available. Implement simple in-memory cache in providers:

```dart
// In BOQStructureNotifier:
List<BOQStructure>? _cache;

Future<void> fetchBOQs(String siteId) async {
  if (_cache != null) {
    state = state.copyWith(boqs: _cache!);
  }
  state = state.copyWith(isLoading: true);
  try {
    final boqs = await _repo.getAllBOQs(siteId);
    _cache = boqs;
    state = state.copyWith(boqs: boqs, isLoading: false, error: null);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}
```

Show "Offline — showing cached data" banner when `networkModeProvider.isOffline == true`.

---

## 16. IMPLEMENTATION ORDER (DO THIS SEQUENCE)

1. ✅ Create `WorkType` enum and update `typeProvider`
2. ✅ Create folder structure
3. ✅ Implement data models (BOQ + DPR)
4. ✅ Implement repositories (BOQ + DPR)  
5. ✅ Implement Riverpod providers
6. ✅ Add Structure Work card to `WorkCategoryScreen`
7. ✅ Update `ModuleScreenV2` setup modules (dynamic based on type)
8. ✅ Update `DprFlowGate` to handle structure type
9. ✅ Implement `DprStructureFlowGate`
10. ✅ Add router cases (`structure-boq`, `/structure-dpr/:siteId`, `structureReportDownload`)
11. ✅ Update `SiteList` module switch for `structure-boq`
12. ✅ Implement `BOQStructureDashboard` screen
13. ✅ Implement `BOQDetailScreen`
14. ✅ Implement `DprStructureListScreen`
15. ✅ Implement `DprStructureCreateScreen` (multi-step)
16. ✅ Implement `DprStructureDetailScreen`
17. ✅ Implement `StructureSheetDownloadPage`
18. ✅ Update `SheetDownloadPage` to route structure work correctly
19. ✅ Add assets + language keys

---

## 17. WHAT NOT TO DO

- ❌ Do NOT create separate DioClient instances — always use `DioClient.dio`
- ❌ Do NOT hardcode siteId — always read from `selectedSiteIdProvider` or pass through navigation extra
- ❌ Do NOT use `setState` in screens that should be driven by Riverpod — use `ConsumerStatefulWidget` only when local animation state is needed
- ❌ Do NOT duplicate the `SheetDownloadPage` download/share logic — extract it into a shared mixin or utility class `SheetDownloadMixin` that both `SheetDownloadPage` and `StructureSheetDownloadPage` use
- ❌ Do NOT use `print()` — use `debugPrint()`
- ❌ Do NOT block the main thread — all API calls are async
- ❌ Do NOT show raw Dio error messages to user — extract clean messages using the existing `extractBackendError()` utility

---

## 18. MIXIN SUGGESTION — SHEET DOWNLOAD

To avoid duplication between `SheetDownloadPage` and `StructureSheetDownloadPage`, extract shared logic:

```dart
// lib/core/utlis/mixins/sheet_download_mixin.dart
mixin SheetDownloadMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isLoading = false;
  bool isDownloading = false;
  String selectedFormat = 'excel';

  Future<void> handleDownload({
    required String sheetName,
    required Future<Uint8List> Function(String, String, String) apiCall,
    required String defaultFileName,
    required DateTime startDate,
    required DateTime endDate,
  }) async { /* shared impl */ }

  Future<void> downloadAndShare({...}) async { /* shared impl */ }
  Future<void> saveMobile(Uint8List bytes, String fileName) async { /* shared impl */ }
  Future<void> saveDesktop(Uint8List bytes, String fileName) async { /* shared impl */ }
  
  void showFormatDialog({...}) { /* shared impl */ }
  void showShareOrDownloadDialog({...}) { /* shared impl */ }
}
```

Both download pages then `with SheetDownloadMixin` and only define their own sheet buttons.

---

## 19. ROUTES CLASS ADDITIONS

In `lib/core/router/routes.dart`, add:

```dart
static const structureBoqList = '/structure-boq';
static const structureDpr = '/structure-dpr';
static const structureReportDownload = '/structure-report';
```

---

## 20. FINAL CHECKLIST

Before marking complete, verify:

- [ ] `WorkType.structure` routes correctly from `WorkCategoryScreen`
- [ ] `typeProvider` returns `WorkType.structure` when navigating to module screen
- [ ] `ModuleScreenV2` setup tab shows BOQ card (not rate/DPR setup) for structure work
- [ ] `ModuleScreenV2` setup tab shows rate + DPR setup for mechanical/insulation (no regression)
- [ ] DPR daily entry tap opens `DprStructureListScreen` for structure work
- [ ] DPR daily entry tap opens existing DPR flow for mechanical/insulation (no regression)
- [ ] BOQ upload (Excel) works with file picker and shows success feedback
- [ ] DPR create form validates `qtyUsed <= availableQty` before submit
- [ ] BOQ quantities update after DPR creation (verify by refreshing BOQ list)
- [ ] Sheet download works for all 4 types (measurement, abstract, summary, detailed)
- [ ] `detailed` sheet type correctly disables PDF format option
- [ ] Shimmer loading shown on all list screens before data loads
- [ ] Empty states shown when no BOQs or DPRs exist
- [ ] Pull-to-refresh works on all list screens
- [ ] Delete DPR shows confirmation dialog and restores BOQ quantities
- [ ] Offline: POST calls are queued (handled automatically by DioClient)
- [ ] No `print()` statements — only `debugPrint()`
- [ ] No hardcoded siteIds
- [ ] All `go_router` routes added and tested
- [ ] App builds without errors on `flutter build apk --debug`

---

## 21. KEY API ENDPOINTS QUICK REFERENCE

| Action | Method | Endpoint |
|---|---|---|
| List BOQs | GET | `/site/{siteId}/boq-structure` |
| BOQ Detail | GET | `/site/{siteId}/boq-structure/{boqId}` |
| BOQ Items | GET | `/site/{siteId}/boq-structure/{boqId}/items` |
| Upload BOQ Excel | POST | `/site/{siteId}/boq-structure/upload` (multipart) |
| Create DPR | POST | `/site/{siteId}/dpr-structure` |
| List DPRs | GET | `/site/{siteId}/dpr-structure` |
| DPR Detail | GET | `/site/{siteId}/dpr-structure/{dprId}` |
| Update DPR | PUT | `/site/{siteId}/dpr-structure/{dprId}` |
| Delete DPR | DELETE | `/site/{siteId}/dpr-structure/{dprId}` |
| Download Sheet | GET | `/site/{siteId}/structure-work/sheets?fromDate=&toDate=&sheetType=&format=` |

Sheet types: `measurement` | `abstract` | `summary` | `detailed`  
Formats: `pdf` | `excel` (`detailed` = Excel only)

---

*This prompt was generated with full analysis of the API documentation, DioClient, WorkCategoryScreen, ModuleScreenV2, DprFlowGate, SheetDownloadPage, and GoRouter. Every section is intentional. Do not skip sections.*