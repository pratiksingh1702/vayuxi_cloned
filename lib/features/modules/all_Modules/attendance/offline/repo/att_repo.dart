import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar_community/isar.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/provider/AttendanceService.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../../../core/api/dio.dart';
import '../../../Manpower Details/model/manpower_model.dart';
import '../../../Manpower Details/offline/isar/manpower_isar.dart';
import '../../model/attModel.dart';
import '../isar/attendance_isar.dart';

class AttendanceRepository {
  final Isar isar;

  AttendanceRepository(this.isar);

  // ─────────────────────────────────────────────────────────────
  // MANPOWER SYNC
  // ─────────────────────────────────────────────────────────────

  Future<void> syncManpowerFromApi(String type) async {
    final res = await DioClient.dio.get(
      "/manpower",
      queryParameters: {"type": type},
    );

    print("\n🚀 SYNC (UPSERT BY EMPLOYEE CODE) START — type: $type");

    final rawList =
        (res.data as List).map((e) => ManpowerModel.fromJson(e)).toList();

    print("📦 RAW COUNT: ${rawList.length}");

    /// ✅ STEP 1: Clean + dedupe by manpowerId
    final Map<String, ManpowerModel> cleanMap = {};

    for (final m in rawList) {
      if (m.id == null || m.id!.isEmpty) {
        print("❌ SKIP garbage ID → ${m.employeeCode}");
        continue;
      }

      final existing = cleanMap[m.id!];
      if (existing == null) {
        cleanMap[m.id!] = m;
      } else {
        final oldTime = DateTime.tryParse(existing.updatedAt ?? "");
        final newTime = DateTime.tryParse(m.updatedAt ?? "");

        if (newTime != null && (oldTime == null || newTime.isAfter(oldTime))) {
          cleanMap[m.id!] = m;
        }
      }
    }

    final cleanList = cleanMap.values.toList();
    print("🧹 CLEAN COUNT: ${cleanList.length}");

    await isar.writeTxn(() async {
      final local =
          await isar.manpowerIsars.filter().typeEqualTo(type).findAll();

      /// Map by manpowerId and employeeCode for faster lookups
      final Map<String, ManpowerIsar> localById = {
        for (var item in local) item.manpowerId: item
      };

      final Map<String, ManpowerIsar> localByEmpCode = {
        for (var item in local)
          if (item.employeeCode != null && item.employeeCode!.isNotEmpty)
            item.employeeCode!: item
      };

      int inserted = 0;
      int updated = 0;
      int skipped = 0;
      int noChanges = 0;

      final List<ManpowerIsar> toSave = [];

      for (final m in cleanList) {
        ManpowerIsar? existing;

        /// 🔥 PRIMARY MATCH → employeeCode
        if (m.employeeCode != null && m.employeeCode!.isNotEmpty) {
          existing = localByEmpCode[m.employeeCode!];
        }

        /// fallback → manpowerId
        existing ??= localById[m.id!];

        if (existing != null) {
          /// Check if any field has actually changed
          final hasChanges = _hasChanges(existing, m);

          if (!hasChanges) {
            noChanges++;
            continue;
          }

          /// Optional: Check timestamp as an additional optimization
          final localTime = existing.updatedAt;
          final newTime = DateTime.tryParse(m.updatedAt ?? "");

          if (newTime != null && !newTime.isAfter(localTime)) {
            // Server timestamp is older or equal, but fields have changed
            // This could happen if server doesn't update timestamps properly
            print(
                "⚠️ Field changes detected but server timestamp is older: emp=${m.employeeCode}");
          }

          updated++;
          print("🔄 UPDATE: emp=${m.employeeCode}, id=${m.id}");

          _fillIsar(existing, m, type);

          /// IMPORTANT: ensure ID updated if backend changed it
          existing.manpowerId = m.id!;

          toSave.add(existing);
        } else {
          /// ✅ INSERT
          inserted++;
          print("➕ INSERT: emp=${m.employeeCode}, id=${m.id}");

          final obj = ManpowerIsar();
          _fillIsar(obj, m, type);

          toSave.add(obj);
        }
      }

      if (toSave.isNotEmpty) {
        await isar.manpowerIsars.putAll(toSave);
      }

      print("📊 SUMMARY:");
      print("   ➕ Inserted: $inserted");
      print("   🔄 Updated: $updated");
      print("   ⏭️ Skipped (no changes): $noChanges");
      print("   ⏭️ Skipped (timestamp check): $skipped");
      print("   💾 Saved: ${toSave.length}");
    });

    print("✅ SYNC END\n");
  }

