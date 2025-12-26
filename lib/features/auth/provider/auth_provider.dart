import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/features/modules/screen/device_id_helper.dart';
import '../../modules/all_Modules/Manpower Details/model/manpower_model.dart';
import '../../profile_page/userModel/userModel.dart';

import '../service/auth_client.dart';

// Updated AuthState class in auth_provider.dart
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? errorMessage;
  final User? user;
  final ManpowerModel? manpower;
  final String? role; // 'user' or 'manpower'

  AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.errorMessage,
    this.user,
    this.manpower,
    this.role,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? errorMessage,
    User? user,
    ManpowerModel? manpower,
    String? role,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: errorMessage,
      user: user ?? this.user,
      manpower: manpower ?? this.manpower,
      role: role ?? this.role,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    // Initialize auth state immediately
    _initializeAuthState();
  }
  Future<void> _initializeAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('auth_role');
      final manpowerData = prefs.getString('manpower_data');

      if (token != null && token.isNotEmpty && role != null) {
        if (role == 'manpower' && manpowerData != null) {
          // Load saved manpower data
          final manpowerJson = json.decode(manpowerData);
          final manpower = ManpowerModel.fromJson(manpowerJson);

          state = state.copyWith(
            isLoading: false,
            isLoggedIn: true,
            role: 'manpower',
            manpower: manpower,
          );
          print("🔐 AUTH INIT - Manpower found, logged in as manpower");
        } else if (role == 'user') {
          // User login (existing logic)
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: true,
            role: 'user',
          );
          print("🔐 AUTH INIT - Token found, user considered logged in");
        }
      } else {
        state = state.copyWith(isLoading: false, isLoggedIn: false);
        print("🔐 AUTH INIT - No token found, user not logged in");
      }
    } catch (e) {
      print("🔐 AUTH INIT - Error: $e");
      state = state.copyWith(isLoading: false, isLoggedIn: false);
    }
  }

  // ---------------------------------------------------------
  // CHECK LOGIN
  // ---------------------------------------------------------

  // ---------------------------------------------------------
  // CHECK LOGIN (Updated)
  // ---------------------------------------------------------
  Future<void> checkLogin() async {
    print("🔐 CHECKING LOGIN - Starting auth check");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('auth_role');

      if (token == null || token.isEmpty || role == null) {
        print("🔐 CHECKING LOGIN - No token found, user not logged in");
        state = state.copyWith(isLoading: false, isLoggedIn: false, user: null, manpower: null, role: null);
        return;
      }

      print("🔐 CHECKING LOGIN - Token found, role: $role");

      if (role == 'manpower') {
        // Fetch manpower data
        try {
          final manpowerData = await AuthAPI.getCurrentManpower();
          final manpower = ManpowerModel.fromJson(manpowerData['data'] ?? manpowerData);

          // Update stored manpower data
          await prefs.setString('manpower_data', json.encode(manpower.toJson()));

          print("🔐 CHECKING LOGIN - Manpower data fetched successfully");
          state = state.copyWith(
            isLoading: false,
            isLoggedIn: true,
            role: 'manpower',
            manpower: manpower,
            errorMessage: null,
          );
        } catch (e) {
          print("🔐 CHECKING LOGIN - Error fetching manpower: $e");
          // Try to load from saved data
          final savedData = prefs.getString('manpower_data');
          if (savedData != null) {
            final manpowerJson = json.decode(savedData);
            final manpower = ManpowerModel.fromJson(manpowerJson);

            state = state.copyWith(
              isLoading: false,
              isLoggedIn: true,
              role: 'manpower',
              manpower: manpower,
              errorMessage: null,
            );
          } else {
            await _clearAuthData();
            state = state.copyWith(isLoading: false, isLoggedIn: false);
          }
        }
      } else if (role == 'user') {
        // Existing user logic
        print("🔐 CHECKING LOGIN - User data fetched successfully, user is logged in");
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          role: 'user',
          errorMessage: null,
        );
      }
    } catch (e) {
      print("🔐 CHECKING LOGIN - Error: $e");
      await _clearAuthData();
      state = state.copyWith(isLoading: false, isLoggedIn: false, user: null, manpower: null, role: null);
    }
  }
  // ---------------------------------------------------------
  // SAVE + CLEAR TOKEN
  // ---------------------------------------------------------
  Future<void> saveLogin(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  Future<void> saveUserLogin(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', 'user');
    // Clear manpower data if exists
    await prefs.remove('manpower_data');
  }

  Future<void> saveManpowerLogin(String token, ManpowerModel manpower) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', 'manpower');
    // Save manpower data for quick access
    await prefs.setString('manpower_data', json.encode(manpower.toJson()));
  }

  Future<void> _clearAuthData() async {
    print("Clearing auth data");
    final prefs = await SharedPreferences.getInstance();
    await DevicePrefs.clearDeviceId();
    await prefs.remove('auth_token');
    await prefs.remove('auth_role');
    await prefs.remove('manpower_data');
  }


  // ---------------------------------------------------------
  // MANPOWER LOGIN
  // ---------------------------------------------------------
  Future<void> manpowerLogin(String employeeCode, String otp) async {
    print("🔐 MANPOWER LOGIN - Starting manpower login");

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.manpowerLogin({
        "employeeCode": employeeCode,
        "otp": otp,
      });

      final token = res['data']?['token']?['token'] ?? "";
      final manpowerData = res['data']?['manpower'];

      if (token.isEmpty || manpowerData == null) {
        throw Exception("Invalid response from server");
      }

      // Parse manpower data
      final manpower = ManpowerModel.fromJson(manpowerData);

      // Save login
      await saveManpowerLogin(token, manpower);

      print("🔐 MANPOWER LOGIN - Login successful, updating state");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        role: 'manpower',
        manpower: manpower,
        errorMessage: null,
      );
    } catch (e) {
      print("🔐 MANPOWER LOGIN - Error: $e");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------
  // LOGIN WITH OTP
  // ---------------------------------------------------------
  Future<void> loginWithOtp(String email, String otp) async {
    print("🔐 USER LOGIN WITH OTP - Starting OTP verification");

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.verifyLoginOtp(email, otp);
      final token = res['token']?['token'] ?? "";

      if (token.isEmpty) throw Exception("No token returned");

      // Fetch user data
      final userData = await AuthAPI.getCurrentUser();
      final user = User.fromJson(userData);

      await saveUserLogin(token, user);

      print("🔐 USER LOGIN WITH OTP - Login successful, updating state");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        role: 'user',
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      print("🔐 USER LOGIN WITH OTP - Error: $e");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------
  // LOGOUT (Updated)
  // ---------------------------------------------------------
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      final role = state.role;
      if (role == 'user') {
        await AuthAPI.logout();
      }
      // Manpower logout might not have an API endpoint
    } catch (_) {
      print("Logout API call failed, continuing with local logout");
    }

    await _clearAuthData();
    state = AuthState(); // Reset to initial state
  }

  Future<void> logoutAll() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthAPI.logoutAll();
    } catch (_) {}

    await _clearAuthData();
    state = AuthState();
  }
  Future<void> fetchCurrentAuth() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final role = state.role;

      if (role == 'user') {
        final res = await AuthAPI.getCurrentUser();
        final user = User.fromJson(res);

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          role: 'user',
          user: user,
        );
      } else if (role == 'manpower') {
        final res = await AuthAPI.getCurrentManpower();
        final manpower = ManpowerModel.fromJson(res['data'] ?? res);

        // Update stored data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('manpower_data', json.encode(manpower.toJson()));

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          role: 'manpower',
          manpower: manpower,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }


  // ---------------------------------------------------------
  // UPDATE USER
  // ---------------------------------------------------------
  Future<void> updateUser(User user, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.updateUser(user.id, updateData);
      final updatedUser = User.fromJson(res['user'] ?? res);

      state = state.copyWith(isLoading: false, user: updatedUser);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------
  // FETCH USER
  // ---------------------------------------------------------
  Future<void> fetchCurrentUser() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.getCurrentUser();
      final user = User.fromJson(res);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }
  // ---------------------------------------------------------
  // REGISTRATION
  // ---------------------------------------------------------
  Future<void> register(Map<String, dynamic> userData) async {
    print("🔐 REGISTRATION - Starting registration process");

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.signup(userData);

      print("🔐 REGISTRATION - Registration successful: $res");

      // ✅ AUTO-LOGIN: Save the token and update state
      final token = res['token']?['token'];
      if (token != null && token.isNotEmpty) {
        await saveLogin(token);

        // Fetch user data to complete login
        final userData = await AuthAPI.getCurrentUser();
        final user = User.fromJson(userData);

        print("🔐 REGISTRATION - Auto-login successful");
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          user: user,
          errorMessage: null,
        );
      } else {
        // If no token, just complete registration without login
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
      }

    } catch (e) {
      print("🔐 REGISTRATION - Error: $e");
      state = state.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }
  // ---------------------------------------------------------
  // EMAIL VERIFICATION
  // ---------------------------------------------------------
  Future<String> generateEmailOtp(String email) async {
    try {
      final res = await AuthAPI.generateEmailOtp(email);
      return res['message'] ?? "OTP sent successfully";
    } catch (e) {
      throw e.toString().replaceFirst("Exception: ", "");
    }
  }

  Future<String> verifyEmailOtp(String email, String otp) async {
    print("🔐 EMAIL VERIFICATION - Verifying OTP for: $email");



    try {
      final res=await AuthAPI.verifyEmailOtp(email, otp);
      return res['message'] ?? "OTP verified successfully";

      print("🔐 EMAIL VERIFICATION - Email verified successfully");

    } catch (e) {
      print("🔐 EMAIL VERIFICATION - Error: $e");
      throw e.toString().replaceFirst("Exception: ", "");
      print("🔐 EMAIL VERIFICATION - Error: $e");

    }
  }

  String _getErrorMessage(dynamic error) {
    final text = error.toString();

    if (text.contains("timeout")) return "Network timeout. Try again.";
    if (text.contains("network") || text.contains("socket")) {
      return "Network error. Check connection.";
    }
    if (text.contains("401")) return "Unauthorized. Login again.";
    if (text.contains("500")) return "Server error. Try later.";

    return "Unexpected error occurred.";
  }
}

final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
