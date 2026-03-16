import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/typeProvider/type_provider.dart';
import '../../../Manpower Details/model/manpower_model.dart';
import '../../../team/provider/teamProvider.dart';
import '../../model/attModel.dart';
import 'att_sync.dart';

String normalizeDateKey(DateTime date) {
  // YYYY-MM-DD
  return "${date.year.toString().padLeft(4, '0')}-"
      "${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";
}

/// ✅ OFFLINE manpower stream
final manpowerOfflineProvider =
    StreamProvider.family<List<ManpowerModel>, ({String type})>((ref, args) {
  ref.watch(manpowerSyncControllerProvider((type: args.type)));
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchManpower(args.type);
});

// att_offline_provider.dart

// Add a refresh counter to force provider re-runs
final attendanceRefreshProvider = StateProvider<int>((ref) => 0);

final attendanceOfflineProvider = StreamProvider.family<List<AttendanceModel>,
    ({String siteId, String type, DateTime date})>((ref, args) async* {

  // ✅ FIX 1: Watch the refresh counter — any increment forces full re-run
  ref.watch(attendanceRefreshProvider);

  // ✅ FIX 2: Watch teamProvider reactively so new members trigger re-run
  final teams = ref.watch(teamProvider).teams;

  print('🔄 Fetching attendance for ${args.date}');

  final repo = ref.watch(attendanceRepositoryProvider);
  final dateKey = repo.formatDateKey(args.date);

  if (await repo.isOnline()) {
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

  // ✅ FIX 2: Use teams from reactive watch above, not a one-shot read
  final ids = teams
      .expand((t) => [
    ...t.teamMemberIds,
    if (t.teamLeadId != null && t.teamLeadId!.isNotEmpty) t.teamLeadId!,
  ])
      .toSet()
      .toList();

  if (ids.isNotEmpty) {
    await repo.ensureAttendanceForTeam(
      siteId: args.siteId,
      type: args.type,
      dateKey: dateKey,
      teamMemberIds: ids,
    );
  }

  yield* repo.watchAttendance(
    siteId: args.siteId,
    type: args.type,
    dateKey: dateKey,
    teamMemberIds: ids,
  );
});
final attendanceDraftProvider =
    StateProvider<List<AttendanceModel>>((ref) => []);
