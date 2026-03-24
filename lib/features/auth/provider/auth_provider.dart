// features/auth/provider/auth_provider.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// CHANGE FROM PREVIOUS VERSION: register() method
// ═══════════════════════════════════════════════════════════════════════════
//
// The signup API now returns:
//   { user, token, deviceId, gracePeriodEndsAt, isWithinGracePeriod }
//
// Previously: register() only saved the auth token after signup.
// Now:        register() also saves the deviceId from signup response.
//
// WHY THIS MATTERS:
//   The deviceId returned at signup IS the registrationDeviceId.
//   Backend stores it as user.registrationDeviceId.
//   If we don't save it locally and send it in Dio headers, backend
//   cannot identify this as a primary device → will return
//   requiresDeviceAuth=true for this device after grace period.
//
//   With it saved: Device A (registration device) → permanently trusted.
//   Without it:    Device A looks like Device C after 24h → OTP prompted.
//
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/features/modules/screen/device_id_helper.dart';
import '../../../core/router/app_access.dart';
import '../../modules/all_Modules/Manpower Details/model/manpower_model.dart';
import '../../profile_page/userModel/userModel.dart';

import '../service/auth_client.dart';
import '../service/guard.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// AUTH NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState(isLoading: true)) {
    _initializeAuthState();
  }

  // ── Init from cache ───────────────────────────────────────────────────────

  Future<void> _initializeAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('auth_role');
      final userData = prefs.getString('user_data');

      if (role == 'user' && userData != null) {
        final userJson = json.decode(userData);
        final user = User.fromJson(userJson);

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          role: 'user',
          user: user,
        );

        debugPrint(userData);
        print("🔐 AUTH INIT - User restored from cache");
        return;
      }

      final manpowerData = prefs.getString('manpower_data');

      if (token != null && token.isNotEmpty && role != null) {
        if (role == 'manpower' && manpowerData != null) {
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

  // ── Save helpers ──────────────────────────────────────────────────────────

  Future<void> saveUserLogin(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', 'user');
    await prefs.setString('user_data', json.encode(user.toJson()));
    await prefs.remove('manpower_data');
  }

  Future<void> saveLogin(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> saveManpowerLogin(
      String token, ManpowerModel manpower) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_role', 'manpower');
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

  // ── Check login ───────────────────────────────────────────────────────────

  Future<void> checkLogin() async {
    print("🔐 CHECKING LOGIN - Starting auth check");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final role = prefs.getString('auth_role');

      if (token == null || token.isEmpty || role == null) {
        print("🔐 CHECKING LOGIN - No token found");
        state = state.copyWith(
            isLoading: false,
            isLoggedIn: false,
            user: null,
            manpower: null,
            role: null);
        return;
      }

      print("🔐 CHECKING LOGIN - Token found $token, role: $role");

      if (role == 'manpower') {
        try {
          final manpowerData = await AuthAPI.getCurrentManpower();
          final manpower =
          ManpowerModel.fromJson(manpowerData['data'] ?? manpowerData);

          await prefs.setString(
              'manpower_data', json.encode(manpower.toJson()));

          state = state.copyWith(
            isLoading: false,
            isLoggedIn: true,
            role: 'manpower',
            manpower: manpower,
            errorMessage: null,
          );
        } catch (e) {
          final savedData = prefs.getString('manpower_data');
          if (savedData != null) {
            final manpower =
            ManpowerModel.fromJson(json.decode(savedData));
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
      state = state.copyWith(
          isLoading: false,
          isLoggedIn: false,
          user: null,
          manpower: null,
          role: null);
    }
  }

  // ── Manpower login ────────────────────────────────────────────────────────

  Future<void> manpowerLogin(String employeeCode, String otp) async {
    print("🔐 MANPOWER LOGIN - Starting");
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

      final manpower = ManpowerModel.fromJson(manpowerData);
      await saveManpowerLogin(token, manpower);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        role: 'manpower',
        manpower: manpower,
        errorMessage: null,
      );
      ref.read(appAccessProvider.notifier).initialize();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }

  // ── Login with OTP ────────────────────────────────────────────────────────

  Future<void> loginWithOtp(String email, String otp) async {
    print("🔐 USER LOGIN WITH OTP - Starting");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.verifyLoginOtp(email, otp);
      final token = res['token']?['token'] ?? "";

      if (token.isEmpty) throw Exception("No token returned");

      final userData = await AuthAPI.getCurrentUser();
      final user = User.fromJson(userData);

      await saveUserLogin(token, user);

      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        role: 'user',
        user: user,
        errorMessage: null,
      );
      ref.read(appAccessProvider.notifier).initialize();
    } catch (e) {
      print("🔐 USER LOGIN WITH OTP - Error: $e");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      final role = state.role;
      if (role == 'user') {
        await AuthAPI.logout();
      }
    } catch (_) {
      print("Logout API call failed, continuing with local logout");
    }

    await _clearAuthData();
    state = AuthState();
    await ref.read(appAccessProvider.notifier).initialize();
  }

  Future<void> logoutAll() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthAPI.logoutAll();
    } catch (_) {}

    await _clearAuthData();
    state = AuthState();
  }

  // ── Fetch current auth ────────────────────────────────────────────────────

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
        final manpower =
        ManpowerModel.fromJson(res['data'] ?? res);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'manpower_data', json.encode(manpower.toJson()));

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

  // ── Update user ───────────────────────────────────────────────────────────

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

  // ── Fetch current user ────────────────────────────────────────────────────

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

  // ── REGISTRATION ──────────────────────────────────────────────────────────
  //
  // CHANGED: Now saves deviceId from signup response.
  //
  // Signup API response now includes:
  //   { user, token, deviceId, gracePeriodEndsAt, isWithinGracePeriod }
  //
  // deviceId = registrationDeviceId on backend = Device A (permanently trusted).
  // We save it via DevicePrefs so Dio interceptor sends it on every request.
  // Without this, backend can't identify Device A after grace period expires.
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> register(Map<String, dynamic> userData) async {
    print("🔐 REGISTRATION - Starting");
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final res = await AuthAPI.signup(userData);
      print("🔐 REGISTRATION - Successful: $res");

      final token    = res['token']?['token'];
      // ── NEW: Save registration deviceId from signup response ────────────
      // This is the registrationDeviceId stored by backend in user.registrationDeviceId
      // Sending it on every request lets backend identify this as a primary device
      // even after the 24-hour grace period expires.
      final deviceId = res['deviceId']?.toString() ?? '';

      if (token != null && token.isNotEmpty) {
        await saveLogin(token);

        // Save deviceId immediately — before any other API calls
        if (deviceId.isNotEmpty) {
          await DevicePrefs.saveDeviceId(deviceId);
          print("📱 REGISTRATION - Saved registration deviceId: $deviceId");
        }

        final userData    = await AuthAPI.getCurrentUser();
        final user        = User.fromJson(userData);

        await saveUserLogin(token, user);

        print("🔐 REGISTRATION - Auto-login successful");
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          user: user,
          errorMessage: null,
        );
        await ref.read(appAccessProvider.notifier).initialize();
      } else {
        state = state.copyWith(isLoading: false, errorMessage: null);
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

  // ── Email verification ────────────────────────────────────────────────────

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
      final res = await AuthAPI.verifyEmailOtp(email, otp);
      return res['message'] ?? "OTP verified successfully";
    } catch (e) {
      print("🔐 EMAIL VERIFICATION - Error: $e");
      throw e.toString().replaceFirst("Exception: ", "");
    }
  }

  // ── Error helper ──────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>(
        (ref) => AuthNotifier(ref));