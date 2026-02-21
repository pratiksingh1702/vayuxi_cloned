

import '../../model/teamModel.dart';

class TeamState {
  final bool isLoading;
  final List<TeamModel> teams;
  final String? error;
  final bool hasData;

  TeamState({
    this.isLoading = false,
    this.teams = const [],
    this.error,
    this.hasData = false,
  });

  TeamState copyWith({
    bool? isLoading,
    List<TeamModel>? teams,
    String? error,
    bool? hasData,
  }) {
    return TeamState(
      isLoading: isLoading ?? this.isLoading,
      teams: teams ?? this.teams,
      error: error ?? this.error,
      hasData: hasData ?? this.hasData,
    );
  }
}
