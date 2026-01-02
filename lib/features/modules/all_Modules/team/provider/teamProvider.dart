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

  Future<void> deleteTeam({
    required String siteId,
    required String teamId,
    required String type,
  }) async {
    try {
      state = const AsyncValue.loading();

      await TeamApi.deleteTeam(
        siteId: siteId,
        teamId: teamId,
      );

      // 🔄 Refresh list after delete
      await getTeams(type, siteId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
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
    ref.read(selectedTeamIdProvider.notifier).state = null;
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

  return teamState.when(
    data: (teams) {
      if (selectedId == null || teams.isEmpty) return null;
      try {
        return teams.firstWhere((team) => team.id == selectedId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});