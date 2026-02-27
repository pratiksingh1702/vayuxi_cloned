import 'package:dio/dio.dart';
import '../../../../../core/api/dio.dart';
import '../model/teamModel.dart';

class TeamApi {
  // Fetch team list
  /// 🔹 DPR MECHANICAL TEAMS
  static Future<List<TeamModel>> fetchMechanicalTeams({
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team/dpr-mechanical",
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) {
          final teamJson = e["teamId"];   // 🔥 IMPORTANT FIX
          return TeamModel.fromJson(teamJson);
        }).toList();
      } else {
        throw Exception("Failed to fetch mechanical teams");
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🔹 DPR INSULATION TEAMS
  static Future<List<TeamModel>> fetchInsulationTeams({
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team/dpr-insulation",
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) {
          final teamJson = e["teamId"];   // 🔥 IMPORTANT FIX
          return TeamModel.fromJson(teamJson);
        }).toList();
      } else {
        throw Exception("Failed to fetch insulation teams");
      }
    } catch (e) {
      rethrow;
    }
  }
  static Future<List<TeamModel>> fetchTeams({
    required String type,
    required String siteId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team",
        queryParameters: {"type": type},
      );

      if (response.statusCode == 200) {
        List data = response.data;
        print(data);
        print("Ssssssssssssss");
        return data.map((e) => TeamModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to fetch teams");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Fetch team by ID
  static Future<TeamModel> fetchTeamById({
    required String siteId,
    required String teamId,
  }) async {
    try {
      final response = await DioClient.dio.get(
        "/site/$siteId/team/$teamId",
      );

      if (response.statusCode == 200) {
        return TeamModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch team details");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create new team
  static Future<TeamModel?> createTeam({
    required String siteId,
    required String type,
    required FormData data,
  }) async {
    try {
      final response = await DioClient.dio.post(
        "/site/$siteId/team",
        queryParameters: {"type": type},
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      } else {
        throw Exception("Failed to create team");
      }
    }on DioException catch (e) {
      print("Dio error: ${e.response?.statusCode}");
      print("Dio response: ${e.response?.data}");
    }
  }

  // Update team
  static Future<TeamModel> updateTeam({
    required String siteId,
    required String teamId,
    required FormData data,
  }) async {
    try {
      final response = await DioClient.dio.put(
        "/site/$siteId/team/$teamId",
        data: data,
      );

      if (response.statusCode == 200) {
        return TeamModel.fromJson(response.data);
      } else {
        throw Exception("Failed to update team");
      }
    } catch (e) {
      rethrow;
    }
  }
  // Delete team
  static Future<void> deleteTeam({
    required String siteId,
    required String teamId,
  }) async {
    try {
      final response = await DioClient.dio.delete(
        "/site/$siteId/team/$teamId",
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete team");
      }
    } on DioException catch (e) {
      print("❌ Delete Team Dio error: ${e.response?.statusCode}");
      print("❌ Response: ${e.response?.data}");
      rethrow;
    }
  }
  static Future<void> bulkDeleteTeams({
    required List<String> teamIds,
  }) async {
    if (teamIds.isEmpty) {
      throw Exception("No team IDs provided for bulk delete");
    }

    try {
      final response = await DioClient.dio.post(
        "/team/bulk-delete",
        data: {
          "ids": teamIds,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          "Bulk delete failed: ${response.statusCode} ${response.data}",
        );
      }

      print("✅ Bulk team delete successful");
      print("📦 Deleted IDs: $teamIds");
    } on DioException catch (e, stack) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      print("❌ BULK DELETE TEAM FAILED");
      print("➡️ POST /team/bulk-delete");
      print("📟 STATUS: $status");
      print("📦 RESPONSE: $data");
      print(stack);

      rethrow;
    } catch (e, stack) {
      print("❌ UNEXPECTED BULK DELETE ERROR");
      print("📝 ERROR: $e");
      print(stack);
      rethrow;
    }
  }


}
