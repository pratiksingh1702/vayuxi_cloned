# Module Dashboard — Implementation Guide

## Overview

This document tells the AI exactly what to build, where to put it, and how each piece connects.  
**Scope:** Daily Entry tab only. Setup / Reports / More tabs show no stats.  
**Goal:** Replace the static "Recent Activity" and "Overview" cards with live, minimal stats pulled from `/api/v1/dashboard/activity-summary`, filtered by the currently selected `type`, `site`, and `team`.

---

## 1. Files to Create

### 1a. `module_dashboard_service.dart`

**Location:** Same directory as `module_screen_v2.dart`

**What it does:**
- Contains the model `DashboardSummary` (and nested models).
- Contains the service class `ModuleDashboardService` with one method: `fetchSummary(...)`.
- Contains the Riverpod `dashboardSummaryProvider`.
- Uses `DioClient.dio` (imported from `package:untitled2/core/api/dio_client.dart`).
- Returns `DashboardSummary` on success, throws on error.

**Full code to generate:**

```dart
// module_dashboard_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/dio_client.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class DashLastEntry {
  final String? id;
  final String? date;
  final String? siteName;
  final String? teamName;
  final String? createdAt;

  const DashLastEntry({
    this.id,
    this.date,
    this.siteName,
    this.teamName,
    this.createdAt,
  });

  factory DashLastEntry.fromJson(Map<String, dynamic> json) {
    return DashLastEntry(
      id: json['_id']?.toString(),
      date: json['date']?.toString(),
      siteName: (json['site'] is Map) ? json['site']['siteName']?.toString() : null,
      teamName: (json['team'] is Map) ? json['team']['teamName']?.toString() : null,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class DashAttendance {
  final int totalPresent;
  final int totalAbsent;
  final DashLastEntry? lastEntry;

  const DashAttendance({
    required this.totalPresent,
    required this.totalAbsent,
    this.lastEntry,
  });

  factory DashAttendance.fromJson(Map<String, dynamic> json) {
    return DashAttendance(
      totalPresent: (json['totalPresentWorkers'] as num?)?.toInt() ?? 0,
      totalAbsent: (json['totalAbsentWorkers'] as num?)?.toInt() ?? 0,
      lastEntry: json['lastEntry'] != null
          ? DashLastEntry.fromJson(json['lastEntry'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DashDpr {
  final DashLastEntry? lastEntry;
  final num? totalQty;
  final String? remarks;

  const DashDpr({this.lastEntry, this.totalQty, this.remarks});

  factory DashDpr.fromJson(Map<String, dynamic> json) {
    final raw = json['lastEntry'];
    DashLastEntry? entry;
    num? qty;
    String? rmk;
    if (raw is Map<String, dynamic>) {
      entry = DashLastEntry.fromJson(raw);
      qty = raw['totalQty'] as num?;
      rmk = raw['remarks']?.toString();
    }
    return DashDpr(lastEntry: entry, totalQty: qty, remarks: rmk);
  }
}

class DashExpenses {
  final num totalAmount;
  final DashLastEntry? lastEntry;
  final String? category;
  final num? lastAmount;

  const DashExpenses({
    required this.totalAmount,
    this.lastEntry,
    this.category,
    this.lastAmount,
  });

  factory DashExpenses.fromJson(Map<String, dynamic> json) {
    final raw = json['lastEntry'];
    DashLastEntry? entry;
    String? cat;
    num? amt;
    if (raw is Map<String, dynamic>) {
      entry = DashLastEntry.fromJson(raw);
      cat = raw['category']?.toString();
      amt = raw['amount'] as num?;
    }
    return DashExpenses(
      totalAmount: (json['totalAmount'] as num?) ?? 0,
      lastEntry: entry,
      category: cat,
      lastAmount: amt,
    );
  }
}

class DashInventory {
  final int totalItems;
  final int lowStockItems;
  final String? lastMaterial;
  final String? lastMovementType;
  final num? lastQty;
  final String? uom;

  const DashInventory({
    required this.totalItems,
    required this.lowStockItems,
    this.lastMaterial,
    this.lastMovementType,
    this.lastQty,
    this.uom,
  });

  factory DashInventory.fromJson(Map<String, dynamic> json) {
    final raw = json['lastEntry'];
    String? mat, movType, uom;
    num? qty;
    if (raw is Map<String, dynamic>) {
      mat = raw['materialName']?.toString();
      uom = raw['uom']?.toString();
      final mov = raw['lastMovement'];
      if (mov is Map<String, dynamic>) {
        movType = mov['movementType']?.toString();
        qty = mov['quantity'] as num?;
      }
    }
    return DashInventory(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      lowStockItems: (json['lowStockItems'] as num?)?.toInt() ?? 0,
      lastMaterial: mat,
      lastMovementType: movType,
      lastQty: qty,
      uom: uom,
    );
  }
}

class DashboardSummary {
  final DashAttendance attendance;
  final DashDpr dpr;
  final DashExpenses expenses;
  final DashInventory inventory;

  const DashboardSummary({
    required this.attendance,
    required this.dpr,
    required this.expenses,
    required this.inventory,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      attendance: DashAttendance.fromJson(
          (json['attendance'] as Map<String, dynamic>?) ?? {}),
      dpr: DashDpr.fromJson((json['dpr'] as Map<String, dynamic>?) ?? {}),
      expenses: DashExpenses.fromJson(
          (json['expenses'] as Map<String, dynamic>?) ?? {}),
      inventory: DashInventory.fromJson(
          (json['inventory'] as Map<String, dynamic>?) ?? {}),
    );
  }
}

// ── Service ────────────────────────────────────────────────────────────────

class ModuleDashboardService {
  static const String _path = '/dashboard/activity-summary';

  /// Fetches the activity summary.
  /// Pass [type], [siteId], [teamId] — all nullable.
  /// When null they are simply omitted from the query string.
  static Future<DashboardSummary> fetchSummary({
    String? type,
    String? siteId,
    String? teamId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (siteId != null && siteId.isNotEmpty) queryParams['site'] = siteId;
    if (teamId != null && teamId.isNotEmpty) queryParams['team'] = teamId;

    final response = await DioClient.dio.get(
      _path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data as Map<String, dynamic>;
    return DashboardSummary.fromJson(data);
  }
}

// ── Params + Provider ──────────────────────────────────────────────────────

/// Params bag — Riverpod rebuilds the provider whenever any field changes.
class DashboardParams {
  final String? type;
  final String? siteId;
  final String? teamId;

  const DashboardParams({this.type, this.siteId, this.teamId});

  @override
  bool operator ==(Object other) =>
      other is DashboardParams &&
      other.type == type &&
      other.siteId == siteId &&
      other.teamId == teamId;

  @override
  int get hashCode => Object.hash(type, siteId, teamId);
}

final dashboardSummaryProvider =
    FutureProvider.family<DashboardSummary, DashboardParams>(
        (ref, params) async {
  return ModuleDashboardService.fetchSummary(
    type: params.type,
    siteId: params.siteId,
    teamId: params.teamId,
  );
});
```

