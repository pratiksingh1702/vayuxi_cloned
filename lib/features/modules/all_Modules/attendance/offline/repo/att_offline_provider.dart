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

final attendanceOfflineProvider = StreamProvider.family<List<AttendanceModel>,
    ({String siteId, String type, DateTime date})>((ref, args) async* {
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
    } catch (e, s) {
      // Do NOT stop the provider — just log and continue
      print("⚠️ Attendance sync failed: $e");
    }
  }


  /// fetch teams
  final teamNotifier = ref.read(teamProvider.notifier);
  await teamNotifier.fetchTeams(type: args.type, siteId: args.siteId);

  final teams = ref.read(teamProvider).teams;

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
  /// stream DB
  yield* repo.watchAttendance(
    siteId: args.siteId,
    type: args.type,
    dateKey: dateKey,
  );
});
final attendanceDraftProvider =
    StateProvider<List<AttendanceModel>>((ref) => []);
