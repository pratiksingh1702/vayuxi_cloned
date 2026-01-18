import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/manpower_model.dart';

import 'manpowerService.dart';

/// State class to hold manpower data
class ManpowerState {
  final bool isLoading;
  final List<ManpowerModel> manpowerList;
  final String? error;

  ManpowerState({
    this.isLoading = false,
    this.manpowerList = const [],
    this.error,
  });

  ManpowerState copyWith({
    bool? isLoading,
    List<ManpowerModel>? manpowerList,
    String? error,
  }) {
    return ManpowerState(
      isLoading: isLoading ?? this.isLoading,
      manpowerList: manpowerList ?? this.manpowerList,
      error: error ?? this.error,
    );
  }
}

/// Notifier to manage manpower state
class ManpowerNotifier extends StateNotifier<ManpowerState> {
  ManpowerNotifier() : super(ManpowerState());

  /// Fetch manpower list
  Future<void> fetchManpower(String type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ManpowerAPI.fetchManpower(type);
      if (res["success"]) {
        final List dataList = res["data"];
        state = state.copyWith(
          manpowerList: dataList.map((e) => ManpowerModel.fromJson(e)).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: "Failed to fetch manpower",
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<ManpowerModel?> addManpower(String type, Map<String, dynamic> data) async {
    try {
      final response = await ManpowerAPI.postManpower(type, data);


        // Parse the created manpower from response
        final createdManpower = ManpowerModel.fromJson(response["data"]);

        // Refresh list
        await fetchManpower(type);

        // Return the created manpower
        return createdManpower;



    } catch (e) {
      state = state.copyWith(error: e.toString());
      throw Exception(e.toString());
    }
  }


  /// Update manpower
  Future<ManpowerModel?> updateManpower(
      String id,
      Map<String, dynamic> data,
      String type
      ) async {
    try {
      final response = await ManpowerAPI.updateManpower(id, data);

      // Check if response was successful and has data
      if (response["success"] == true && response["data"] != null) {
        // Parse the updated manpower from response
        final updatedManpower = ManpowerModel.fromJson(response["data"]);

        // Refresh list
        await fetchManpower(type);

        // Return the updated manpower
        return updatedManpower;
      }

      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
  /// Mark manpower as left
  Future<void> leftManpower(String id, Map<String, dynamic> data, String type) async {
    try {
      await ManpowerAPI.leftManpower(id, data);
      await fetchManpower(type);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider instance
final manpowerProvider =
StateNotifierProvider<ManpowerNotifier, ManpowerState>((ref) {
  return ManpowerNotifier();
});
