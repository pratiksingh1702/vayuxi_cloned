// lib/core/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../profile_page/userModel/userModel.dart';

import '../service/auth_client.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final bool otpVerified;
  final String? errorMessage;
  final User? user;

  AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.otpVerified = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    bool? otpVerified,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      otpVerified: otpVerified ?? this.otpVerified,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    checkLogin();
  }

  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      try {
        final userData = await AuthAPI.getCurrentUser();
        final user = User.fromJson(userData);
        state = state.copyWith(
          isLoggedIn: true,
          otpVerified: true,
          user: user,
        );
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> saveLogin(String token) async {
    print("savvvvvvvvvve");
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  Future<void> loginWithOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await AuthAPI.verifyLoginOtp(email, otp);
      final token = res['token']?['token'];

      if (token != null) {
        await saveLogin(token);
        checkLogin();
      }
    } catch (e) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString()
      );
    }
  }
  Future<void> logout() async {
    try {
      await AuthAPI.logout();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      state = AuthState(isLoggedIn: false);
    }
  }

  Future<void> logoutAll() async {
    try {
      await AuthAPI.logoutAll();
    } catch (e) {
      print('Logout all error: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      state = AuthState(isLoggedIn: false);
    }
  }

  Future<void> updateUser(User user, Map<String, dynamic> updateData) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await AuthAPI.updateUser(user.id, updateData);
      final updatedUser = User.fromJson(res['user'] ?? res);
      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> fetchCurrentUser() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await AuthAPI.getCurrentUser();
      final user = User.fromJson(res);
      state = state.copyWith(
        isLoading: false,
        user: user,
        isLoggedIn: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void setUser(User user) {
    state = state.copyWith(user: user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});