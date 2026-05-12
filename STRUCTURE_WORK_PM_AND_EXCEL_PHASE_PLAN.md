# Structure Work P&M Entry + Combined Excel Download Implementation Plan

This document explains how to implement the next Structure Work phase in the Flutter app, matching the current Next.js Structure Work functionality.

Scope:
- Add **P&M Database data entry** for Structure Work.
- Keep the P&M entry UI **same-to-same style** as the existing Structure DPR entry screen.
- Add report download for one combined Excel file containing:
  - `Detailed DPR`
  - `Date & Mark No wise Report`
  - `Direct Manpower`
  - `Indirect Manpower`
  - `P&M Database`
- Use dynamic backend data only. Do not hardcode generated Excel row values on Flutter side.

---

## 1. Current Flutter Structure Work Flow

### Existing module root

```text
lib/features/modules/all_Modules/structure_work/
```

### Existing main areas

```text
structure_work/
  boq/
  dpr/
  dpr_setup/
  reports/
```

### Existing DPR entry screen

```text
lib/features/modules/all_Modules/structure_work/dpr/screens/dpr_structure_create_screen.dart
```

This screen already handles:
- date selection
- DPR name
- plant/location/MOC inputs
- assembly mark cards
- BOQ auto-sync
- DPR create/update
- search/filter/sort
- same Structure Work visual language to reuse for P&M entry

### Existing DPR repository

```text
lib/features/modules/all_Modules/structure_work/dpr/repository/dpr_structure_repository.dart
```

Current sheet download method already supports dynamic sheet types:

```dart
Future<Uint8List> downloadSheet(
  String siteId, {
  required String fromDate,
  required String toDate,
  required String sheetType,
  required String format,
})
```

It calls:

```text
GET /site/{siteId}/structure-work/sheets?fromDate=&toDate=&sheetType=&format=
```

### Existing reports screen

```text
lib/features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart
```

For `type == 'structure_work'`, this screen currently shows:
- Measurement Sheet
- Abstract Sheet
- Summary Sheet
- Detailed DPR
- DPR List

Add the new combined Excel button here.

---

## 2. Backend API Contract To Use

The Flutter app should call the same APIs that are already used by the Next.js implementation.

Base URL is already configured in:

```text
lib/core/api/dio.dart
```

```dart
baseUrl: "https://be-vayuxi-chi.vercel.app/api/v1"
```

### 2.1 Get P&M Entry For Date

```http
GET /site/{siteId}/structure-work/pm-entry?date=YYYY-MM-DD
```

Example:

```text
GET /site/6a021b4b58541f7447153596/structure-work/pm-entry?date=2026-05-12
```

Expected response shape:

```json
{
  "success": true,
  "data": {
    "date": "2026-05-12",
    "rows": [
      {
        "_id": "resourceId",
        "unitCode": "Unit-01",
        "unitName": "Unit-01",
        "categoryName": "Crane",
        "resourceName": "Hydra Crane 12 MT",
        "uom": "Nos",
        "requiredQty": 1,
        "actualQty": 0,
        "gap": 1,
        "remarks": "",
        "templateRowNo": 1,
        "sortOrder": 1
      }
    ],
    "summary": {
      "totalRequired": 0,
      "totalActual": 0,
      "totalGap": 0,
      "totalCategories": 0,
      "totalResources": 0,
      "filledResources": 0,
      "pendingResources": 0,
      "unitSummary": [
        {
          "unitCode": "Unit-01",
          "unitName": "Unit-01",
          "required": 0,
          "actual": 0,
          "gap": 0
        }
      ]
    }
  }
}
```

Important:
- `rows` are resource master rows plus that date's saved actual quantity.
- `actualQty` must be editable in Flutter.
- `remarks` must be editable in Flutter.
- `gap = requiredQty - actualQty` should be displayed, but backend also returns it.

### 2.2 Save P&M Entry For Date

```http
POST /site/{siteId}/structure-work/pm-entry
```

Request body:

```json
{
  "date": "2026-05-12",
  "entries": [
    {
      "resourceId": "resourceId",
      "actualQty": 1,
      "remarks": "Working"
    }
  ]
}
```