  /// Helper method to check if any field has changed between local and server data
  bool _hasChanges(ManpowerIsar existing, ManpowerModel newData) {
    // Basic identification fields
    if (existing.manpowerId != newData.id) return true;
    if (existing.type != (newData.type ?? existing.type)) return true;
    if (existing.fullName != newData.fullName) return true;
    if (existing.designation != newData.designation) return true;
    if (existing.employeeCode != newData.employeeCode) return true;

    // Contact information
    if (existing.phoneNumber != newData.phoneNumber) return true;

    // Government IDs
    if (existing.aadharNumber != newData.aadharNumber) return true;
    if (existing.panNumber != newData.panNumber) return true;

    // Dates
    if (existing.dateOfBirth != newData.dateOfBirth) return true;
    if (existing.dateOfJoining != newData.dateOfJoining) return true;

    // Banking information
    if (existing.bankAccountNumber != newData.bankAccountNumber) return true;
    if (existing.ifscCode != newData.ifscCode) return true;
    if (existing.epfNumber != newData.epfNumber) return true;
    if (existing.uanNumber != newData.uanNumber) return true;
    if (existing.esicNumber != newData.esicNumber) return true;

    // Payroll fields
    if (existing.payBasics != newData.payBasics) return true;
    if (existing.salary != newData.salary) return true;
    if (existing.basicSalary != newData.basicSalary) return true;
    if (existing.hra != newData.hra) return true;
    if (existing.dearnessAllowance != newData.dearnessAllowance) return true;
    if (existing.specialAllowance != newData.specialAllowance) return true;
    if (existing.travelAllowance != newData.travelAllowance) return true;
    if (existing.medicalAllowance != newData.medicalAllowance) return true;
    if (existing.totalHour != newData.totalHour?.toString()) return true;
    if (existing.pfApplicable != newData.pfApplicable) return true;

    // Employment status
    if (existing.remarks != newData.remarks) return true;
    if (existing.company != newData.company) return true;
    if (existing.isDeleted != (newData.isDeleted ?? false)) return true;
    if (existing.isLeft != (newData.isLeft ?? false)) return true;
    if (existing.reason != newData.reason) return true;

    // Sites assignment (compare lists)
    if (!_areListsEqual(existing.sites, newData.sites)) return true;

    // Login credentials
    if (existing.loginEmail != newData.loginEmail) return true;
    if (existing.loginPassword != newData.loginPassword) return true;
    if (existing.isLoginEnabled != newData.isLoginEnabled) return true;

    // Timestamp comparison (server timestamp vs local)
    final serverUpdatedAt = DateTime.tryParse(newData.updatedAt ?? "");
    if (serverUpdatedAt != null && existing.updatedAt != serverUpdatedAt) {
      // If timestamps differ, consider it a change
      return true;
    }

    return false;
  }

