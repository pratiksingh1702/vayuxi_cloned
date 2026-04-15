import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/features/modules/screen/device_id_helper.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/dio.dart';

class AuthAPI {
  static final dio = DioClient.dio;
  // Add these methods to your AuthAPI class in auth_client.dart

// -----------------------------------------------------
// MANPOWER AUTHENTICATION
// -----------------------------------------------------

  /// 1️⃣ Manpower Login with Employee Code and OTP
  static Future<Map<String, dynamic>> manpowerLogin(
      Map<String, dynamic> data) async {
    try {
      print("🚀 MANPOWER LOGIN - Sending data: $data");

      final res = await dio.post(
        "/manpower-auth/login",
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print("✅ MANPOWER LOGIN - Success: ${res.statusCode}");
      print("📦 MANPOWER LOGIN - Response: ${res.data}");

      return res.data;
    } on DioException catch (e) {
      print("❌ MANPOWER LOGIN - Dio Error: ${e.message}");
      print("❌ MANPOWER LOGIN - Response: ${e.response?.data}");
      print("❌ MANPOWER LOGIN - Status: ${e.response?.statusCode}");

      final errorData = e.response?.data;
      String errorMessage = "Manpower login failed";

      if (errorData is Map) {
        errorMessage = errorData['message'] ??
            errorData['error'] ??
            "Manpower login failed";
      } else if (errorData is String) {
        errorMessage = errorData;
      }

      throw Exception(errorMessage);
    } catch (e) {
      print("❌ MANPOWER LOGIN - General Error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getGracePeriodStatus() async {
    final res = await dio.get("/auth/grace-period-status");
    return res.data as Map<String, dynamic>;
  }

  /// 2️⃣ Get Current Manpower (after login)
  static Future<Map<String, dynamic>> getCurrentManpower() async {
    final response = await dio.get('/manpower-auth/me');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(response.data['message'] ?? "Failed to fetch manpower");
    }
  }

  // In AuthAPI class — add this new method, don't touch existing ones

  static Future<Map<String, dynamic>> checkDeviceTrust() async {
    final existingDeviceId = await DevicePrefs.getDeviceId();
    final deviceId = existingDeviceId ?? await _getDeviceId();
    print('🔍 [checkDeviceTrust] deviceId: $deviceId');
    final res = await dio.post(
      "/auth/check-device-trust",
      data: {"deviceId": deviceId},
    );
    return res.data as Map<String, dynamic>;
  }

  /// Helper: Get or Create Device ID
  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("actual_device_id");

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString("actual_device_id", id);
    }

    return id;
  }

  // -----------------------------------------------------
  // 🚀 DEVICE AUTHORIZATION
  // -----------------------------------------------------