Expected response:

```json
{
  "success": true,
  "message": "P&M entries saved successfully",
  "data": {
    "savedCount": 1
  }
}
```

### 2.3 Get P&M Resource Master

```http
GET /site/{siteId}/structure-work/pm-resources
```

Use this only if a separate master/resource view is needed. For normal P&M daily entry, `GET pm-entry?date=` is enough because it returns the full dynamic grid.

### 2.4 Combined Excel Download

```http
GET /site/{siteId}/structure-work/sheets?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD&sheetType=detailed-with-pm&format=excel
```

Example:

```text
GET /site/6a021b4b58541f7447153596/structure-work/sheets?fromDate=2026-05-01&toDate=2026-05-12&sheetType=detailed-with-pm&format=excel
```

The backend generates the workbook. Flutter only downloads the bytes.

Expected workbook sheets:

```text
Detailed DPR
Date & Mark No wise Report
Direct Manpower
Indirect Manpower
P&M Database
```

Important:
- This is Excel-only.
- Do not build this workbook in Flutter.
- The backend applies formulas, formatting, merged cells, date columns, manpower counts, P&M data, and DPR calculations.

---

## 3. Flutter Files To Add

Create a new `pm` folder under Structure Work:

```text
lib/features/modules/all_Modules/structure_work/pm/
  models/
    structure_pm_entry_model.dart
  repository/
    structure_pm_repository.dart
  providers/
    structure_pm_provider.dart
  screens/
    structure_pm_entry_screen.dart
  widgets/
    structure_pm_overview_card.dart
    structure_pm_unit_selector.dart
    structure_pm_resource_card.dart
    structure_pm_category_section.dart
```

Why separate from DPR folder:
- P&M entry is daily entry data, but not BOQ/DPR assembly mark data.
- Keeping it isolated avoids making `dpr_structure_create_screen.dart` too large.
- The UI can still match DPR entry styling.

---

## 4. Flutter Models

File:

```text
lib/features/modules/all_Modules/structure_work/pm/models/structure_pm_entry_model.dart
```

### 4.1 Resource Row Model

```dart
class StructurePmResourceRow {
  final String id;
  final String unitCode;
  final String unitName;
  final String categoryName;
  final String resourceName;
  final String uom;
  final double requiredQty;
  final double actualQty;
  final double gap;
  final String remarks;
  final int templateRowNo;
  final int sortOrder;

  const StructurePmResourceRow({
    required this.id,
    required this.unitCode,
    required this.unitName,
    required this.categoryName,
    required this.resourceName,
    required this.uom,
    required this.requiredQty,
    required this.actualQty,
    required this.gap,
    required this.remarks,
    required this.templateRowNo,
    required this.sortOrder,
  });

  factory StructurePmResourceRow.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StructurePmResourceRow(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      unitCode: (json['unitCode'] ?? '').toString(),
      unitName: (json['unitName'] ?? '').toString(),
      categoryName: (json['categoryName'] ?? '').toString(),
      resourceName: (json['resourceName'] ?? '').toString(),
      uom: (json['uom'] ?? '').toString(),
      requiredQty: toDouble(json['requiredQty']),
      actualQty: toDouble(json['actualQty']),
      gap: toDouble(json['gap']),
      remarks: (json['remarks'] ?? '').toString(),
      templateRowNo: int.tryParse((json['templateRowNo'] ?? 0).toString()) ?? 0,
      sortOrder: int.tryParse((json['sortOrder'] ?? 0).toString()) ?? 0,
    );
  }

  StructurePmResourceRow copyWith({
    double? actualQty,
    String? remarks,
  }) {
    final nextActual = actualQty ?? this.actualQty;
    return StructurePmResourceRow(
      id: id,
      unitCode: unitCode,
      unitName: unitName,
      categoryName: categoryName,
      resourceName: resourceName,
      uom: uom,
      requiredQty: requiredQty,
      actualQty: nextActual,
      gap: requiredQty - nextActual,
      remarks: remarks ?? this.remarks,
      templateRowNo: templateRowNo,
      sortOrder: sortOrder,
    );
  }
}
```

