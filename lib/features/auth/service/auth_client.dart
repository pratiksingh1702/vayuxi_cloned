import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/dio.dart';

class AuthAPI {
  static final dio = DioClient.dio;

  /// Helper: Get or Create Device ID
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("device_id");

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString("device_id", id);
    }

    return id;
  }

  // -----------------------------------------------------
  // 🚀 DEVICE AUTHORIZATION
  // -----------------------------------------------------

  /// 1️⃣ Generate Device OTP
  static Future<Map<String, dynamic>> generateDeviceOtp() async {
    final deviceId = await _getDeviceId();

    final res = await dio.post(
      "/auth/generate-device-otp",

    );

    return res.data;
  }

  /// 2️⃣ Verify Device OTP
  static Future<Map<String, dynamic>> verifyDeviceOtp(Map<String, dynamic> data) async {
    final res = await dio.post("/auth/verify-device-otp", data: data);
    return res.data;
  }

  // -----------------------------------------------------
  // EXISTING METHODS (UNTOUCHED)
  // -----------------------------------------------------


  static Future<Map<String, dynamic>> signup(Map<String, dynamic> data) async {
    try {
      print("🚀 SIGNUP API - Sending data: $data");

      // Remove null values like React Native does
      final cleanData = Map<String, dynamic>.from(data);
      cleanData.removeWhere((key, value) => value == null);

      final res = await dio.post(
        "/auth/signup", // Make sure path matches
        data: cleanData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print("✅ SIGNUP API - Success: ${res.statusCode}");
      print("📦 SIGNUP API - Response: ${res.data}");

      return res.data;
    } on DioException catch (e) {
      print("❌ SIGNUP API - Dio Error: ${e.message}");
      print("❌ SIGNUP API - Response: ${e.response?.data}");
      print("❌ SIGNUP API - Status: ${e.response?.statusCode}");

      // Extract error message like React Native
      final errorData = e.response?.data;
      String errorMessage = "Registration failed";

      if (errorData is Map) {
        errorMessage = errorData['message'] ??
            errorData['error'] ??
            "Registration failed";
      } else if (errorData is String) {
        errorMessage = errorData;
      }

      throw Exception(errorMessage);
    } catch (e) {
      print("❌ SIGNUP API - General Error: $e");
      rethrow;
    }
  }

  // Also update your OTP methods to match React Native
  static Future<Map<String, dynamic>> generateEmailOtp(String email) async {
    try {
      final res = await dio.post(
          "/auth/generate-email-otp",
          data: {"email": email}
      );
      return res.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMessage = "Failed to send OTP";

      if (errorData is Map) {
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    try {
      final res = await dio.post(
          "/auth/verify-email-otp",
          data: {"email": email, "otp": otp}
      );
      return res.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMessage = "OTP verification failed";

      if (errorData is Map) {
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> generateLoginOtp(String email) async {
    final res =
    await dio.post("/auth/generate-login-otp", data: {"email": email});
    return res.data;
  }

  static Future<Map<String, dynamic>> verifyLoginOtp(
      String email, String otp) async {
    final res =
    await dio.post("/auth/verify-login", data: {"email": email, "otp": otp});

    if (res.statusCode == 200) {
      return res.data;
    } else {
      throw Exception(res.data['message'] ?? "Failed to fetch user");
    }
  }

  static Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> data) async {
    final res = await dio.post("/user/$id", data: data);
    return res.data;
  }

  static Future<Map<String, dynamic>> logout() async {
    final res = await dio.post("/auth/logout");
    return res.data;
  }

  static Future<Map<String, dynamic>> logoutAll() async {
    final res = await dio.post("/auth/logout-all-device");
    return res.data;
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await dio.get('/user/me');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(response.data['message'] ?? "Failed to fetch user");
    }
  }

  static Future<Map<String, dynamic>> getUserById(String id) async {
    final res = await dio.get("/user/$id");
    return res.data;
  }
}
