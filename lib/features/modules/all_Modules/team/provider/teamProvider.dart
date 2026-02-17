import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:untitled2/features/modules/all_Modules/team/offline/state/isar_provider.dart';

import '../model/teamModel.dart';
import '../offline/isar/team_isar.dart';
import '../offline/isar/team_local_Storage.dart';
import '../offline/state/team_State.dart';
import '../provider/teamService.dart';

/// ------------------------------------------------------------
/// TEAM LIST PROVIDER
/// ------------------------------------------------------------
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/teamModel.dart';


final teamProvider =
StateNotifierProvider<TeamNotifier, TeamState>((ref) => TeamNotifier(ref));

class TeamNotifier extends StateNotifier<TeamState> {
  TeamNotifier(this.ref) : super(TeamState());

  final Ref ref;

  Future<void> fetchTeams({
    required String type,
    required String siteId,
  }) async {
    if (type.isEmpty || siteId.isEmpty) {
      state = state.copyWith(
        teams: [],
        isLoading: false,
        hasData: false,
        error: "Missing type/siteId",
      );
      return;
    }


    final local = TeamLocalStorage();

    // show loader ONLY if no data
    if (state.teams.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // ✅ 1) LOAD OFFLINE FIRST
      final cached = await local.getTeams(type: type, siteId: siteId);
      final cachedTeams = cached.map((e) => e.toModel()).toList();

      if (cachedTeams.isNotEmpty) {
        state = state.copyWith(
          teams: cachedTeams,
          isLoading: false,
          hasData: true,
        );
      }

      // ✅ 2) FETCH ONLINE
      final apiTeams = await TeamApi.fetchTeams(type: type, siteId: siteId);

      // ✅ 3) SAVE TO ISAR
      final keepIds = <String>{};
      final isarTeams = <TeamIsar>[];

      for (final team in apiTeams) {
        keepIds.add(team.id);
        isarTeams.add(TeamIsar.fromModel(team, siteId));
      }

      await local.saveTeams(type: type, siteId: siteId, teams: isarTeams);

      // ✅ 4) CLEANUP STALE
      await local.deleteTeamsNotIn(type: type, siteId: siteId, keepIds: keepIds);

      // ✅ 5) UPDATE UI
      state = state.copyWith(
        isLoading: false,
        teams: apiTeams,
        hasData: true,
        error: null,
      );
    } catch (e) {
      // ✅ fallback offline
      final cached = await local.getTeams(type: type, siteId: siteId);
      final cachedTeams = cached.map((e) => e.toModel()).toList();

      if (cachedTeams.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          teams: cachedTeams,
          hasData: true,
          error: "Using cached data - $e",
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          teams: [],
          hasData: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<void> deleteTeam({
    required String siteId,
    required String teamId,
    required String type,
  }) async {
    await TeamApi.deleteTeam(siteId: siteId, teamId: teamId);

    // Refresh
    await fetchTeams(type: type, siteId: siteId);
  }

  Future<void> updateTeam({
    required String siteId,
    required String teamId,
    required String type,
    required FormData data,
  }) async {
    await TeamApi.updateTeam(siteId: siteId, teamId: teamId, data: data);

    await fetchTeams(type: type, siteId: siteId);
  }

  Future<void> createTeam({
    required String siteId,
    required String type,
    required FormData data,
  }) async {
    await TeamApi.createTeam(siteId: siteId, type: type, data: data);

    await fetchTeams(type: type, siteId: siteId);
  }
}


/// ------------------------------------------------------------
/// FETCH SINGLE TEAM (API CALL)
/// ------------------------------------------------------------
final teamDetailsProvider =
FutureProvider.family<TeamModel, Map<String, String>>((ref, params) async {
  return await TeamApi.fetchTeamById(
    siteId: params["siteId"]!,
    teamId: params["teamId"]!,
  );
});

/// ------------------------------------------------------------
/// TEAM DROPDOWN & SELECTION (MATCHES SITE PATTERN)
/// ------------------------------------------------------------

/// Stores the dropdown value (can be null or "none")
final teamDropdownValueProvider = StateProvider<TeamModel?>((ref) => null);

/// Stores only the selected team's ID
final selectedTeamIdProvider = StateProvider<String?>((ref) => null);


/// Manages team selection with clear() method
class SelectedTeamNotifier extends StateNotifier<TeamModel?> {
  SelectedTeamNotifier(this.ref) : super(null);
  final Ref ref;

  void select(TeamModel team) {
    state = team;
    ref.read(selectedTeamIdProvider.notifier).state = team.id;
    ref.read(teamDropdownValueProvider.notifier).state = team;
  }

  void clear() {
    state = null;
    ref.read(selectedTeamIdProvider.notifier).state = "";
    ref.read(teamDropdownValueProvider.notifier).state = null;
  }
}

final selectedTeamProvider =
StateNotifierProvider<SelectedTeamNotifier, TeamModel?>(
      (ref) => SelectedTeamNotifier(ref),
);

/// Auto-derives selected team from list & selected ID
final currentTeamProvider = Provider<TeamModel?>((ref) {
  final teamState = ref.watch(teamProvider);
  final selectedId = ref.watch(selectedTeamIdProvider);

  if (selectedId == null || selectedId.isEmpty) return null;
  if (teamState.teams.isEmpty) return null;

  try {
    return teamState.teams.firstWhere((team) => team.id == selectedId);
  } catch (_) {
    return null;
  }
});