### 4.2 Summary Models

```dart
class StructurePmUnitSummary {
  final String unitCode;
  final String unitName;
  final double required;
  final double actual;
  final double gap;

  const StructurePmUnitSummary({
    required this.unitCode,
    required this.unitName,
    required this.required,
    required this.actual,
    required this.gap,
  });

  factory StructurePmUnitSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StructurePmUnitSummary(
      unitCode: (json['unitCode'] ?? '').toString(),
      unitName: (json['unitName'] ?? '').toString(),
      required: toDouble(json['required']),
      actual: toDouble(json['actual']),
      gap: toDouble(json['gap']),
    );
  }
}

class StructurePmSummary {
  final double totalRequired;
  final double totalActual;
  final double totalGap;
  final int totalCategories;
  final int totalResources;
  final int filledResources;
  final int pendingResources;
  final List<StructurePmUnitSummary> unitSummary;

  const StructurePmSummary({
    required this.totalRequired,
    required this.totalActual,
    required this.totalGap,
    required this.totalCategories,
    required this.totalResources,
    required this.filledResources,
    required this.pendingResources,
    required this.unitSummary,
  });

  factory StructurePmSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return StructurePmSummary(
      totalRequired: toDouble(json['totalRequired']),
      totalActual: toDouble(json['totalActual']),
      totalGap: toDouble(json['totalGap']),
      totalCategories: int.tryParse((json['totalCategories'] ?? 0).toString()) ?? 0,
      totalResources: int.tryParse((json['totalResources'] ?? 0).toString()) ?? 0,
      filledResources: int.tryParse((json['filledResources'] ?? 0).toString()) ?? 0,
      pendingResources: int.tryParse((json['pendingResources'] ?? 0).toString()) ?? 0,
      unitSummary: ((json['unitSummary'] as List?) ?? [])
          .map((e) => StructurePmUnitSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static const empty = StructurePmSummary(
    totalRequired: 0,
    totalActual: 0,
    totalGap: 0,
    totalCategories: 0,
    totalResources: 0,
    filledResources: 0,
    pendingResources: 0,
    unitSummary: [],
  );
}
```

### 4.3 Entry Response Model

```dart
class StructurePmEntryData {
  final String date;
  final List<StructurePmResourceRow> rows;
  final StructurePmSummary summary;

  const StructurePmEntryData({
    required this.date,
    required this.rows,
    required this.summary,
  });

  factory StructurePmEntryData.fromJson(Map<String, dynamic> json) {
    return StructurePmEntryData(
      date: (json['date'] ?? '').toString(),
      rows: ((json['rows'] as List?) ?? [])
          .map((e) => StructurePmResourceRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: StructurePmSummary.fromJson(
        (json['summary'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}
```

---

## 5. P&M Repository

File:

```text
lib/features/modules/all_Modules/structure_work/pm/repository/structure_pm_repository.dart
```

```dart
import 'package:untitled2/core/api/dio.dart';
import '../models/structure_pm_entry_model.dart';

class StructurePmRepository {
  Future<StructurePmEntryData> getEntry(
    String siteId, {
    required String date,
  }) async {
    final res = await DioClient.dio.get(
      '/site/$siteId/structure-work/pm-entry',
      queryParameters: {'date': date},
    );

    return StructurePmEntryData.fromJson(
      res.data['data'] as Map<String, dynamic>,
    );
  }

  Future<bool> saveEntry(
    String siteId, {
    required String date,
    required List<StructurePmResourceRow> rows,
  }) async {
    final entries = rows
        .where((row) => row.actualQty > 0 || row.remarks.trim().isNotEmpty)
        .map((row) => {
              'resourceId': row.id,
              'actualQty': row.actualQty,
              'remarks': row.remarks.trim(),
            })
        .toList();

    final res = await DioClient.dio.post(
      '/site/$siteId/structure-work/pm-entry',
      data: {
        'date': date,
        'entries': entries,
      },
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }
}
```

Notes:
- Use `DioClient.dio`, not a new Dio instance.
- Auth token is already injected by the interceptor.
- Keep endpoint names exactly as above.

---

