import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/api/dio.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/offline/mech/repo/dpr_draft_repo.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/offline/repo/insu_dpr_draft_repo.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class DashDraft {
  final String id;
  final String title;
  final String subtitle;
  final String module;
  final String type; // 'mech' | 'insu'
  final dynamic data;
  final DateTime savedAt;

  DashDraft({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.module,
    required this.type,
    required this.data,
    required this.savedAt,
  });
}

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
      siteName: (json['site'] is Map)
          ? (json['site']['siteName'] ?? json['site']['name'])?.toString()
          : null,
      teamName: (json['team'] is Map)
          ? (json['team']['teamName'] ?? json['team']['name'])?.toString()
          : null,
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
    // Try to get counts from today first, fallback to latestEntryDateStats if 0
    final today = json['today'] as Map<String, dynamic>?;
    final latest = json['latestEntryDateStats'] as Map<String, dynamic>?;

    int present = (today?['totalPresentWorkers'] as num?)?.toInt() ?? 0;
    int absent = (today?['totalAbsentWorkers'] as num?)?.toInt() ?? 0;

    if (present == 0 && absent == 0 && latest != null) {
      present = (latest['totalPresentWorkers'] as num?)?.toInt() ?? 0;
      absent = (latest['totalAbsentWorkers'] as num?)?.toInt() ?? 0;
    }

    return DashAttendance(
      totalPresent: present,
      totalAbsent: absent,
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
      cat = (raw['category'] ?? raw['expenseType'])?.toString();
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
  final DashLastEntry? lastEntry;
  final String? lastMaterial;
  final String? lastMovementType;
  final num? lastQty;
  final String? uom;

  const DashInventory({
    required this.totalItems,
    required this.lowStockItems,
    this.lastEntry,
    this.lastMaterial,
    this.lastMovementType,
    this.lastQty,
    this.uom,
  });

  factory DashInventory.fromJson(Map<String, dynamic> json) {
    final raw = json['lastEntry'];
    DashLastEntry? entry;
    String? mat, movType, uom;
    num? qty;
    if (raw is Map<String, dynamic>) {
      entry = DashLastEntry.fromJson(raw);
      mat = raw['materialName']?.toString();
      if (mat == null && raw['inventory'] is Map) {
        mat = raw['inventory']['name']?.toString();
      }
      uom = raw['uom']?.toString();
      final mov = raw['lastMovement'];
      if (mov is Map<String, dynamic>) {
        movType = mov['movementType']?.toString();
        qty = mov['quantity'] as num?;
      } else {
        qty = (raw['quantity'] ?? raw['totalQty']) as num?;
      }
    }
    return DashInventory(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      lowStockItems: (json['lowStockItems'] as num?)?.toInt() ?? 0,
      lastEntry: entry,
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

    final raw = response.data as Map<String, dynamic>;
    final data = (raw['data'] as Map<String, dynamic>?) ?? raw;
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

final dashboardDraftsProvider = FutureProvider<List<DashDraft>>((ref) async {
  final mechRepo = DprDraftRepo();
  final insuRepo = InsuDprDraftRepo();

  final mechDrafts = await mechRepo.getAllDrafts();
  final insuDrafts = await insuRepo.getAllDrafts();

  final List<DashDraft> all = [];

  for (final d in mechDrafts) {
    all.add(DashDraft(
      id: d.draftId,
      title: d.draft.dprName.isNotEmpty ? d.draft.dprName : "Draft Entry",
      subtitle: "Site: ${d.siteId} · Team: ${d.teamId}",
      module: "DPR (Mechanical)",
      type: 'mech',
      data: d.draft,
      savedAt: d.savedAt,
    ));
  }

  for (final d in insuDrafts) {
    all.add(DashDraft(
      id: d.draftId,
      title: d.draft.workDescription.isNotEmpty
          ? d.draft.workDescription
          : "Draft Entry",
      subtitle: "Site: ${d.siteId} · Team: ${d.teamId}",
      module: "DPR (Insulation)",
      type: 'insu',
      data: d.draft,
      savedAt: d.savedAt,
    ));
  }

  all.sort((a, b) => b.savedAt.compareTo(a.savedAt));
  return all;
});
