# VAYUXI ERP — Frontend + Backend Improvement Plan

---

## Issues Identified

### Issue 1: Category Selection Screen Order is Wrong

**Current order** (defined by `WorkType` enum in `lib/typeProvider/work_type.dart`):
1. Mechanical
2. Insulation
3. Structure (Erection)
4. Civil
5. Roofing
6. Fabrication

**Required order** (matches actual site execution workflow):
1. Mechanical
2. Insulation
3. Structural Fabrication
4. Structural Erection
5. Civil
6. Roofing

**Why it matters:**
This order matches actual site execution workflow and improves user familiarity during onboarding. Workers expect to see categories in the order they encounter them on-site.

**Root Cause:**
The `_CategorySpotlightCard` widget in `lib/work_cat.dart` (line 1112) iterates `WorkType.values` directly:
```dart
itemCount: WorkType.values.length,
itemBuilder: (context, index) {
  final type = WorkType.values[index];
```
The enum declaration order in `lib/typeProvider/work_type.dart` IS the display order.

---

### Issue 2: Notification & Sync System Creates Unnecessary Frustration

**Current Problem:**
Users continuously see "Syncing Data" messages even when there is no actual issue. The system has a triple-notification pattern:
1. `GlobalSyncBanner` (always visible overlay) — shows for running, success, AND failed states
2. `NotificationIngestionService` — creates persistent in-app notifications for EVERY sync state (queued, running, success, failed)
3. `showSnackBar` calls — 321 instances across 76 files showing redundant messages

**Problematic Files:**
- `lib/core/api/global_sync_banner.dart` — Shows banner for running + success + failed (lines 21-25)
- `lib/core/api/sync_job.dart` — `success()` shows "Done" for 2s, `allDone()` shows "All changes synced" for 2s
- `lib/core/api/syncManager.dart` — Triggers sync jobs provider on every state change
- `lib/features/noti_system/updates/domain/services/notification_ingestion_service.dart` — Creates persistent notification for every sync event
- `lib/core/upload/ui/upload_banner.dart` — Full banner + floating ball for uploads
- `lib/features/tour/screen/global_tour_overlay.dart` — Mounts both GlobalSyncBanner AND GlobalUploadBanner on every screen

**Required Behavior:**
- Silent background sync — no popups during normal operation
- Show notification ONLY when user action is required
- If network unavailable: show simple message "Low network detected. Your entry has been saved in Draft."
- Auto-detect module (Attendance, DPR, Expense, Inventory)
- Once network restored: auto-sync silently, remove draft notification automatically
- Do NOT show "Data Saved", "Sync Successful", or "Uploading" messages repeatedly

---

### Issue 3: Navigation Sections Hidden When Data is Unavailable

**Current Problem:**
The app hides navigation items/sections when no data exists, breaking user memory mapping.

**Problematic Code:**
In `lib/features/modules/screen/module_screen_v2.dart` (line 1626):
```dart
children: _currentModules
    .where((m) => !m.isEmpty)
    .map((item) => _buildModuleIconItem(item, itemWidth, t))
    .toList(),
```

Also in `_setupModules` (line 385):
```dart
if (secondaryModule != null) secondaryModule,
```
This conditionally hides Rate/BOQ based on work type instead of always showing them.

**Required Behavior:**
- All navigation sections must ALWAYS be visible regardless of data availability
- If no data exists, show the section with message like "No Rates Added" — NOT hide it
- Same applies to: Reports, Inventory, Team, Daily Entries, Setup Modules
- Bottom nav (Daily Entry / Setup / Reports / More) must never hide tabs

**Mandatory Setup Structure (always visible):**
- Site
- Rate
- Manpower
- Team
- DPR Setup
- Inventory Setup

**Mandatory Main Navigation (always visible):**
- Daily Entry
- Setup
- Reports
- More

---

### Issue 4: UI/UX Language Too Corporate for Site Workers

**Current Problem:**
- Module icons are 52x52px (too small for outdoor use with gloves)
- Font sizes go down to 10px (unreadable in sunlight)
- 321 `showSnackBar` calls use technical language
- Complex terminology and corporate dashboard styling
- Overloaded screens with too many decision points

**Required Direction:**
- Site-friendly, fast to understand, low-literacy compatible, action-oriented
- Simple labels, recognizable icons, clear CTA buttons
- Large tap targets (minimum 64px), minimum 13px font size
- Minimal decision-making steps
- Must be usable by: labour supervisors, foremen, site engineers, semi-skilled workers

---

## Implementation Phases

---

## Phase 1 — Category Order Fix + Silence Noisy Sync

