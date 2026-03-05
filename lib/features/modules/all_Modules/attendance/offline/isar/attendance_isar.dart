import 'package:isar/isar.dart';

import '../../../Manpower Details/model/manpower_model.dart';
import '../../model/attModel.dart';

part 'attendance_isar.g.dart';

@collection
class AttendanceIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String attendanceId; // API id OR local generated id

  @Index()
  late String siteId;

  @Index()
  late String type;

  /// store date normalized as YYYY-MM-DD
  @Index()
  late String dateKey;

  @Index()
  late String manpowerId;

  late double ot;
  late String status;
  late double totalHours;

  late String? company;

  late bool isDeleted;

  /// OFFLINE SYNC FLAGS
  @Index()
  late bool isDirty;

  /// timestamp for conflict resolution
  late DateTime updatedAt;
}

extension AttendanceIsarMapper on AttendanceIsar {
  AttendanceModel toModel() {
    return AttendanceModel(
      id: attendanceId,
      siteId: siteId,
      manpower: ManpowerModel(id: manpowerId),
      ot: ot,
      date: dateKey,
      status: status,
      totalHours: totalHours,
      company: company ?? '',
      type: type,
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );
  }

  /// ✅ create Isar object from AttendanceModel
  static AttendanceIsar fromModel(
      AttendanceModel m,
      String dateKey, {
        required String siteId,
        required String type,
      }) {
    return AttendanceIsar()
      ..attendanceId = m.id
      ..siteId = siteId
      ..type = type
      ..dateKey = dateKey
      ..manpowerId = (m.manpower.id ?? '')
      ..ot = m.ot
      ..status = m.status
      ..totalHours = m.totalHours
      ..company = m.company
      ..isDeleted = false
      ..isDirty = false
      ..updatedAt = DateTime.now();
  }
}

