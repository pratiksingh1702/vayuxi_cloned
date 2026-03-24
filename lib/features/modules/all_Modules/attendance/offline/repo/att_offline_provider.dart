import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../Manpower Details/model/manpower_model.dart';
import '../../model/attModel.dart';
import 'att_sync.dart';

String normalizeDateKey(DateTime date) {
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

// ─────────────────────────────────────────────────────────────
// MANPOWER OFFLINE PROVIDERS
// ─────────────────────────────────────────────────────────────

/// Company-wide manpower stream (all sites for a type).
final manpowerOfflineProvider =
StreamProvider.family<List<ManpowerModel>, ({String type})>((ref, args) {
  ref.watch(manpowerSyncControllerProvider((type: args.type)));
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchManpower(args.type);
});

/// Site-scoped manpower stream.
/// Syncs via GET /site/[siteId]/manpower, then watches Isar filtered by
/// sitesElementEqualTo(siteId).
final manpowerBySiteOfflineProvider =
StreamProvider.family<List<ManpowerModel>, ({String siteId, String type})>(
        (ref, args) {
      ref.watch(manpowerSyncBySiteControllerProvider(
        (siteId: args.siteId, type: args.type),
      ));
      final repo = ref.watch(attendanceRepositoryProvider);
      return repo.watchManpowerBySite(siteId: args.siteId, type: args.type);
    });

// ─────────────────────────────────────────────────────────────
// ATTENDANCE OFFLINE PROVIDER
// ─────────────────────────────────────────────────────────────

final attendanceRefreshProvider = StateProvider<int>((ref) => 0);

/// Streams attendance for a site + type + date.
///
/// ── Filtering logic ──────────────────────────────────────────
/// A manpower appears in the attendance list if and only if their
/// [sites] array contains [siteId].
///
/// Team membership is NOT a factor. Every person assigned to the site
/// gets an attendance row regardless of which team (if any) they belong to.
/// ─────────────────────────────────────────────────────────────
final attendanceOfflineProvider = StreamProvider.family<List<AttendanceModel>,
    ({String siteId, String type, DateTime date})>((ref, args) async* {
  ref.watch(attendanceRefreshProvider);

  final repo = ref.watch(attendanceRepositoryProvider);
  final dateKey = repo.formatDateKey(args.date);

  // ── Background sync ─────────────────────────────────────────
  if (await repo.isOnline()) {
    try {
      // Sync site-specific manpower first so sites[] arrays are populated
      await repo.syncManpowerBySite(
        siteId: args.siteId,
        type: args.type,
      );
    } catch (e) {
      print("⚠️ Manpower site-sync failed: $e");
    }

    try {
      await repo.syncAttendanceForDate(
        siteId: args.siteId,
        type: args.type,
        dateKey: dateKey,
      );
    } catch (e) {
      print("⚠️ Attendance sync failed: $e");
    }
  }

  // ── Ensure absent rows exist for every site-assigned manpower ──
  await repo.ensureAttendanceForSite(
    siteId: args.siteId,
    type: args.type,
    dateKey: dateKey,
  );

  // ── Stream live data (site-only filter inside watchAttendance) ──
  yield* repo.watchAttendance(
    siteId: args.siteId,
    type: args.type,
    dateKey: dateKey,
  );
});

final attendanceDraftProvider =
StateProvider<List<AttendanceModel>>((ref) => []);