> Low risk, high impact. Can be done immediately without breaking anything.

---

### 1.1 Reorder WorkType Enum

**File:** `lib/typeProvider/work_type.dart`

**Current code (line 3-9):**
```dart
enum WorkType {
  mechanical,
  insulation,
  structure,
  civil,
  roofing,
  fabrication;
```

**Change to:**
```dart
enum WorkType {
  mechanical,
  insulation,
  fabrication,
  structure,
  civil,
  roofing;
```

**Why:** The `_CategorySpotlightCard` in `lib/work_cat.dart` uses `WorkType.values[index]` — so enum order = display order. No other code changes needed.

---

### 1.2 Update Display Names for Clarity

**File:** `lib/typeProvider/work_type.dart`

**Change `displayName` getter:**
```dart
String get displayName {
  switch (this) {
    case WorkType.mechanical:
      return 'Mechanical Work';
    case WorkType.insulation:
      return 'Insulation Work';
    case WorkType.structure:
      return 'Structural Erection';
    case WorkType.civil:
      return 'Civil Work';
    case WorkType.roofing:
      return 'Roofing Work';
    case WorkType.fabrication:
      return 'Structural Fabrication';
  }
}
```

No change needed here — names are already correct. Just verify after reorder.

---

### 1.3 Stop Showing Sync Banner for Success Status

**File:** `lib/core/api/global_sync_banner.dart`

**Current code (lines 21-25):**
```dart
final visible = jobs.where((j) =>
    j.status == SyncJobStatus.running ||
    j.status == SyncJobStatus.success ||
    j.status == SyncJobStatus.failed
).toList();
```

**Change to:**
```dart
final visible = jobs.where((j) =>
    j.status == SyncJobStatus.failed
).toList();
```

**Why:** Users should only see the banner when something actually failed and needs their attention. Running and success states should be silent.

---

### 1.4 Remove "All changes synced" Popup

**File:** `lib/core/api/sync_job.dart`

**Current code (lines 115-128):**
```dart
void allDone() {
  state = [
    const SyncJob(
      id: "done",
      label: "All changes synced",
      status: SyncJobStatus.success,
      message: "All changes synced",
    )
  ];

  Future.delayed(const Duration(seconds: 2), () {
    state = [];
  });
}
```

**Change to:**
```dart
void allDone() {
  state = [];
}
```

**Why:** No need to show "All changes synced" — success should be silent.

---

### 1.5 Stop Persisting Success/Running Notifications

**File:** `lib/features/noti_system/updates/domain/services/notification_ingestion_service.dart`

**Remove/no-op these methods:**
- `persistSyncSuccess` (lines 44-65) — Change to just delete the queued notification instead of creating a new "success" one
- `persistSyncRunning` (lines 67-87) — No-op this method, running state doesn't need a notification

**Keep these methods:**
- `persistQueuedRequest` — Important: tells user their data is saved offline
- `persistSyncRetryFailed` — Important: tells user there's an issue

**In `lib/core/api/syncManager.dart`, update `_retryQueuedRequests()`:**
- Remove line 168: `await NotificationIngestionService.persistSyncRunning(req);`
- Change line 197: `await NotificationIngestionService.persistSyncSuccess(req);` to instead DELETE the queued notification: `await _repository.deleteNotification('sync_${req.id}');`

---

### 1.6 Simplify Success Sync Job to Immediate Removal

**File:** `lib/core/api/sync_job.dart`

**Current code (lines 68-82):**
```dart
void success(String id) {
  state = [
    for (final j in state)
      if (j.id == id)
        j.copyWith(
          status: SyncJobStatus.success,
          message: "Done",
        )
      else
        j
  ];
  Future.delayed(const Duration(seconds: 2), () {
    remove(id);
  });
}
```

**Change to:**
```dart
void success(String id) {
  remove(id);
}
```

**Why:** No need to show success for 2 seconds. Just silently remove from state.

---

## Phase 2 — Navigation Persistence (Never Hide Sections)

> Ensures all modules are always visible. Users always know where everything is.

---

### 2.1 Remove isEmpty Filter from Icon Grid

**File:** `lib/features/modules/screen/module_screen_v2.dart`

**Current code (line 1624-1628):**
```dart
children: _currentModules
    .where((m) => !m.isEmpty)
    .map((item) => _buildModuleIconItem(item, itemWidth, t))
    .toList(),
```

**Change to:**
```dart
children: _currentModules
    .map((item) => _buildModuleIconItem(item, itemWidth, t))
    .toList(),
```

