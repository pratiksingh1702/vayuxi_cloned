import 'package:isar/isar.dart';
import 'package:untitled2/features/modules/all_Modules/Manpower%20Details/offline/isar/manpower_isar.dart';

import '../../../../../../core/local/isar_db.dart';
import '../../model/manpower_model.dart';
import '../../service/manpowerService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';




class ManpowerRepository {
  final Isar isar = AppIsarDB.isar;

  /// ------------------------------------------------
  /// WATCH (UI listens here)
  /// ------------------------------------------------
  Stream<List<ManpowerModel>> watchManpower(String type) {
    return isar.manpowerIsars
        .filter()
        .typeEqualTo(type)
        .and()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true)
        .map((rows) {
      return rows.map((m) {
        return ManpowerModel(
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
        );
      }).toList();
    });
  }

  /// ------------------------------------------------
  /// SYNC FROM API → ISAR
  /// ------------------------------------------------
  Future<void> syncFromApi(String type) async {
    final res = await ManpowerAPI.fetchManpower(type);

    if (res["success"] != true) return;

    final List list = res["data"];

    final isarRows = list.map((e) {
      final m = ManpowerModel.fromJson(e);

      return ManpowerIsar()
        ..manpowerId = m.id ?? ""
        ..type = type
        ..fullName = m.fullName
        ..designation = m.designation
        ..employeeCode = m.employeeCode
        ..phoneNumber = m.phoneNumber
        ..company = m.company
        ..isDeleted = m.isDeleted ?? false
        ..isLeft = m.isLeft ?? false
        ..updatedAt = DateTime.tryParse(m.updatedAt ?? "") ?? DateTime.now();
    }).toList();

    await isar.writeTxn(() async {
      await isar.manpowerIsars.putAll(isarRows);
    });
  }
}
final manpowerRepositoryProvider = Provider((ref) {
  return ManpowerRepository();
});
final manpowerOfflineProvider =
StreamProvider.family<List<ManpowerModel>, String>((ref, type) {
  final repo = ref.read(manpowerRepositoryProvider);

  // background sync (if online)
  Future.microtask(() => repo.syncFromApi(type));

  return repo.watchManpower(type);
});