## 6. P&M Riverpod Provider

File:

```text
lib/features/modules/all_Modules/structure_work/pm/providers/structure_pm_provider.dart
```

### State fields

```dart
class StructurePmState {
  final DateTime selectedDate;
  final List<StructurePmResourceRow> rows;
  final StructurePmSummary summary;
  final String? selectedUnitCode;
  final bool isLoading;
  final bool isSaving;
  final String? error;
}
```

### Provider behavior

Add methods:

```dart
Future<void> load(String siteId, DateTime date)
void setDate(DateTime date)
void setSelectedUnit(String? unitCode)
void updateActualQty(String resourceId, double actualQty)
void updateRemarks(String resourceId, String remarks)
Future<bool> save(String siteId)
void clearError()
```

### Date formatting helper

Use backend format:

```dart
String formatApiDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
```

### Important provider logic

When updating actual qty:
- find by `resourceId`
- update only that row
- recalculate `gap = requiredQty - actualQty`
- recalculate local summary so UI changes immediately

When saving:
- send all changed/non-empty rows
- after save, reload from backend for the selected date

---

## 7. P&M Entry UI Design

File:

```text
lib/features/modules/all_Modules/structure_work/pm/screens/structure_pm_entry_screen.dart
```

The visual style must match:

```text
lib/features/modules/all_Modules/structure_work/dpr/screens/dpr_structure_create_screen.dart
```

Reuse these design patterns:
- `Scaffold` with `CustomDrawer`
- `CustomSliverAppBar`
- `BottomButtonWrapper`
- `RoundedButton`
- 12px page padding
- date selector container like `_buildDateSection`
- main cards with `borderRadius: BorderRadius.circular(16)` and soft shadow
- input height `44`
- action buttons `48 x 48`
- same color scheme usage from `Theme.of(context).colorScheme`

### 7.1 P&M Screen Layout

```text
CustomSliverAppBar(title: siteName or "P&M Entry")
  ↓
LinearProgressIndicator when loading/saving
  ↓
SingleChildScrollView padding 12
  ↓
Header row
  - site name
  - "Structure P&M Database"
  - refresh icon button
  ↓
Date section
  - title: "P&M Daily Entry"
  - selected date chip
  ↓
Overview card
  - Total Required
  - Total Actual
  - Total Gap
  - Total Resources
  - Filled
  - Pending
  ↓
Unit selector row
  - All
  - Unit-01
  - Unit-02
  - Unit-03
  - Unit-04
  ↓
Search box
  ↓
Category sections
  - Category title
  - Resource rows/cards
  ↓
Bottom save button: "Save P&M Entry"
```

### 7.2 Overview Boxes

Create widget:

```text
structure_pm_overview_card.dart
```

Cards should be same height and box style. Recommended metrics:

```text
Total Required
Total Actual
Total Gap
Resources
Filled
Pending
Categories
```

Use a responsive wrap/grid so text does not overflow on mobile.

### 7.3 Unit Selector

Create widget:

```text
structure_pm_unit_selector.dart
```

Behavior:
- `All` shows all rows.
- Unit tabs filter rows by `unitCode`.
- Show unit actual/required/gap in each unit chip if space allows.
- Use horizontal scrolling chips/cards.

### 7.4 Resource Entry Row/Card

Create widget:

```text
structure_pm_resource_card.dart
```

Fields shown per resource:

```text
Resource Name
Category Name
UOM
Required Qty
Actual Qty input
Gap
Remarks input
```

Input rules:
- `Actual Qty`: numeric keyboard, allow decimal.
- `Remarks`: text input.
- Gap color:
  - green when `gap <= 0`
  - amber/red when `gap > 0`

### 7.5 Category Grouping

Create widget:

```text
structure_pm_category_section.dart
```

Group by:

```dart
row.categoryName
```

Sort order:
1. `unitCode`
2. `templateRowNo`
3. `sortOrder`
4. `resourceName`

---

## 8. Where To Add P&M Entry In Navigation

The user asked for P&M Database data entry inside Structure Work DPR entry/module flow.

Recommended implementation:

### Option A: Add P&M entry card in Structure module daily entry

