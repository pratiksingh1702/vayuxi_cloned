import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/features/modules/screen/device_id_helper.dart';
import '../../profile_page/userModel/userModel.dart';

import '../service/auth_client.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? errorMessage;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: errorMessage,
      user: user ?? this.user,
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

      if (token != null && token.isNotEmpty) {
        // We have a token, consider user logged in initially
        state = state.copyWith(isLoading: false, isLoggedIn: true);
        print("🔐 AUTH INIT - Token found, user considered logged in");
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

  Future<void> checkLogin() async {
    print("🔐 CHECKING LOGIN - Starting auth check");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print("🔐 CHECKING LOGIN - No token found, user not logged in");
        state = state.copyWith(isLoading: false, isLoggedIn: false, user: null);
        return;
      }

      print("🔐 CHECKING LOGIN - Token found, fetching user data");


      print("🔐 CHECKING LOGIN - User data fetched successfully, user is logged in");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,

        errorMessage: null,
      );
    } catch (e) {
      print("🔐 CHECKING LOGIN - Error: $e");
      await _clearAuthData();
      state = state.copyWith(isLoading: false, isLoggedIn: false, user: null);
    }
  }
  // ---------------------------------------------------------
  // SAVE + CLEAR TOKEN
  // ---------------------------------------------------------
  Future<void> saveLogin(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearAuthData() async {
    print("cleared");
    final prefs = await SharedPreferences.getInstance();
    await DevicePrefs.clearDeviceId();
    await prefs.remove('auth_token');
  }

  // ---------------------------------------------------------
  // LOGIN WITH OTP
  // ---------------------------------------------------------
  Future<void> loginWithOtp(String email, String otp) async {
    print("🔐 LOGIN WITH OTP - Starting OTP verification");

    try {
      final res = await AuthAPI.verifyLoginOtp(email, otp);
      final token = res['token']?['token'] ?? "";

      if (token.isEmpty) throw Exception("No token returned");

      await saveLogin(token);


      print("🔐 LOGIN WITH OTP - Login successful, updating state");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,

        errorMessage: null,
      );
    } catch (e) {
      print("🔐 LOGIN WITH OTP - Error: $e");
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: false,
        errorMessage: _getErrorMessage(e),
      );
    }
  }
  // ---------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthAPI.logout();
    } catch (_) {}

    await _clearAuthData();
    state = AuthState();
  }

  Future<void> logoutAll() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthAPI.logoutAll();
    } catch (_) {}

    await _clearAuthData();
    state = AuthState();
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
