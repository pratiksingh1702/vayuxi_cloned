import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/local/isar_db.dart';
import 'att_repo.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(AppIsarDB.isar);
});

final manpowerSyncControllerProvider =
FutureProvider.family<void, ({String type})>((ref, args) async {
  final repo = ref.read(attendanceRepositoryProvider);
  await repo.syncManpowerFromApi(args.type);
});

final attendanceSyncControllerProvider =
FutureProvider.family<void, ({String siteId, String type, String dateKey})>(
      (ref, args) async {
    final repo = ref.read(attendanceRepositoryProvider);

    // prevent multiple sync spam
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
  },
);

