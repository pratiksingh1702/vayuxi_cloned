import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../model/attModel.dart';
import '../../Manpower Details/model/manpower_model.dart';
import 'AttendanceService.dart';

final attendanceNotifierProvider =
StateNotifierProvider<AttendanceNotifier, AsyncValue<List<AttendanceModel>>>(
      (ref) => AttendanceNotifier(AttendanceApi()),
);

class AttendanceNotifier extends StateNotifier<AsyncValue<List<AttendanceModel>>> {
  final AttendanceApi _api;
  DateTime? _selectedDate;

  AttendanceNotifier(this._api) : super(const AsyncValue.loading());

  /// ✅ Fetch manpower list with date - tries to get existing attendance first
  Future<void> fetchManpower(String type, String siteId, DateTime date) async {
    try {
      state = const AsyncValue.loading();
      _selectedDate = date;

      final formattedDisplayDate = _formatDateForDisplay(date); // DD/MM/YYYY
      print('🔄 Fetching manpower for date: $formattedDisplayDate');

      // First try to fetch existing attendance for the specific date using the correct endpoint
      try {
        final existingAttendance = await AttendanceApi.fetchAttendanceByDate(
          type: type,
          siteId: siteId,
          fromDate: formattedDisplayDate,
        );

        if (existingAttendance.data != null && (existingAttendance.data as List).isNotEmpty) {
          print('✅ Found existing attendance data: ${(existingAttendance.data as List).length} records');

          // Convert existing attendance data to AttendanceModel
          final List<AttendanceModel> data = (existingAttendance.data as List).map((e) {
            return AttendanceModel.fromJson(e);
          }).toList();

          state = AsyncValue.data(data);
          return;
        } else {
          print('ℹ️ No existing attendance found for $formattedDisplayDate');
        }
      } catch (e) {
        print('ℹ️ No existing attendance found, loading manpower list: $e');
      }

      // Fetch manpower list and initialize with default values
      final res = await AttendanceApi.fetchAttendance2(type: type, siteId: siteId);

      final List<AttendanceModel> data = (res.data as List).map((e) {
        final manpower = ManpowerModel.fromJson(e);
        return AttendanceModel(
          id: "", // Empty ID for new records
          siteId: siteId,
          manpower: manpower,
          ot: 0,
          date: formattedDisplayDate,
          status: "absent", // Default status
          totalHours: 0, // Default hours
          company: manpower.company ?? "",
          type: type,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      print('✅ Loaded ${data.length} manpower records');
      state = AsyncValue.data(data);
    } catch (e, st) {
      print('❌ Error fetching manpower: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// ✅ Post multiple attendance (create new)
  Future<void> postMultipleAttendance({
    required List<Map<String, dynamic>> payload,
    required String type,
    required String siteId,
  }) async {
    try {
      print('🆕 Creating ${payload.length} new attendance records');

      await AttendanceApi.postMultipleAttendance(
        data: payload,
        type: type,
        siteId: siteId,
      );

      print('✅ New attendance records created successfully');

      // Refresh the data
      if (_selectedDate != null) {
        await fetchManpower(type, siteId, _selectedDate!);
      }

    } catch (e, st) {
      print('❌ Error creating attendance: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// ✅ Update multiple attendance (update existing)
  Future<void> updateMultipleAttendance({
    required List<Map<String, dynamic>> payload,
    required String type,
    required String siteId,
    required String date,
  }) async {
    try {
      print('🔄 Updating ${payload.length} existing attendance records');

      await AttendanceApi.updateMultipleAttendance(
        data: payload,
        type: type,
        siteId: siteId,
        fromDate: date,
      );

      print('✅ Attendance records updated successfully');

      // Refresh the data
      if (_selectedDate != null) {
        await fetchManpower(type, siteId, _selectedDate!);
      }

    } catch (e, st) {
      print('❌ Error updating attendance: $e');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// ✅ Update local state
  void updateEmployee(int index, AttendanceModel updated) {
    final current = state.value;
    if (current == null) return;

    final List<AttendanceModel> newList = [...current];
    newList[index] = updated;
    state = AsyncValue.data(newList);
  }

  /// ✅ Toggle all present/absent
  void markAllPresent(bool present) {
    final current = state.value;
    if (current == null) return;

    final List<AttendanceModel> updated = current.map((e) {
      return e.copyWith(
        status: present ? "present" : "absent",
        totalHours: present ? 8 : 0,
        ot: present ? e.ot : 0,
      );
    }).toList();
    state = AsyncValue.data(updated);
  }

  String _formatDateForDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
}