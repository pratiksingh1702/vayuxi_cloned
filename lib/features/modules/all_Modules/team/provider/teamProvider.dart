import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../model/teamModel.dart';
import '../provider/teamService.dart';

/// ------------------------------------------------------------
/// TEAM LIST PROVIDER
/// ------------------------------------------------------------
final teamProvider =
StateNotifierProvider<TeamNotifier, AsyncValue<List<TeamModel>>>((ref) {
  return TeamNotifier();
});

class TeamNotifier extends StateNotifier<AsyncValue<List<TeamModel>>> {
  TeamNotifier() : super(const AsyncValue.loading());

  Future<void> getTeams(String type, String siteId) async {
    state = const AsyncValue.loading();
    try {
      final teams = await TeamApi.fetchTeams(type: type, siteId: siteId);
      state = AsyncValue.data(teams);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTeam({
    required String siteId,
    required String teamId,
    required FormData formData,
    required String type,
  }) async {
    try {
      state = const AsyncValue.loading();

      await TeamApi.updateTeam(
        siteId: siteId,
        teamId: teamId,
        data: formData,
      );

      await getTeams(type, siteId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> createTeam({
    required String type,
    required String siteId,
    required FormData formData,
  }) async {
    try {
      await TeamApi.createTeam(
        siteId: siteId,
        type: type,
        data: formData,
      );

      await getTeams(type, siteId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
/// SELECTED TEAM ID PROVIDER
/// ------------------------------------------------------------
/// Stores only the selected team's ID.
final selectedTeamIdProvider = StateProvider<String?>((ref) => null);


/// ------------------------------------------------------------
/// SELECTED TEAM PROVIDER (AUTO RETURNS TeamModel)
/// ------------------------------------------------------------
/// Returns full TeamModel based on selectedTeamId + teamProvider list.
final selectedTeamProvider = Provider<TeamModel?>((ref) {
  final selectedId = ref.watch(selectedTeamIdProvider);
  final teamState = ref.watch(teamProvider);

  return teamState.when(
    data: (teams) {
      if (selectedId == null) return null;
      return teams.firstWhere(
            (t) => t.id == selectedId,

      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
