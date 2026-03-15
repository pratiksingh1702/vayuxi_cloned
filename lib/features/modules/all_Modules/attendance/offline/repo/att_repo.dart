import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import 'package:untitled2/features/modules/all_Modules/attendance/provider/AttendanceService.dart';

import '../../../../../../core/api/dio.dart';
import '../../../Manpower Details/model/manpower_model.dart';
import '../../../Manpower Details/offline/isar/manpower_isar.dart';
import '../../model/attModel.dart';
import '../isar/attendance_isar.dart';
 // AttendanceModel

class AttendanceRepository {
  final Isar isar;

  AttendanceRepository(this.isar);

  Future<void> ensureAttendanceForTeam({
    required String siteId,
    required String type,
    required String dateKey,
    required List<String> teamMemberIds,
  }) async {

    final existingRows = await isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .findAll();

    final existingIds = existingRows.map((e) => e.manpowerId).toSet();

    final manpowerRows = await isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .anyOf(teamMemberIds, (q, id) => q.manpowerIdEqualTo(id))
        .isDeletedEqualTo(false)
        .findAll();

    await isar.writeTxn(() async {

      for (final m in manpowerRows) {

        if (existingIds.contains(m.manpowerId)) {
          continue;
        }

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

  Future<void> deleteManpowerLocal(String manpowerId) async {
    final row = await isar.manpowerIsars
        .filter()
        .manpowerIdEqualTo(manpowerId)
        .findFirst();

    if (row == null) return;
    print("dpmmmmmmmmmmm");

    await isar.writeTxn(() async {
      await isar.manpowerIsars.delete(row.isarId);
    });
  }
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
  // -------------------------------
  // ✅ MANPOWER CACHE
  // -------------------------------
  /// ✅ SYNC API -> ISAR (background)
  Future<void> syncAttendanceForDate({
    required String siteId,
    required String type,
    required String dateKey,
  }) async {
    if (!await isOnline()) return;

    final date = DateTime.parse(dateKey);

    final formattedDate =
        "${date.day.toString().padLeft(2, '0')}/"
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

    final List raw =
    (res.data is Map && res.data['data'] != null)
        ? res.data['data']
        : res.data;

    final models = raw.map((e) => AttendanceModel.fromJson(e)).toList();

    final isarRows = models.map((m) {
      return AttendanceIsarMapper.fromModel(
        m,
        dateKey,
        siteId: siteId,
        type: type,
      );
    }).toList();

    await isar.writeTxn(() async {
      for (final row in isarRows) {
        // ✅ Find existing by manpowerId + dateKey + siteId + type
        final existing = await isar.attendanceIsars
            .filter()
            .siteIdEqualTo(siteId)
            .typeEqualTo(type)
            .dateKeyEqualTo(dateKey)
            .manpowerIdEqualTo(row.manpowerId)
            .findFirst();

        if (existing != null) {
          // ✅ Update existing row — preserve isarId so Isar updates in place
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
          // ✅ Insert new row
          await isar.attendanceIsars.put(row);
        }
      }
    });
  }
  Future<bool> isOnline() async {
    final result = await  Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
  String formatDateKey(DateTime date) {
    // backend expects YYYY-MM-DD
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }


  Stream<List<ManpowerModel>> watchManpower(String type) {
    return isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .isDeletedEqualTo(false)
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true)
        .map(
          (rows) => rows.map((m) {
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
          isDeleted: m.isDeleted,
          isLeft: m.isLeft,
          reason: m.reason,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt.toIso8601String(),
          loginEmail: m.loginEmail,
          loginPassword: m.loginPassword,
          isLoginEnabled: m.isLoginEnabled,
        );
      }).toList(),
    );
  }

  Future<void> syncManpowerFromApi(String type) async {
    final res = await DioClient.dio.get(
      "/manpower",
      queryParameters: {"type": type},
    );

    print("SYNC RUNNING AGAIN");

    final list =
    (res.data as List).map((e) => ManpowerModel.fromJson(e)).toList();

    final serverIds = list.map((e) => e.id ?? "").toSet();

    await isar.writeTxn(() async {

      /// ----------------------------
      /// FETCH ALL LOCAL DATA
      /// ----------------------------
      final local = await isar.manpowerIsars
          .filter()
          .typeEqualTo(type)
          .findAll();

      /// Map for fast lookup
      final Map<String, ManpowerIsar> localMap = {
        for (var item in local) item.manpowerId: item
      };

      /// ----------------------------
      /// DELETE MISSING RECORDS
      /// ----------------------------
      final idsToDelete = local
          .where((row) => !serverIds.contains(row.manpowerId))
          .map((e) => e.isarId)
          .toList();

      if (idsToDelete.isNotEmpty) {
        await isar.manpowerIsars.deleteAll(idsToDelete);
      }

      /// ----------------------------
      /// UPSERT RECORDS
      /// ----------------------------
      final List<ManpowerIsar> isarList = [];

      for (final m in list) {

        final existing = localMap[m.id ?? ""];

        final obj = existing ?? ManpowerIsar();

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

          ..isDeleted = m.isDeleted ?? false
          ..isLeft = m.isLeft ?? false
          ..reason = m.reason

          ..createdAt = m.createdAt
          ..updatedAt =
              DateTime.tryParse(m.updatedAt ?? "") ?? DateTime.now()

          ..loginEmail = m.loginEmail
          ..loginPassword = m.loginPassword
          ..isLoginEnabled = m.isLoginEnabled;

        isarList.add(obj);
      }

      await isar.manpowerIsars.putAll(isarList);
    });
  }

  // -------------------------------
  // ✅ ATTENDANCE CACHE
  // -------------------------------
  Stream<List<AttendanceModel>> watchAttendance({
    required String siteId,
    required String type,
    required String dateKey,
  }) {
    return isar.attendanceIsars
        .filter()
        .siteIdEqualTo(siteId)
        .typeEqualTo(type)
        .dateKeyEqualTo(dateKey)
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .asyncMap((rows) async {
      // load manpower rows once for mapping
      final manpowerRows = await isar.manpowerIsars.filter().typeEqualTo(type).findAll();
      final manpowerMap = {for (final m in manpowerRows) m.manpowerId: m};

      return rows.map((a) {
        final m = manpowerMap[a.manpowerId];

        final manpower = ManpowerModel(
          id: a.manpowerId,
          fullName: m?.fullName,
          designation: m?.designation,
          employeeCode: m?.employeeCode,
          phoneNumber: m?.phoneNumber,
          company: m?.company,
          type: type,
          updatedAt: m?.updatedAt.toIso8601String(),
          createdAt: m?.updatedAt.toIso8601String(),
          isDeleted: m?.isDeleted,
          isLeft: m?.isLeft,
        );

        return AttendanceModel(
          id: a.attendanceId,
          siteId: a.siteId,
          manpower: manpower,
          ot: a.ot,
          date: a.dateKey,
          status: a.status,
          totalHours: a.totalHours,
          company: a.company ?? "",
          type: a.type,
          createdAt: a.updatedAt,
          updatedAt: a.updatedAt,
        );
      }).toList();
    });
  }

  Future<void> syncAttendanceFromApi({
    required String siteId,
    required String type,
    required String dateKey, // YYYY-MM-DD
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
        ..attendanceId = x.id.isEmpty ? "${x.siteId}_${x.manpower.id}_$dateKey" : x.id
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

  /// ✅ local edit (works offline)
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
      ..attendanceId = existing?.attendanceId ?? "${siteId}_${manpowerId}_$dateKey"
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

  /// ✅ push dirty rows to backend
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

    final payload = dirty.map((x) {
      return {
        "manpowerId": x.manpowerId,
        "status": x.status,
        "totalHours": x.totalHours,
        "ot": x.ot,
        "date": dateKey,
      };
    }).toList();

    // Use your API endpoint to update/create
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
  Future<void> prepareAttendanceFromTeam({
    required String siteId,
    required String type,
    required String dateKey,
    required List<String> teamMemberIds,
  }) async {
    print("preparing ooooooooooooo");
    // 🔥 Step 1: get manpower rows from Isar
    final manpowerRows = await isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .and()
        .anyOf(
          teamMemberIds,
              (q, id) => q.manpowerIdEqualTo(id),
        )

            .and()
        .isDeletedEqualTo(false)
        .findAll();

    // 🔥 Step 2: create attendance rows if missing
    await isar.writeTxn(() async {
      for (final m in manpowerRows) {
        final existing = await isar.attendanceIsars
            .where()
            .filter()
            .siteIdEqualTo(siteId)

            .typeEqualTo(type)

            .dateKeyEqualTo(dateKey)

            .manpowerIdEqualTo(m.manpowerId)
            .findFirst();

        if (existing != null) {
          continue;
        }

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

  Future<void> _createAttendanceFromManpower({
    required String siteId,
    required String type,
    required String dateKey,
    required List<String> manpowerIds,
  }) async {
    for (final id in manpowerIds) {
      final existing = await isar.attendanceIsars
          .filter()
          .siteIdEqualTo(siteId)
          .typeEqualTo(type)
          .dateKeyEqualTo(dateKey)
          .manpowerIdEqualTo(id)
          .findFirst();

      if (existing != null) continue;

      await upsertLocalAttendance(
        siteId: siteId,
        type: type,
        dateKey: dateKey,
        manpowerId: id,
        status: "absent",
        totalHours: 0,
        ot: 0,
      );
    }
  }


}