In the Structure Work module screen, add one Daily Entry card:

```text
P&M Database Entry
```

Route:

```text
/site-list/structure-pm-entry
```

Screen:

```dart
StructurePmEntryScreen(siteId: siteId, siteName: siteName)
```

This is cleaner than putting P&M inside `DprStructureCreateScreen`, because DPR assembly entry and P&M resource entry are separate daily forms.

### Option B: Add a tab inside Structure DPR entry

If the UI must be inside the same screen, use two tabs:

```text
DPR Entry | P&M Database
```

Keep `DprStructureCreateScreen` as the parent and render `StructurePmEntryScreen` content in the second tab.

Recommended: **Option A first**, because it is safer and keeps each screen smaller.

---

## 9. Router Changes

Add route constant:

```text
lib/core/router/routes.dart
```

```dart
static const String structurePmEntry = '/structure-pm-entry';
```

Add route in:

```text
lib/core/router/app_router.dart
```

```dart
GoRoute(
  path: Routes.structurePmEntry,
  builder: (context, state) {
    final siteId = state.uri.queryParameters['siteId'] ?? '';
    final siteName = state.uri.queryParameters['siteName'] ?? '';
    return StructurePmEntryScreen(
      siteId: siteId,
      siteName: siteName,
    );
  },
)
```

If your current route style passes site data differently, follow the existing Structure DPR route pattern instead of this query example.

---

## 10. Add Combined Excel Button

File:

```text
lib/features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart
```

Inside the `type == 'structure_work'` GridView, add this card after `Detailed DPR`:

```dart
sheetButton(
  label: "Detailed + Mark + Manpower + P&M",
  icon: Icons.assignment_turned_in_rounded,
  sheetName: "Structure Detailed DPR With P&M",
  excelOnly: true,
  apiCall: (fromDate, toDate, format) =>
      DPRStructureRepository().downloadSheet(
    siteId,
    fromDate: fromDate,
    toDate: toDate,
    sheetType: 'detailed-with-pm',
    format: 'excel',
  ),
  defaultFileName: "structure_detailed_with_pm",
),
```

Important:
- Force `format: 'excel'`.
- Keep `excelOnly: true`.
- Use both `fromDate` and `toDate` from the existing date range selector.

---

## 11. Excel Data Responsibility

Flutter should not calculate workbook rows.

### Backend owns:

```text
Detailed DPR sheet formatting
Detailed DPR formulas
Date & Mark No wise Report
Direct Manpower sheet
Indirect Manpower sheet
P&M Database sheet
Excel merged cells
Excel styles
Excel formulas
Excel sheet order
```

### Flutter owns:

```text
Date range selection
Calling download endpoint
Saving/sharing bytes
Showing loading/error UI
```

This is important because Excel desktop can show repair warnings if mobile/client code writes partial Excel. The backend must produce one valid `.xlsx` file, and Flutter should save the binary exactly as received.

---

## 12. Manpower Data Rule

Do not create a new manpower API for this phase.

The combined Excel backend uses existing data:
- existing `manpowers` collection
- existing `attendances` collection
- `type: structure_work`
- `siteId`
- `company`
- date range: `fromDate` to `toDate`

Designation matching is done backend-side against static direct/indirect designation lists.

Flutter only passes:

```text
fromDate
 toDate
 sheetType=detailed-with-pm
 format=excel
```

---

## 13. P&M Data Storage Rule

P&M daily entries are stored in backend DB, not locally only.

### Resource master

Backend collection stores resource configuration:

```text
company
siteId
unitCode
unitName
categoryName
resourceName
uom
requiredQty
templateRowNo
sortOrder
isDefault
isActive
```

### Daily entry

Backend collection stores date-wise actual data:

```text
company
siteId
resourceId
entryDate
actualQty
remarks
```

Flutter must not seed static P&M rows locally. It must read from:

```text
GET /pm-entry?date=YYYY-MM-DD
```

---

## 14. Validation Rules

### P&M entry screen

Before save:
- siteId is required
- selected date is required
- actual qty must be `>= 0`
- remarks can be empty
- allow saving even when all actual qty are zero, but show confirmation if needed