  /// 1️⃣ Generate Device OTP
  static Future<Map<String, dynamic>> generateDeviceOtp() async {
    final deviceId = await _getDeviceId();

    try {
      print("🚀 GENERATE DEVICE OTP - Sending request");
      print("📱 Device ID: $deviceId");

      final res = await dio.post(
        "/auth/generate-device-otp",
        data: {"deviceId": deviceId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print("✅ GENERATE DEVICE OTP - Success: ${res.statusCode}");

      final responseData = res.data;

      // Check if response is successful
      if (responseData['success'] == true) {
        print("✅ GENERATE DEVICE OTP - OTP generated successfully");
        return responseData;
      } else {
        // Handle API success: false case
        final errorMessage =
            responseData['message'] ?? "Failed to generate OTP";
        print("❌ GENERATE DEVICE OTP - API returned error: $errorMessage");
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print("❌ GENERATE DEVICE OTP - Dio Error: ${e.message}");
      print("❌ GENERATE DEVICE OTP - Error Type: ${e.type}");

      String errorMessage = "Failed to generate OTP. Please try again.";

      // Handle different Dio error types
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              "Connection timeout. Please check your internet connection.";
          break;

        case DioExceptionType.connectionError:
          errorMessage = "No internet connection. Please check your network.";
          break;

        case DioExceptionType.badCertificate:
          errorMessage = "Security certificate error. Please try again later.";
          break;

        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          final errorData = e.response?.data;

          print("❌ GENERATE DEVICE OTP - Status Code: $statusCode");
          print("❌ GENERATE DEVICE OTP - Error Response: $errorData");

          if (statusCode == 400) {
            errorMessage = "Bad request. Please try again.";
          } else if (statusCode == 401) {
            errorMessage = "Unauthorized. Please login again.";
          } else if (statusCode == 403) {
            errorMessage = "Access denied. Please contact support.";
          } else if (statusCode == 404) {
            errorMessage = "Device OTP service not found.";
          } else if (statusCode == 429) {
            errorMessage =
                "Too many requests. Please wait before trying again.";
          } else if (statusCode == 500) {
            errorMessage = "Server error. Please try again later.";
          }

          // Try to extract error message from response
          if (errorData is Map) {
            final apiMessage = errorData['message'] ??
                errorData['error'] ??
                errorData['details']?.toString();
            if (apiMessage != null && apiMessage.isNotEmpty) {
              errorMessage = apiMessage.toString();
            }
          } else if (errorData is String) {
            if (errorData.isNotEmpty) {
              errorMessage = errorData;
            }
          }
          break;

        case DioExceptionType.cancel:
          errorMessage = "Request cancelled.";
          break;

        default:
          errorMessage = "Network error. Please check your connection.";
      }

      throw Exception(errorMessage);
    } catch (e) {
      // Handle any other exceptions
      print("❌ GENERATE DEVICE OTP - Unexpected Error: $e");

      String errorMessage = "An unexpected error occurred.";

      if (e is FormatException) {
        errorMessage = "Invalid response from server.";
      } else if (e is TypeError) {
        errorMessage = "Data format error. Please try again.";
      }

      throw Exception(errorMessage);
    }
  }

  /// 2️⃣ Verify Device OTP
  static Future<Map<String, dynamic>> verifyDeviceOtp(
      Map<String, dynamic> data) async {
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
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? "Registration failed";
      } else if (errorData is String) {
        errorMessage = errorData;
      }

      throw Exception(errorMessage);
    } catch (e) {
      print("❌ SIGNUP API - General Error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> sendPhoneOtp(String phoneNumber) async {
    try {
      final res = await dio.post(
        "/auth/send-otp",
        data: {"phoneNumber": phoneNumber},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMessage = "Failed to send OTP";

      if (errorData is Map) {
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } else if (errorData is String && errorData.isNotEmpty) {
        errorMessage = errorData;
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneOtp(
      String phoneNumber, String otp) async {
    try {
      final res = await dio.post(
        "/auth/verify-otp",
        data: {"phoneNumber": phoneNumber, "otp": otp},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMessage = "OTP verification failed";

      if (errorData is Map) {
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } else if (errorData is String && errorData.isNotEmpty) {
        errorMessage = errorData;
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> completeProfile({
    required String fullName,
    required String email,
    String? companyName,
  }) async {
    try {
      final payload = <String, dynamic>{
        "fullName": fullName,
        "email": email,
      };
      if (companyName != null && companyName.trim().isNotEmpty) {
        payload["companyName"] = companyName.trim();
      }

      final res = await dio.post(
        "/auth/complete-profile",
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      final errorData = e.response?.data;
      String errorMessage = "Failed to complete profile";

      if (errorData is Map) {
        errorMessage =
            errorData['message'] ?? errorData['error'] ?? errorMessage;
      } else if (errorData is String && errorData.isNotEmpty) {
        errorMessage = errorData;
      }
      throw Exception(errorMessage);
    }
  }

  static Future<Map<String, dynamic>> updateUser(
    String id,
    dynamic data, // 👈 allow FormData
  ) async {
    final res = await dio.put(
      "/user/$id",
      data: data,
      options: Options(
        contentType: Headers.multipartFormDataContentType,
      ),
    );
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