  /// Helper to compare two lists
  bool _areListsEqual(List<String>? list1, List<String>? list2) {
    if (list1 == null && list2 == null) return true;
    if (list1 == null || list2 == null) return false;
    if (list1.length != list2.length) return false;

    // Sort both lists for consistent comparison
    final sorted1 = List<String>.from(list1)..sort();
    final sorted2 = List<String>.from(list2)..sort();

    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i] != sorted2[i]) return false;
    }
    return true;
  }

  Future<void> syncManpowerBySite({
    required String siteId,
    required String type,
  }) async {
    final res = await DioClient.dio.get(
      "/site/$siteId/manpower",
      queryParameters: {"type": type},
    );

    print("\n🚀 SYNC START — site: $siteId, type: $type");

    final rawList =
        (res.data as List).map((e) => ManpowerModel.fromJson(e)).toList();

    print("📦 RAW COUNT: ${rawList.length}");

    int skippedGarbage = 0;
    int duplicateReplaced = 0;

    final Map<String, ManpowerModel> cleanMap = {};

    for (final m in rawList) {
      if (m.id == null || m.id!.isEmpty) {
        skippedGarbage++;
        print("❌ SKIP garbage ID → ${m.employeeCode}");
        continue;
      }

      final existing = cleanMap[m.id!];
      if (existing == null) {
        cleanMap[m.id!] = m;
      } else {
        final existingTime = DateTime.tryParse(existing.updatedAt ?? "");
        final newTime = DateTime.tryParse(m.updatedAt ?? "");

        if (newTime != null &&
            (existingTime == null || newTime.isAfter(existingTime))) {
          cleanMap[m.id!] = m;
          duplicateReplaced++;
          print("♻️ DUPLICATE replaced for ID: ${m.id}");
        }
      }
    }

    final cleanList = cleanMap.values.toList();

    print("🧹 CLEAN COUNT: ${cleanList.length}");
    print("⚠️ GARBAGE SKIPPED: $skippedGarbage");
    print("♻️ DUPLICATES HANDLED: $duplicateReplaced");

    await isar.writeTxn(() async {
      final local =
          await isar.manpowerIsars.filter().typeEqualTo(type).findAll();

      final Map<String, ManpowerIsar> localMap = {
        for (var item in local) item.manpowerId: item
      };

      final Map<String, ManpowerIsar> localByEmpCode = {
        for (var item in local)
          if (item.employeeCode != null && item.employeeCode!.isNotEmpty)
            item.employeeCode!: item
      };

      print("💾 LOCAL COUNT: ${local.length}");

      int updated = 0;
      int inserted = 0;
      int noChanges = 0;

      final List<ManpowerIsar> toSave = [];

      for (final m in cleanList) {
        ManpowerIsar? existing;

        /// Primary match by employeeCode
        if (m.employeeCode != null && m.employeeCode!.isNotEmpty) {
          existing = localByEmpCode[m.employeeCode!];
        }

        /// Fallback to manpowerId
        existing ??= localMap[m.id!];

        /// Check for conflicts
        if (m.employeeCode != null) {
          final conflict = localByEmpCode[m.employeeCode!];
          if (conflict != null && conflict.manpowerId != m.id) {
            print(
                "💥 CONFLICT employeeCode=${m.employeeCode} between ${conflict.manpowerId} and ${m.id}");
          }
        }

        if (existing != null) {
          /// Check if any field has actually changed
          final hasChanges = _hasChanges(existing, m);

          if (!hasChanges) {
            noChanges++;
            continue;
          }

          updated++;
          print("🔄 UPDATE: ${m.id}");

          _fillIsar(existing, m, type);
          toSave.add(existing);
        } else {
          inserted++;
          print("➕ INSERT: ${m.id}");

          final obj = ManpowerIsar();
          _fillIsar(obj, m, type);
          toSave.add(obj);
        }
      }

      if (toSave.isNotEmpty) {
        await isar.manpowerIsars.putAll(toSave);
      }

      // print("📊 SUMMARY:");
      // print("   ➕ Inserted: $inserted");
      // print("   🔄 Updated: $updated");
      // print("   ⏭️ Skipped (no changes): $noChanges");
      // print("   💾 Saved: ${toSave.length}");
    });

    print("✅ SYNC END\n");
  }

  void _fillIsar(ManpowerIsar obj, ManpowerModel m, String type) {
    obj
      ..manpowerId = m.id ?? ""
      ..type = m.type ?? type
      ..fullName = m.fullName
      ..designation = m.designation
      ..employeeCode = (m.employeeCode == null || m.employeeCode!.isEmpty)
          ? null
          : m.employeeCode
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

  // ─────────────────────────────────────────────────────────────
  // MANPOWER WATCH
  // ─────────────────────────────────────────────────────────────

  Stream<List<ManpowerModel>> watchManpower(String type) {
    return isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map(_isarToModel).toList());
  }

  Stream<List<ManpowerModel>> watchManpowerBySite({
    required String siteId,
    required String type,
  }) {
    return isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .isDeletedEqualTo(false)
        .sitesElementEqualTo(siteId)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map(_isarToModel).toList());
  }

  ManpowerModel _isarToModel(ManpowerIsar m) {
    return ManpowerModel(
      id: m.manpowerId,
      type: m.type,
      fullName: m.fullName,
      designation: m.designation,
      employeeCode: m.employeeCode,
      phoneNumber: m.phoneNumber,
      aadharNumber: m.aadharNumber,
      panNumber: m.panNumber,
      dateOfBirth: m.dateOfBirth,
      dateOfJoining: m.dateOfJoining,
      bankAccountNumber: m.bankAccountNumber,
      ifscCode: m.ifscCode,
      epfNumber: m.epfNumber,
      uanNumber: m.uanNumber,
      esicNumber: m.esicNumber,
      payBasics: m.payBasics,
      totalHour: m.totalHour,
      salary: m.salary,
      basicSalary: m.basicSalary,
      hra: m.hra,
      dearnessAllowance: m.dearnessAllowance,
      specialAllowance: m.specialAllowance,
      travelAllowance: m.travelAllowance,
      medicalAllowance: m.medicalAllowance,
      pfApplicable: m.pfApplicable,
      remarks: m.remarks,
      company: m.company,
      sites: List<String>.from(m.sites),
      isDeleted: m.isDeleted,
      isLeft: m.isLeft,
      reason: m.reason,
      createdAt: m.createdAt,
      updatedAt: m.updatedAt.toIso8601String(),
      loginEmail: m.loginEmail,
      loginPassword: m.loginPassword,
      isLoginEnabled: m.isLoginEnabled,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MANPOWER LOCAL OPS
  // ─────────────────────────────────────────────────────────────

  Future<void> deleteManpowerLocal(String manpowerId) async {
    final row = await isar.manpowerIsars
        .filter()
        .manpowerIdEqualTo(manpowerId)
        .findFirst();
    if (row == null) return;
    await isar.writeTxn(() async {
      await isar.manpowerIsars.delete(row.isarId);
    });
  }

  Future<void> deleteManpowerLocalBulk(List<String> manpowerIds) async {
    final ids = manpowerIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return;

    final localIsarIds = <int>[];
    for (final manpowerId in ids) {
      final row = await isar.manpowerIsars
          .filter()
          .manpowerIdEqualTo(manpowerId)
          .findFirst();
      if (row != null) {
        localIsarIds.add(row.isarId);
      }
    }

    if (localIsarIds.isEmpty) return;

    await isar.writeTxn(() async {
      await isar.manpowerIsars.deleteAll(localIsarIds);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // ATTENDANCE — ENSURE ROWS
  // ─────────────────────────────────────────────────────────────

  /// Creates missing absent rows for every manpower that has [siteId] in
  /// their [sites] array. No team filter — all site-assigned manpower get a row.
  Future<void> ensureAttendanceForSite({
    required String siteId,
    required String type,
    required String dateKey,
  }) async {
    final existingRows = await isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .findAll();

    final existingAttIds = existingRows.map((e) => e.manpowerId).toSet();

    // ✅ ONLY site filter — show every manpower assigned to this site
    final manpowerRows = await isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .isDeletedEqualTo(false)
        .sitesElementEqualTo(siteId)
        .findAll();

    await isar.writeTxn(() async {
      for (final m in manpowerRows) {
        if (existingAttIds.contains(m.manpowerId)) continue;

        final row = AttendanceIsar()
          ..attendanceId = "${siteId}_${m.manpowerId}_$dateKey"
          ..siteId = siteId
          ..type = type
          ..dateKey = dateKey
          ..manpowerId = m.manpowerId
          ..status = "absent"
          ..totalHours = 0
          ..ot = 0
          ..company = m.company
          ..isDeleted = false
          ..isDirty = false
          ..updatedAt = DateTime.now();

        await isar.attendanceIsars.put(row);
      }
    });
  }

  /// Kept for backward-compat call sites that still pass teamMemberIds.
  /// Internally delegates to [ensureAttendanceForSite] — team IDs ignored.
  Future<void> ensureAttendanceForTeam({
    required String siteId,
    required String type,
    required String dateKey,
    required List<String> teamMemberIds, // ignored
  }) =>
      ensureAttendanceForSite(siteId: siteId, type: type, dateKey: dateKey);

  Future<int> getAttendanceCount({
    required String siteId,
    required String type,
    required String dateKey,
  }) async {
    return await isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .count();
  }

  Future<void> syncAttendanceForDate({
    required String siteId,
    required String type,
    required String dateKey,
  }) async {
    if (!await isOnline()) return;

    final date = DateTime.parse(dateKey);
    final formattedDate = "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";

    dynamic res;
    try {
      res = await AttendanceApi.fetchAttendanceByDate(
        type: type,
        siteId: siteId,
        fromDate: formattedDate,
      );
    } catch (e) {
      print("⚠️ Attendance API error: $e");
      return;
    }

    final List raw = (res.data is Map && res.data['data'] != null)
        ? res.data['data']
        : res.data;

    final models = raw.map((e) => AttendanceModel.fromJson(e)).toList();
    final isarRows = models
        .map((m) => AttendanceIsarMapper.fromModel(m, dateKey,
            siteId: siteId, type: type))
        .toList();

    await isar.writeTxn(() async {
      for (final row in isarRows) {
        final existing = await isar.attendanceIsars
            .filter()
            .siteIdEqualTo(siteId)
            .typeEqualTo(type)
            .dateKeyEqualTo(dateKey)
            .manpowerIdEqualTo(row.manpowerId)
            .findFirst();

        if (existing != null) {
          existing
            ..attendanceId = row.attendanceId
            ..status = row.status
            ..totalHours = row.totalHours
            ..ot = row.ot
            ..company = row.company
            ..isDeleted = row.isDeleted
            ..isDirty = false
            ..updatedAt = row.updatedAt;
          await isar.attendanceIsars.put(existing);
        } else {
          await isar.attendanceIsars.put(row);
        }
      }
    });
  }

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  // ─────────────────────────────────────────────────────────────
  // ATTENDANCE WATCH
  // ─────────────────────────────────────────────────────────────

  /// Streams attendance rows for a date.
  /// Only filter: manpower must have [siteId] in their [sites] array.
  /// Team membership is irrelevant.
  Stream<List<AttendanceModel>> watchAttendance({
    required String siteId,
    required String type,
    required String dateKey,
    List<String> teamMemberIds = const [], // kept for signature compat, unused
  }) {
    final attendanceStream = isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);

    // ✅ SITE-ONLY filter — no team gate
    final manpowerStream = isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .isDeletedEqualTo(false)
        .sitesElementEqualTo(siteId)
        .watch(fireImmediately: true);

    return Rx.combineLatest2(
      attendanceStream,
      manpowerStream,
      (List<AttendanceIsar> attendanceRows, List<ManpowerIsar> manpowerRows) {
        final attendanceMap = {for (final a in attendanceRows) a.manpowerId: a};

        return manpowerRows.map((m) {
          final att = attendanceMap[m.manpowerId];
          return AttendanceModel(
            id: att?.attendanceId ?? "${siteId}_${m.manpowerId}_$dateKey",
            siteId: siteId,
            manpower: ManpowerModel(
              id: m.manpowerId,
              fullName: m.fullName,
              designation: m.designation,
              company: m.company,
              totalHour: m.totalHour,
            ),
            ot: att?.ot ?? 0,
            date: dateKey,
            status: att?.status ?? "absent",
            totalHours: att?.totalHours ?? 0,
            company: m.company ?? "",
            type: type,
            createdAt: att?.updatedAt ?? DateTime.now(),
            updatedAt: att?.updatedAt ?? DateTime.now(),
          );
        }).toList();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ATTENDANCE LOCAL OPS
  // ─────────────────────────────────────────────────────────────

  Future<void> syncAttendanceFromApi({
    required String siteId,
    required String type,
    required String dateKey,
  }) async {
    final response = await DioClient.dio.get(
      "/site/$siteId/attendance/attendance",
      queryParameters: {"type": type, "fromDate": dateKey},
    );

    final list = (response.data as List)
        .map((e) => AttendanceModel.fromJson(e))
        .toList();

    final isarList = list.map((x) {
      return AttendanceIsar()
        ..attendanceId =
            x.id.isEmpty ? "${x.siteId}_${x.manpower.id}_$dateKey" : x.id
        ..siteId = siteId
        ..type = type
        ..dateKey = dateKey
        ..manpowerId = x.manpower.id ?? ""
        ..ot = x.ot
        ..status = x.status
        ..totalHours = x.totalHours
        ..company = x.company
        ..isDeleted = false
        ..isDirty = false
        ..updatedAt = x.updatedAt;
    }).toList();

    await isar.writeTxn(() async {
      await isar.attendanceIsars.putAll(isarList);
    });
  }

  Future<void> upsertLocalAttendance({
    required String siteId,
    required String type,
    required String dateKey,
    required String manpowerId,
    required String status,
    required double totalHours,
    required double ot,
    String? company,
  }) async {
    final existing = await isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .manpowerIdEqualTo(manpowerId)
        .findFirst();

    final row = existing ?? AttendanceIsar();
    row
      ..attendanceId =
          existing?.attendanceId ?? "${siteId}_${manpowerId}_$dateKey"
      ..siteId = siteId
      ..type = type
      ..dateKey = dateKey
      ..manpowerId = manpowerId
      ..status = status
      ..totalHours = totalHours
      ..ot = ot
      ..company = company
      ..isDeleted = false
      ..isDirty = true
      ..updatedAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.attendanceIsars.put(row);
    });
  }

  Future<void> pushDirtyAttendance({
    required String siteId,
    required String type,
    required String dateKey,
  }) async {
    final dirty = await isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .isDirtyEqualTo(true)
        .findAll();

    if (dirty.isEmpty) return;

    final payload = dirty
        .map((x) => {
              "manpowerId": x.manpowerId,
              "status": x.status,
              "totalHours": x.totalHours,
              "ot": x.ot,
              "date": dateKey,
            })
        .toList();

    await DioClient.dio.post(
      "/site/$siteId/attendance/update",
      queryParameters: {"type": type, "fromDate": dateKey},
      data: payload,
    );

    await isar.writeTxn(() async {
      for (final d in dirty) {
        d.isDirty = false;
        await isar.attendanceIsars.put(d);
      }
    });
  }

  /// Kept for backward-compat. Delegates to [ensureAttendanceForSite].
  Future<void> prepareAttendanceFromTeam({
    required String siteId,
    required String type,
    required String dateKey,
    required List<String> teamMemberIds, // ignored
  }) =>
      ensureAttendanceForSite(siteId: siteId, type: type, dateKey: dateKey);
}
