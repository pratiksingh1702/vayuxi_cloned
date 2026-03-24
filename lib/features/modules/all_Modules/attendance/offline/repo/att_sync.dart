import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/local/isar_db.dart';
import 'att_repo.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(AppIsarDB.isar);
});

/// Sync ALL manpower for a type (company-wide)
final manpowerSyncControllerProvider =
FutureProvider.family<void, ({String type})>((ref, args) async {
  final repo = ref.read(attendanceRepositoryProvider);
  await repo.syncManpowerFromApi(args.type);
});

/// ✅ NEW: Sync manpower scoped to a specific site
/// Uses GET /api/v1/site/[siteId]/manpower?type=...
final manpowerSyncBySiteControllerProvider =
FutureProvider.family<void, ({String siteId, String type})>((ref, args) async {
  final repo = ref.read(attendanceRepositoryProvider);
  await repo.syncManpowerBySite(siteId: args.siteId, type: args.type);
});

final attendanceSyncControllerProvider = FutureProvider.family<void,
    ({String siteId, String type, String dateKey})>((ref, args) async {
  final repo = ref.read(attendanceRepositoryProvider);
  final lock = ref.keepAlive();
  try {
    await repo.syncAttendanceForDate(
      siteId: args.siteId,
      type: args.type,
      dateKey: args.dateKey,
    );
  } finally {
    lock.close();
  }
});