---

## 2. Changes to `module_screen_v2.dart`

### 2a. New import to add at the top of the file

```dart
import 'module_dashboard_service.dart';
```

### 2b. In `_buildScrollBody` — replace activity and overview calls

Find this block:

```dart
_buildActivityCard(),
const SizedBox(height: 10),
_buildOverviewCard(cs, isDark),
```

Replace it with:

```dart
if (_currentIndex == 0) ...[
  _buildDailyStatsSection(cs, isDark),
  const SizedBox(height: 10),
],
```

### 2c. Delete these old methods entirely

Remove (do not keep, do not leave as comments) the following methods:
- `_buildActivityCard()`
- `_buildActivityRow(...)`
- `_buildOverviewCard(...)`
- `_buildOverviewRow(...)`

### 2d. Add these new methods to `_ModuleScreenV2State`

Paste the entire block below into the class body (good place: after `_buildDropdownRow`):

```dart
// ── Daily Entry Stats (Daily tab only) ─────────────────────────────────────

Widget _buildDailyStatsSection(ColorScheme cs, bool isDark) {
  final type = ref.watch(typeProvider);
  final selectedSite = ref.watch(siteDropdownValueProvider);
  final selectedTeam = ref.watch(teamDropdownValueProvider);

  final params = DashboardParams(
    type: type,
    siteId: selectedSite?.id,
    teamId: selectedTeam?.id,
  );

  final asyncSummary = ref.watch(dashboardSummaryProvider(params));

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: asyncSummary.when(
      loading: () => _buildStatsShimmer(cs),
      // Silent fail — stats are supplemental; never distract user with an error
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) => _buildStatsGrid(summary, cs, isDark),
    ),
  );
}

Widget _buildStatsShimmer(ColorScheme cs) {
  return Row(
    children: List.generate(4, (i) {
      return Expanded(
        child: Container(
          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
          height: 80,
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: cs.outlineVariant.withOpacity(0.3), width: 0.8),
          ),
        ),
      );
    }),
  );
}

Widget _buildStatsGrid(DashboardSummary s, ColorScheme cs, bool isDark) {
  String fmtAmount(num v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String fmtTime(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '—';
    }
  }

  final hasLowStock = s.inventory.lowStockItems > 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Eyebrow label
      Row(children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
              color: Colors.greenAccent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          "Today's Snapshot",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: cs.onSurfaceVariant,
          ),
        ),
      ]),
      const SizedBox(height: 8),

      // 4 stat tiles — single row
      Row(
        children: [
          _buildStatTile(
            cs: cs,
            isDark: isDark,
            icon: Icons.how_to_reg_rounded,
            iconColor: Colors.green,
            label: 'Attendance',
            value: '${s.attendance.totalPresent}',
            sub: '${s.attendance.totalAbsent} absent',
            subColor: s.attendance.totalAbsent > 0
                ? Colors.orange
                : cs.onSurfaceVariant,
            time: fmtTime(s.attendance.lastEntry?.createdAt),
          ),
          const SizedBox(width: 8),
          _buildStatTile(
            cs: cs,
            isDark: isDark,
            icon: Icons.description_rounded,
            iconColor: Colors.indigo,
            label: 'DPR',
            value: s.dpr.lastEntry != null ? 'Filed' : 'None',
            sub: s.dpr.totalQty != null
                ? 'Qty ${s.dpr.totalQty}'
                : (s.dpr.remarks ?? '—'),
            subColor: cs.onSurfaceVariant,
            time: fmtTime(s.dpr.lastEntry?.createdAt),
          ),
          const SizedBox(width: 8),
          _buildStatTile(
            cs: cs,
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.orange,
            label: 'Expenses',
            value: fmtAmount(s.expenses.totalAmount),
            sub: s.expenses.category ?? '—',
            subColor: cs.onSurfaceVariant,
            time: fmtTime(s.expenses.lastEntry?.createdAt),
          ),
          const SizedBox(width: 8),
          _buildStatTile(
            cs: cs,
            isDark: isDark,
            icon: Icons.inventory_2_rounded,
            iconColor: hasLowStock ? Colors.redAccent : Colors.teal,
            label: 'Inventory',
            value: '${s.inventory.totalItems}',
            sub: hasLowStock
                ? '${s.inventory.lowStockItems} low'
                : 'All stocked',
            subColor: hasLowStock ? Colors.redAccent : Colors.teal,
            time: null,
            highlight: hasLowStock,
          ),
        ],
      ),
    ],
  );
}

Widget _buildStatTile({
  required ColorScheme cs,
  required bool isDark,
  required IconData icon,
  required Color iconColor,
  required String label,
  required String value,
  required String sub,
  required Color subColor,
  String? time,
  bool highlight = false,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? Colors.redAccent.withOpacity(0.4)
              : cs.outlineVariant.withOpacity(0.4),
          width: highlight ? 1.2 : 0.8,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: subColor,
            ),
          ),
          if (time != null) ...[
            const SizedBox(height: 3),
            Text(
              time,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: cs.onSurfaceVariant.withOpacity(0.55),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 3. Update `_buildLoadingState()`

Inside `_buildLoadingState()`, find the shimmer blocks for activity card and overview card and **replace both** with this single 4-tile shimmer row:

```dart
// Replace old activity shimmer + overview shimmer with:
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    children: List.generate(4, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
        child: ShimmerImage(height: 80, width: double.infinity, borderRadius: 14),
      ),
    )),
  ),
),
const SizedBox(height: 10),
```

---

## 4. How Reactivity Works

`dashboardSummaryProvider` is a `FutureProvider.family` keyed on `DashboardParams`.

- User changes **site dropdown** → `siteDropdownValueProvider` emits → `params.siteId` changes → new API call fires automatically.
- User changes **team dropdown** → same flow with `teamDropdownValueProvider`.
- User's **work type** changes → `typeProvider` emits → `params.type` changes → new call.

**No manual refresh, no setState triggers needed.**

---

## 5. Complete Change Summary

| File | Action |
|------|--------|
| `module_dashboard_service.dart` | **Create** — models, service, provider |
| `module_screen_v2.dart` | Add `import 'module_dashboard_service.dart'` |
| `module_screen_v2.dart` | In `_buildScrollBody`: wrap with `if (_currentIndex == 0)` and call `_buildDailyStatsSection` |
| `module_screen_v2.dart` | **Delete** `_buildActivityCard`, `_buildActivityRow`, `_buildOverviewCard`, `_buildOverviewRow` |
| `module_screen_v2.dart` | **Add** `_buildDailyStatsSection`, `_buildStatsGrid`, `_buildStatTile`, `_buildStatsShimmer` |
| `module_screen_v2.dart` | In `_buildLoadingState`: replace two shimmer blocks with one 4-tile shimmer row |

---

## 6. Design Rules the AI Must Follow

- **4 tiles, single row** — Attendance · DPR · Expenses · Inventory. Never stack vertically.
- **Tile height ~80 dp** — compact. User must reach the module grid without excessive scrolling.
- **Silent on error** — `SizedBox.shrink()`. Stats are supplemental; never block user flow.
- **No CircularProgressIndicator** — shimmer tiles only during loading.
- **Low stock alert** — red border + red sub-text on Inventory tile only.
- **Relative timestamps** — "2m ago", "3h ago", "1d ago". Never ISO strings.
- **Setup / Reports / More tabs** — no stats rendered at all. Guard with `if (_currentIndex == 0)`.
- **Dark-mode safe** — always use `cs.*` tokens. `Colors.white` for tile bg is guarded by `isDark` check.
- **`DioClient.dio` only** — do not instantiate a new Dio or use `dioV2`.
- **`DashboardParams` must have correct `==` and `hashCode`** — already provided; do not remove them.

---

## 7. Pre-submit Checklist for the AI

- [ ] `module_dashboard_service.dart` exists in the same directory as `module_screen_v2.dart`
- [ ] `dashboardSummaryProvider` is `FutureProvider.family<DashboardSummary, DashboardParams>`
- [ ] `DashboardParams.==` and `.hashCode` are implemented with `Object.hash`
- [ ] `_buildScrollBody` only renders stats when `_currentIndex == 0`
- [ ] Old static activity/overview methods are deleted
- [ ] `_buildLoadingState` shimmer updated to 4-tile row
- [ ] No hardcoded API base URL — `DioClient.dio` already has `baseUrl` set
- [ ] App compiles with no unused import warnings