**Also update line 783:**
```dart
int rows = (currentModules.where((m) => !m.isEmpty).length / 4).ceil();
```
**Change to:**
```dart
int rows = (currentModules.length / 4).ceil();
```

**Also update line 979:**
```dart
"${_currentModules.where((m) => !m.isEmpty).length} modules",
```
**Change to:**
```dart
"${_currentModules.length} modules",
```

---

### 2.2 Always Include Rate/BOQ Module in Setup (All Work Types)

**File:** `lib/features/modules/screen/module_screen_v2.dart`

**Current `_setupModules` (lines 383-387):**
```dart
return [
  ...base,
  if (secondaryModule != null) secondaryModule,
  dprSetupModule,
];
```

**Change to always include the secondary module:**
```dart
return [
  ...base,
  _getSecondaryModule(type) ?? ModuleItem(
    labelKey: 'rate_card',
    icon: Icons.currency_rupee_rounded,
    iconColor: Colors.amber,
    routeName: "/site-list/rate",
  ),
  dprSetupModule,
];
```

**Why:** Rate/BOQ should always be visible. If no rates exist, the rate screen itself should show "No Rates Added" — not hide the entire entry point.

---

### 2.3 Create Reusable Empty State Widget

**New File:** `lib/core/utlis/widgets/empty_module_state.dart`

```dart
import 'package:flutter/material.dart';

class EmptyModuleState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyModuleState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(180, 52),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

### 2.4 Apply Empty States to All Module Screens

For each module screen that currently shows blank/error when no data:

**Rate screen** — Show: `EmptyModuleState(title: "No Rates Added", subtitle: "Add your first rate to get started", icon: Icons.currency_rupee_rounded)`

**Team screen** — Show: `EmptyModuleState(title: "No Teams Created", subtitle: "Create your first team to organize manpower", icon: Icons.groups_rounded)`

**Inventory screen** — Show: `EmptyModuleState(title: "No Inventory Items", subtitle: "Add materials to start tracking inventory", icon: Icons.inventory_2_rounded)`

**Reports screen** — Show: `EmptyModuleState(title: "No Reports Available", subtitle: "Complete daily entries to generate reports", icon: Icons.analytics_rounded)`

**DPR screen** — Show: `EmptyModuleState(title: "No DPR Entries", subtitle: "Start adding daily progress to see entries here", icon: Icons.description_rounded)`

**Files to update:**
- `lib/features/modules/all_Modules/rate/screens/rate.dart`
- `lib/features/modules/all_Modules/team/screens/teamsList.dart`
- `lib/features/modules/all_Modules/inventory/screens/` (multiple files)
- `lib/features/modules/all_Modules/dpr/screens/dprDetails.dart`
- `lib/features/modules/all_Modules/expense/screens/expense_screen.dart`
- All report screens under `lib/features/modules/all_Modules/`

---

### 2.5 Ensure Bottom Nav Tabs Never Hide

**File:** `lib/features/modules/screen/module_screen_v2.dart`

Verify that `_handleBottomNavTap` and `_buildTabPills` never conditionally hide any of the 4 tabs (Daily, Setup, Reports, More). Currently they don't hide — they just gate behind access control. This is acceptable behavior. No code change needed, just verify.

---

## Phase 3 — Silent Background Sync Architecture

> Complete overhaul of the notification philosophy.

---

### 3.1 Redesign GlobalSyncBanner — Show Only on Actionable Failures

**File:** `lib/core/api/global_sync_banner.dart`

Replace the entire widget logic:

**New behavior:**
- ONLY show when `SyncJobStatus.failed` AND the failure requires user attention (e.g., auth expired, server rejected data)
- Show a simple, non-intrusive inline banner (not floating overlay)
- Include a "Retry" button
- Auto-dismiss after successful retry

**Key change in build method:**
```dart
final visible = jobs.where((j) => j.status == SyncJobStatus.failed).toList();
if (visible.isEmpty) return const SizedBox.shrink();
```

---

### 3.2 Add User-Friendly "Low Network" Notification

**File:** `lib/core/api/network_mode.dart`

When `NetworkMode` transitions to `suggestedOffline` or `offline`, emit a single notification:

**Message:** "Low network detected. Your entry has been saved in Draft."

**Implementation:**
In `NetworkModeNotifier.switchToOffline()` — trigger a single draft notification via `NotificationIngestionService`.

**New method to add in `notification_ingestion_service.dart`:**
```dart
static Future<void> persistNetworkDraftNotification(String moduleName) async {
  final now = DateTime.now();
  final model = NotificationModel(
    id: 'network_draft_${now.millisecondsSinceEpoch}',
    type: NotificationType.update,
    title: 'Low network detected',
    description: 'Your $moduleName entry has been saved in Draft. It will sync automatically when network is back.',
    timestamp: now,
    priority: NotificationPriority.medium,
    metadata: {
      'source': 'network_mode',
      'module': moduleName,
    },
  );
  await _repository.addNotification(model);
}
```

---

### 3.3 Auto-Detect Module Context in Draft Notification

**File:** `lib/features/noti_system/updates/domain/services/notification_ingestion_service.dart`

The existing `_humanTaskLabel` method (lines 220-244) already detects modules from API path:
```dart
if (lower.contains('dpr')) section = 'daily progress update';
if (lower.contains('site')) section = 'site details';
if (lower.contains('manpower')) section = 'manpower entry';
if (lower.contains('rate')) section = 'rate entry';
if (lower.contains('team')) section = 'team details';
if (lower.contains('expense')) section = 'expense entry';
if (lower.contains('inventory')) section = 'inventory entry';
```

**Enhancement:** Add attendance detection:
```dart
if (lower.contains('attendance')) section = 'attendance entry';
```

Use this label in the draft notification message so users see "Your attendance entry has been saved in Draft" instead of generic text.

---

### 3.4 Auto-Dismiss Draft Notification on Sync Success

**File:** `lib/core/api/syncManager.dart`

In `_retryQueuedRequests()`, after successful sync:

**Current (line 197):**
```dart
await NotificationIngestionService.persistSyncSuccess(req);
```

**Change to:**
```dart
await LocalNotificationRepository().deleteNotification('sync_${req.id}');
```

This silently removes the "saved in draft" notification without creating a new "success" notification.

---

### 3.5 Audit and Remove Unnecessary SnackBar Messages

**Scope:** 76 files, 321 `showSnackBar` calls

**Rules for what to KEEP:**
- Error messages that require user action (validation errors, auth failures)
- Destructive action confirmations (delete confirmations)
- User-initiated action results (e.g., "Copied to clipboard")

**Rules for what to REMOVE:**
- "Data Saved" / "Data Saved Successfully"
- "Sync Successful" / "Synced"
- "Uploading..." / "Upload Complete"
- "Loading..." / "Fetching data"
- Any automatic background operation status

**Priority files to audit first (highest SnackBar count):**
1. `lib/features/modules/all_Modules/dpr/screens/widgets/all_material.dart` — 25 calls
2. `lib/features/modules/all_Modules/dpr/screens/add_description.dart` — 22 calls
3. `lib/features/modules/all_Modules/dpr/dpr_insu/screens/testing.dart` — 20 calls
4. `lib/features/modules/all_Modules/dpr/screens/asf.dart` — 19 calls
5. `lib/features/modules/all_Modules/dpr/screens/dprDetails.dart` — 14 calls

---

### 3.6 Replace Popup Feedback with Inline State Indicators

**Concept:**
Instead of showing SnackBars/toasts after save:
- Show a small checkmark icon next to the save button for 1.5 seconds
- Use button state: "Save" → spinning indicator → checkmark icon (no text popup)
- For draft state: show a subtle "Draft" chip near the form title

**Implementation pattern:**
```dart
// Instead of:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Saved successfully')),
);

