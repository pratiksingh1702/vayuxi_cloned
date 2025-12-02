// manpower_utils.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../Manpower Details/model/manpower_model.dart';
import '../../../Manpower Details/service/manPowerProvider.dart';
import '../../../attendance/provider/AttendanceService.dart';

class ManpowerUtils {
  /// Validate if manpower names exist in the system
  static Future<List<String>> validateManpowerNames({
    required List<String> names,
    required String type,
    required WidgetRef ref,
  }) async {
    try {
      // Load manpower list if not already loaded
      final manpowerState = ref.read(manpowerProvider);
      if (manpowerState.manpowerList.isEmpty) {
        await ref.read(manpowerProvider.notifier).fetchManpower(type);
      }

      final currentManpowerState = ref.read(manpowerProvider);
      final validManpower = currentManpowerState.manpowerList;
      print(validManpower.first.fullName);


      if (validManpower.isEmpty) {
        throw Exception("No manpower data available");
      }

      // Find invalid names
      final invalidNames = <String>[];
      for (final name in names) {
        final exists = validManpower.any((manpower) =>
        _normalizeName(manpower.fullName ?? "") == _normalizeName(name));

        if (!exists) {
          invalidNames.add(name);
        }
      }

      return invalidNames;
    } catch (e) {
      throw Exception("Error validating manpower: $e");
    }
  }

  /// Create attendance payload with manpower validation
  static Future<List<Map<String, dynamic>>> createAttendancePayload({
    required List<String> absentNames,
    required String siteId,
    required String type,
    required DateTime date,
    required WidgetRef ref,
  }) async {
    try {
      // Load manpower list
      final manpowerState = ref.read(manpowerProvider);
      if (manpowerState.manpowerList.isEmpty) {
        await ref.read(manpowerProvider.notifier).fetchManpower(type);
      }

      final currentManpowerState = ref.read(manpowerProvider);
      final allManpower = currentManpowerState.manpowerList;

      if (allManpower.isEmpty) {
        throw Exception("No manpower data available");
      }

      // Format date for API
      final formattedDate = _formatDateForAPI(date);

      // Create payload
      final payload = <Map<String, dynamic>>[];

      for (final manpower in allManpower) {
        final isAbsent = absentNames.any((absentName) =>
        _normalizeName(manpower.fullName ?? "") == _normalizeName(absentName));

        payload.add({
          "manpowerId": manpower.id,
          "date": formattedDate,
          "status": isAbsent ? "absent" : "present",
          "totalHours": isAbsent ? 0.0 : 8.0,
          "ot": 0.0,
        });
      }

      return payload;
    } catch (e) {
      throw Exception("Error creating attendance payload: $e");
    }
  }

  /// Get manpower ID by name
  static String? getManpowerIdByName({
    required String name,
    required List<ManpowerModel> manpowerList,
  }) {
    try {
      final normalizedSearchName = _normalizeName(name);
      final manpower = manpowerList.firstWhere(
            (m) => _normalizeName(m.fullName ?? "") == normalizedSearchName,
        orElse: () => ManpowerModel(id: "", fullName: ""),
      );

      return manpower.id!.isEmpty ? null : manpower.id;
    } catch (e) {
      return null;
    }
  }

  /// Normalize names for comparison (case insensitive, trim whitespace)
  static String _normalizeName(String name) {
    return name.trim().toLowerCase();
  }

  /// Format date for API (YYYY-MM-DD)
  static String _formatDateForAPI(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Format date for display (DD/MM/YYYY)
  static String formatDateForDisplay(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  /// Check if we should update or create attendance
  static Future<bool> shouldUpdateAttendance({
    required String siteId,
    required String type,
    required DateTime date,
  }) async {
    try {
      final formattedDate = formatDateForDisplay(date);

      // Try to fetch existing attendance
      final existing = await AttendanceApi.fetchAttendanceByDate(
        type: type,
        siteId: siteId,
        fromDate: formattedDate,
      );

      return existing.data != null && (existing.data as List).isNotEmpty;
    } catch (e) {
      // If no existing attendance found, we should create new
      return false;
    }
  }
}