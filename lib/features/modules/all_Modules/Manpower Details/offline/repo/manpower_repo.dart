import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/offline/isar/manpower_isar.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/offline/repo/att_sync.dart';

import '../../../../../../core/local/isar_db.dart';
import '../../model/manpower_model.dart';
import '../../service/manpowerService.dart';

class ManpowerRepository {
  final Isar isar = AppIsarDB.isar;

  // ─────────────────────────────────────────────────────────────
  // WATCH
  // ─────────────────────────────────────────────────────────────

  /// Watch ALL manpower for a type (company-wide)
  Stream<List<ManpowerModel>> watchManpower(String type) {
    return isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((rows) => rows.map(_isarToModel).toList());
  }

  /// Watch manpower scoped to a specific site
  Stream<List<ManpowerModel>> watchManpowerBySite({
    required String siteId,
    required String type,
  }) {
    return isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .and()
        .isDeletedEqualTo(false)
        .and()
        .sitesElementEqualTo(siteId)
        .watch(fireImmediately: true)
        .map((rows) => rows.map(_isarToModel).toList());
  }

  // ─────────────────────────────────────────────────────────────
  // SYNC FROM API → ISAR
  // ─────────────────────────────────────────────────────────────

  /// Sync company-wide manpower (all sites) — called on ManpowerListScreen
  Future<void> syncFromApi(String type) async {
    final res = await ManpowerAPI.fetchManpower(type);
    if (res["success"] != true) return;

    final List list = res["data"];
    await _upsertManpowerList(
      list.map((e) => ManpowerModel.fromJson(e)).toList(),
      type,
    );
  }

  /// Sync manpower belonging to a specific site —
  /// uses GET /api/v1/site/[siteId]/manpower?type=...
  Future<void> syncFromApiForSite({
    required String siteId,
    required String type,
  }) async {
    final res = await ManpowerAPI.fetchManpowerBySite(siteId: siteId, type: type);
    if (res["success"] != true) return;

    final List list = res["data"];
    await _upsertManpowerList(
      list.map((e) => ManpowerModel.fromJson(e)).toList(),
      type,
    );
  }

  /// Shared upsert logic — writes a list of ManpowerModel into Isar
  Future<void> _upsertManpowerList(List<ManpowerModel> models, String type) async {
    await isar.writeTxn(() async {
      for (final m in models) {
        // 🔥 Find existing record
        final existing = await isar.manpowerIsars
            .filter()
            .manpowerIdEqualTo(m.id ?? "")
            .findFirst();

        final obj = existing ?? ManpowerIsar();

        // 🔥 Update instead of duplicate insert
        obj
          ..manpowerId = m.id ?? ""
          ..type = m.type ?? type
          ..fullName = m.fullName
          ..designation = m.designation
          ..employeeCode = m.employeeCode
          ..phoneNumber = m.phoneNumber
          ..sites = List<String>.from(m.sites)
          ..isDeleted = m.isDeleted ?? false
          ..isLeft = m.isLeft ?? false
          ..updatedAt = DateTime.tryParse(m.updatedAt ?? "") ?? DateTime.now();

        await isar.manpowerIsars.put(obj);
      }
    });
  }
  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  ManpowerModel _isarToModel(ManpowerIsar m) {
    return ManpowerModel(
      id: m.manpowerId,
      fullName: m.fullName,
      designation: m.designation,
      employeeCode: m.employeeCode,
      phoneNumber: m.phoneNumber,
      company: m.company,
      type: m.type,
      sites: List<String>.from(m.sites),
      isDeleted: m.isDeleted,
      isLeft: m.isLeft,
      createdAt: m.updatedAt.toIso8601String(),
      updatedAt: m.updatedAt.toIso8601String(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

final manpowerRepositoryProvider = Provider((ref) => ManpowerRepository());

/// Company-wide manpower stream (unchanged behaviour — used in ManpowerListScreen)
final manpowerOfflineProvider =
StreamProvider.family<List<ManpowerModel>, String>((ref, type) {
  final repo = ref.read(manpowerRepositoryProvider);
  Future.microtask(() => repo.syncFromApi(type));
  return repo.watchManpower(type);
});

/// ✅ NEW: Site-scoped manpower stream
/// Usage: ref.watch(manpowerBySiteProvider((siteId: 'siteA', type: 'mechanical_work')))
final manpowerBySiteProvider =
StreamProvider.family<List<ManpowerModel>, ({String siteId, String type})>(
      (ref, args) {
    final repo = ref.read(manpowerRepositoryProvider);

    // Background sync for this site
    Future.microtask(
          () => repo.syncFromApiForSite(siteId: args.siteId, type: args.type),
    );

    return repo.watchManpowerBySite(siteId: args.siteId, type: args.type);
  },
);