// Use inline state:
setState(() => _saveState = SaveState.success);
Future.delayed(Duration(seconds: 1.5), () {
  if (mounted) setState(() => _saveState = SaveState.idle);
});
```

---

## Phase 4 — UI/UX Simplification for Site Workers

> Make the app feel like a practical site tool, not enterprise office software.

---

### 4.1 Increase Tap Targets

**File:** `lib/features/modules/screen/module_screen_v2.dart`

**Current (line 1652-1653):**
```dart
Container(
  width: 52,
  height: 52,
```

**Change to:**
```dart
Container(
  width: 64,
  height: 64,
```

**Also update all button heights across the app to minimum 48px.**

---

### 4.2 Increase Minimum Font Sizes

**Global rule:** No text smaller than 13px anywhere in the app.

**Files to update:**
- `lib/features/modules/screen/module_screen_v2.dart` — line 1674: change `fontSize: 10` → `fontSize: 13`
- `lib/work_cat.dart` — multiple instances of `fontSize: 11`, `fontSize: 10.5`
- All module screens with small labels

**Recommended theme-level change in app theme:**
```dart
textTheme: TextTheme(
  labelSmall: TextStyle(fontSize: 13), // was 11
  bodySmall: TextStyle(fontSize: 14),  // was 12
)
```

---

### 4.3 Simplify Labels (Translation Keys)

**Files:** Language/translation JSON files in `lib/features/language/`

**Examples of simplification:**
| Current Key | Current Label | Simplified Label |
|-------------|--------------|-----------------|
| `daily_progress_card` | "Daily Progress Report" | "Today's Work" |
| `attendance_card` | "Attendance" | "Mark Attendance" |
| `expense_card` | "Expense Entry" | "Add Expense" |
| `inventory_entry_card` | "Inventory Entry" | "Material In/Out" |
| `summary_analysis_card` | "Summary & Analysis" | "Work Summary" |
| `salary_slip_card` | "Salary Slip" | "Pay Slip" |
| `create_team_card` | "Create Team" | "My Teams" |
| `manpower_details_card` | "Manpower Details" | "Workers" |
| `site_details_card` | "Site Details" | "My Sites" |

---

### 4.4 Reduce Decision Steps in Data Entry

**Principle:** Every screen should have ONE clear primary action.

**Examples:**
- DPR entry: Pre-fill date (today), pre-select last used site/team
- Attendance: Show today's team list immediately, single tap to mark present
- Expense: Start with amount field focused, category as big icon buttons (not dropdown)

**Key files:**
- `lib/features/modules/all_Modules/attendance/screen/attendanceScreen.dart`
- `lib/features/modules/all_Modules/dpr/screens/add_description.dart`
- `lib/features/modules/all_Modules/expense/screens/expense_screen.dart`

---

### 4.5 High-Contrast Outdoor Mode

**Add to app theme configuration:**
- Increase font weight across the board (w500 → w600 minimum)
- Ensure color contrast ratio meets WCAG AA (4.5:1 for text)
- Remove low-opacity text colors (anything below 0.7 opacity)
- Use solid background colors instead of semi-transparent ones

**Files:**
- App-level theme definition
- `lib/core/utlis/widgets/` — all shared widgets

---

### 4.6 Remove Corporate Dashboard Styling

**What to remove:**
- Excessive gradients and shadows (found in `work_cat.dart` CompanyCard)
- Complex animations that slow down low-end phones
- Blur effects (`BackdropFilter` in `module_screen_v2.dart` lines 1542, 1756)
- Floating ball upload indicator — replace with simple inline status

**What to keep:**
- Clean card layouts
- Clear hierarchy
- Good spacing

---

## Technical UX Principles Applied

| Principle | Where Applied |
|-----------|--------------|
| Persistent navigation | Phase 2 — Never hide modules |
| Silent background sync | Phase 3 — Remove all sync popups |
| Offline-first interaction | Phase 3 — Draft-first architecture |
| Low-friction data entry | Phase 4 — Pre-fill, smart defaults |
| Reduced notification dependency | Phase 1 + 3 — Only show actionable alerts |
| State-based UI feedback | Phase 3.6 — Inline indicators, no popups |
| Predictable screen hierarchy | Phase 2 — Fixed nav structure |
| High visual clarity | Phase 4 — Large text, high contrast |

---

## File Reference Map

| Area | Key Files |
|------|-----------|
| Category order | `lib/typeProvider/work_type.dart`, `lib/work_cat.dart` |
| Sync banner | `lib/core/api/global_sync_banner.dart` |
| Sync jobs | `lib/core/api/sync_job.dart` |
| Sync manager | `lib/core/api/syncManager.dart` |
| Upload banner | `lib/core/upload/ui/upload_banner.dart` |
| Network mode | `lib/core/api/network_mode.dart` |
| Notification service | `lib/features/noti_system/updates/domain/services/notification_ingestion_service.dart` |
| Global overlay | `lib/features/tour/screen/global_tour_overlay.dart` |
| Module screen (nav) | `lib/features/modules/screen/module_screen_v2.dart` |
| Module screen (old) | `lib/features/modules/screen/module_screen.dart` |
| Router | `lib/core/router/app_router.dart` |
| Type provider | `lib/typeProvider/type_provider.dart` |

---

## Execution Priority

```
Phase 1 → Immediate (Days 1-2)
Phase 2 → Next (Days 3-7)
Phase 3 → After Phase 2 (Days 8-14)
Phase 4 → Ongoing (Days 15-24)
```

**Phase 1 is independent** — start immediately.
**Phase 2.3** (empty state widget) must be done before **Phase 2.4** (apply to all modules).
**Phase 3.1-3.4** should be done as one single PR (sync refactor).
**Phase 3.5** (SnackBar audit) can run in parallel with Phase 4.
**Phase 4** depends on Phase 2 completion.
