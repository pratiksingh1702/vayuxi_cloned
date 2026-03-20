import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/offline/isar/manpower_isar.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/offline/repo/att_sync.dart';

import '../model/manpower_model.dart';

import '../offline/repo/manpower_repo.dart';
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
  final ManpowerRepository repo;

  ManpowerNotifier(this.repo) : super(ManpowerState());

  /// Fetch manpower list
  Future<void> fetchManpower(String type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 🔥 Try API first

      await repo.syncFromApi(type);

      // 🔥 Always load from Isar after sync
      final localData = await repo.isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .isDeletedEqualTo(false)
          .findAll();

      state = state.copyWith(
        manpowerList: localData.map((m) => ManpowerModel(
          id: m.manpowerId,
          fullName: m.fullName,
          designation: m.designation,
          employeeCode: m.employeeCode,
          phoneNumber: m.phoneNumber,
          company: m.company,
          type: m.type,
          isDeleted: m.isDeleted,
          isLeft: m.isLeft,
          createdAt: m.updatedAt.toIso8601String(),
          updatedAt: m.updatedAt.toIso8601String(),
        )).toList(),
        isLoading: false,
      );

    } catch (e) {
      // ❌ API failed → fallback to Isar
      print("⚠️ API failed, loading offline data");

      final localData = await repo.isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .isDeletedEqualTo(false)
          .findAll();

      if (localData.isNotEmpty) {
        state = state.copyWith(
          manpowerList: localData.map((m) => ManpowerModel(
            id: m.manpowerId,
            fullName: m.fullName,
            designation: m.designation,
            employeeCode: m.employeeCode,
            phoneNumber: m.phoneNumber,
            company: m.company,
            type: m.type,
            isDeleted: m.isDeleted,
            isLeft: m.isLeft,
            createdAt: m.updatedAt.toIso8601String(),
            updatedAt: m.updatedAt.toIso8601String(),
          )).toList(),
          isLoading: false,
          error: "Offline mode",
        );
      } else {
        state = state.copyWith(
          error: "No data available (offline + API failed)",
          isLoading: false,
        );
      }
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

final manpowerProvider =
StateNotifierProvider<ManpowerNotifier, ManpowerState>((ref) {
  final repo = ref.read(manpowerRepositoryProvider);
  return ManpowerNotifier(repo);
});