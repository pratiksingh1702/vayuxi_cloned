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
  ref.watch(manpowerSyncControllerProvider(( type: args.type)));
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchManpower(args.type);
});

/// ✅ OFFLINE attendance stream
final attendanceOfflineProvider = StreamProvider.family<
    List<AttendanceModel>,
    ({String siteId, String type, DateTime date})
>((ref, args) async* {
  final repo = ref.watch(attendanceRepositoryProvider);
  final type=ref.read(typeProvider)!;
  final id=ref.read(selectedSiteIdProvider)!;

  await ref
      .read(teamProvider.notifier)
      .fetchTeams(type: type!, siteId: id);

  final teamState = ref.watch(teamProvider);

  final dateKey = repo.formatDateKey(args.date);

// 🔥 Extract manpower IDs from ALL teams


  final teams = teamState.teams;
  print("📦 TOTAL TEAMS: ${teams.length}");

  for (final t in teams) {
    print("👥 TEAM: ${t.teamName}  → members: ${t.teamMemberIds} -> lead ${t.teamLeadId}");
  }



  final ids = teams
      .expand((t) => [
    ...t.teamMemberIds,
    if (t.teamLeadId != null && t.teamLeadId!.isNotEmpty)
      t.teamLeadId!,
  ])
      .toSet() // remove duplicates
      .toList();


  print("🆔 FINAL MANPOWER IDS (after merge + unique): $ids");


  if (ids.isNotEmpty) {

    await repo.prepareAttendanceFromTeam(
      siteId: args.siteId,
      type: args.type,
      dateKey: dateKey,
      teamMemberIds: ids,
    );
  }

  // 🔥 Stream after creation
  yield* repo.watchAttendance(
    siteId: args.siteId,
    type: args.type,
    dateKey: dateKey,
  );
});
final attendanceDraftProvider =
StateProvider<List<AttendanceModel>>((ref) => []);