### Download screen

Before download:
- start date is required
- end date is required
- end date must not be before start date
- for combined workbook, use Excel only

Existing `SheetDownloadPage` already checks start and end dates. Keep that behavior.

---

## 15. Error Handling

### P&M entry errors

Show toast/snackbar for:
- load failed
- save failed
- invalid number
- empty master rows

Empty state message:

```text
No P&M resources found for this site.
```

This usually means backend resource master is not seeded for the selected site/company.

### Download errors

Use current download failure UI, but improve message if possible:

```text
Could not download the workbook. Please check selected date range and try again.
```

Do not show generic `Data not available` when the real issue is a file/server error.

---

## 16. Implementation Order

1. Add P&M models.
2. Add P&M repository.
3. Add P&M provider/state notifier.
4. Build P&M entry screen with same DPR design tokens.
5. Add route/navigation card for P&M Database Entry.
6. Add combined Excel button in `download_sheets.dart`.
7. Test P&M load with a date.
8. Save actual quantity and remarks.
9. Reload same date and verify values persist.
10. Download combined Excel with start/end date.
11. Open Excel and verify all sheets are visible:
    - `Detailed DPR`
    - `Date & Mark No wise Report`
    - `Direct Manpower`
    - `Indirect Manpower`
    - `P&M Database`

---

## 17. Acceptance Checklist

### P&M Entry

- [ ] P&M entry screen opens for selected Structure Work site.
- [ ] Screen uses the same visual style as Structure DPR entry.
- [ ] Date selector loads date-wise P&M rows.
- [ ] Overview boxes show dynamic summary.
- [ ] Unit selector filters dynamic rows.
- [ ] Category/resource list is dynamic from API.
- [ ] Actual qty can be edited.
- [ ] Remarks can be edited.
- [ ] Save sends data to backend.
- [ ] Reload same date shows saved values.
- [ ] No static P&M actual data is hardcoded in Flutter.

### Combined Excel Download

- [ ] Button appears in Structure Work report sheet screen.
- [ ] Button is Excel-only.
- [ ] Start date and end date are both sent.
- [ ] API uses `sheetType=detailed-with-pm`.
- [ ] Downloaded file opens without repair warning.
- [ ] Workbook includes all five sheets.
- [ ] `P&M Database` sheet shows dynamic saved P&M entries.
- [ ] `Direct Manpower` and `Indirect Manpower` sheets use attendance counts.
- [ ] `Detailed DPR` formulas/calculations are visible in Excel.

---

## 18. Minimal Code Touch List

### Add files

```text
lib/features/modules/all_Modules/structure_work/pm/models/structure_pm_entry_model.dart
lib/features/modules/all_Modules/structure_work/pm/repository/structure_pm_repository.dart
lib/features/modules/all_Modules/structure_work/pm/providers/structure_pm_provider.dart
lib/features/modules/all_Modules/structure_work/pm/screens/structure_pm_entry_screen.dart
lib/features/modules/all_Modules/structure_work/pm/widgets/structure_pm_overview_card.dart
lib/features/modules/all_Modules/structure_work/pm/widgets/structure_pm_unit_selector.dart
lib/features/modules/all_Modules/structure_work/pm/widgets/structure_pm_resource_card.dart
lib/features/modules/all_Modules/structure_work/pm/widgets/structure_pm_category_section.dart
```

### Modify files

```text
lib/core/router/routes.dart
lib/core/router/app_router.dart
lib/features/modules/screen/module_screen_v2.dart
lib/features/modules/all_Modules/dpr/dpr_report/screens/download_sheets.dart
```

Optional if you choose tab-based integration:

```text
lib/features/modules/all_Modules/structure_work/dpr/screens/dpr_structure_create_screen.dart
```

---

## 19. Final Notes

The safest implementation is:
- P&M entry as a new Structure Work daily entry screen.
- Combined workbook as a new Excel-only report button.
- All Excel generation stays backend-side.
- Flutter only handles data entry and byte download.

This keeps the Flutter implementation simple, avoids Excel corruption, and matches the Next.js architecture already built for Structure Work.
