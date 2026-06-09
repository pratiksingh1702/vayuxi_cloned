import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/offline/isar/manpower_isar.dart';

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

  // ─────────────────────────────────────────────────────────────
  // FETCH (company-wide)
  // ─────────────────────────────────────────────────────────────

  Future<void> fetchManpower(String type) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await repo.syncFromApi(type);

      final localData = await repo.isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .isDeletedEqualTo(false)
          .findAll();

      state = state.copyWith(
        manpowerList: localData.map((m) => _isarToModel(m, type)).toList(),
        isLoading: false,
      );
    } catch (e) {
      print("⚠️ API failed, loading offline data: $e");

      final localData = await repo.isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .isDeletedEqualTo(false)
          .findAll();

      if (localData.isNotEmpty) {
        state = state.copyWith(
          manpowerList: localData.map((m) => _isarToModel(m, type)).toList(),
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

  // ─────────────────────────────────────────────────────────────
  // FETCH (site-scoped)
  // ─────────────────────────────────────────────────────────────

  /// Fetch manpower that belong to a specific site.
  /// Syncs via GET /api/v1/site/[siteId]/manpower, then reads from Isar.
  Future<void> fetchManpowerBySite({
    required String siteId,
    required String type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Sync site-specific manpower
      final res =
          await ManpowerAPI.fetchManpowerBySite(siteId: siteId, type: type);

      if (res["success"] == true) {
        final List raw = res["data"];
        final models = raw.map((e) => ManpowerModel.fromJson(e)).toList();

        // Upsert into Isar
        await repo.isar.writeTxn(() async {
          final existing = await repo.isar.manpowerIsars
              .filter()
              .typeEqualTo(type)
              .findAll();
          final Map<String, ManpowerIsar> localMap = {
            for (var item in existing) item.manpowerId: item
          };

          final List<ManpowerIsar> isarList = [];
          for (final m in models) {
            final obj = localMap[m.id ?? ""] ?? ManpowerIsar();
            _fillIsarFromModel(obj, m, type);
            isarList.add(obj);
          }
          await repo.isar.manpowerIsars.putAll(isarList);
        });
      }

      // Read filtered by site from Isar
      final localData = await repo.isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .sitesElementEqualTo(siteId)
          .isDeletedEqualTo(false)
          .findAll();

      state = state.copyWith(
        manpowerList: localData.map((m) => _isarToModel(m, type)).toList(),
        isLoading: false,
      );
    } catch (e) {
      print("⚠️ fetchManpowerBySite failed: $e");

      // Fallback: serve from Isar filtered by site
      final localData = await repo.isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .sitesElementEqualTo(siteId)
          .isDeletedEqualTo(false)
          .findAll();

      state = state.copyWith(
        manpowerList: localData.map((m) => _isarToModel(m, type)).toList(),
        isLoading: false,
        error: "Offline mode",
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Create manpower. Optionally pass [siteId] to auto-assign the new
  /// employee to that site on creation (adds to [sites] array in payload).
  Future<ManpowerModel?> addManpower(
    String type,
    Map<String, dynamic> data, {
    String? siteId,
  }) async {
    try {
      // If a siteId is provided and not already in the payload, add it
      if (siteId != null && siteId.isNotEmpty) {
        final existingSites = List<String>.from(data['sites'] ?? []);
        if (!existingSites.contains(siteId)) {
          existingSites.add(siteId);
        }
        data['sites'] = existingSites;
      }

      final response = await ManpowerAPI.postManpower(type, data);

      if (response["success"] != true) {
        final msg = response["message"] ??
            response["error"] ??
            response["data"]?.toString() ??
            "Failed to create manpower";
        throw Exception(msg);
      }

      final createdManpower = ManpowerModel.fromJson(response["data"]);

      await fetchManpower(type);

      return createdManpower;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  Future<ManpowerModel?> updateManpower(
    String id,
    Map<String, dynamic> data,
    String type,
  ) async {
    try {
      final response = await ManpowerAPI.updateManpower(id, data);

      if (response["success"] == true && response["data"] != null) {
        final updatedManpower = ManpowerModel.fromJson(response["data"]);
        await repo.upsertManpower(updatedManpower, type);
        await fetchManpower(type);
        return updatedManpower;
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SITE ASSIGNMENT
  // ─────────────────────────────────────────────────────────────

  /// Assign manpower to a site (adds siteId to their sites array on the server).
  Future<bool> assignToSite({
    required String manpowerId,
    required String siteId,
    required String type,
  }) async {
    try {
      final res = await ManpowerAPI.manageManpowerSites(
        manpowerId: manpowerId,
        action: "add",
        siteIds: [siteId],
      );
      if (res["success"] == true) {
        await fetchManpower(type);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove manpower from a site
  Future<bool> removeFromSite({
    required String manpowerId,
    required String siteId,
    required String type,
  }) async {
    try {
      final res = await ManpowerAPI.manageManpowerSites(
        manpowerId: manpowerId,
        action: "remove",
        siteIds: [siteId],
      );
      if (res["success"] == true) {
        await fetchManpower(type);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // MARK LEFT
  // ─────────────────────────────────────────────────────────────

  Future<void> leftManpower(
    String id,
    Map<String, dynamic> data,
    String type,
  ) async {
    try {
      final res = await ManpowerAPI.leftManpower(id, data);
      if (res["success"] == true) {
        await fetchManpower(type);
      } else {
        throw Exception(res["message"] ?? "Failed to mark as left");
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  ManpowerModel _isarToModel(ManpowerIsar m, String type) {
    return ManpowerModel(
      id: m.manpowerId,
      fullName: m.fullName,
      designation: m.designation,
      employeeCode: m.employeeCode,
      phoneNumber: m.phoneNumber,
      company: m.company,
      type: m.type,
      sites: List<String>.from(m.sites),
      isDeleted: m.isDeleted,
      isLeft: m.isLeft,
      createdAt: m.updatedAt.toIso8601String(),
      updatedAt: m.updatedAt.toIso8601String(),
    );
  }

  void _fillIsarFromModel(ManpowerIsar obj, ManpowerModel m, String type) {
    obj
      ..manpowerId = m.id ?? ""
      ..type = m.type ?? type
      ..fullName = m.fullName
      ..designation = m.designation
      ..employeeCode = m.employeeCode
      ..phoneNumber = m.phoneNumber
      ..aadharNumber = m.aadharNumber
      ..panNumber = m.panNumber
      ..dateOfBirth = m.dateOfBirth
      ..dateOfJoining = m.dateOfJoining
      ..bankAccountNumber = m.bankAccountNumber
      ..ifscCode = m.ifscCode
      ..epfNumber = m.epfNumber
      ..uanNumber = m.uanNumber
      ..esicNumber = m.esicNumber
      ..payBasics = m.payBasics
      ..totalHour = m.totalHour?.toString()
      ..salary = m.salary
      ..basicSalary = m.basicSalary
      ..hra = m.hra
      ..dearnessAllowance = m.dearnessAllowance
      ..specialAllowance = m.specialAllowance
      ..travelAllowance = m.travelAllowance
      ..medicalAllowance = m.medicalAllowance
      ..pfApplicable = m.pfApplicable
      ..remarks = m.remarks
      ..company = m.company
      ..sites = List<String>.from(m.sites)
      ..isDeleted = m.isDeleted ?? false
      ..isLeft = m.isLeft ?? false
      ..reason = m.reason
      ..createdAt = m.createdAt
      ..updatedAt = DateTime.tryParse(m.updatedAt ?? "") ?? DateTime.now()
      ..loginEmail = m.loginEmail
      ..loginPassword = m.loginPassword
      ..isLoginEnabled = m.isLoginEnabled;
  }
}

final manpowerProvider =
    StateNotifierProvider<ManpowerNotifier, ManpowerState>((ref) {
  final repo = ref.read(manpowerRepositoryProvider);
  return ManpowerNotifier(repo);
});
