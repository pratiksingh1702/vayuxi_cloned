import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/service/auth_client.dart';
import '../offline/repository/user_local_repository.dart';
import '../userModel/userModel.dart';

// -----------------------------------------------------
// 🚀 USER STATE NOTIFIER
// -----------------------------------------------------

class UserState {
  final User? user;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final Ref ref;
  final UserLocalRepository _localRepo = const UserLocalRepository();
  StreamSubscription<User?>? _userWatchSub;

  UserNotifier(this.ref) : super(const UserState()) {
    _startReactiveCacheWatcher();
  }

  Future<void> _startReactiveCacheWatcher() async {
    await _migrateLegacyPrefsCacheToIsar();
    _userWatchSub?.cancel();
    _userWatchSub = _localRepo.watchCurrentUser().listen((cachedUser) {
      if (!mounted) return;
      state = state.copyWith(
        user: cachedUser,
        isLoading: false,
      );
    });
  }

  Future<void> _migrateLegacyPrefsCacheToIsar() async {
    final existing = await _localRepo.getCurrentUser();
    if (existing != null) return;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_data');
    if (cached == null || cached.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        await _localRepo.saveUser(User.fromJson(decoded));
      }
    } catch (_) {
      // Ignore corrupt legacy cache and continue with API fallback.
    }
  }

  // -----------------------------------------------------
  // 🚀 USER METHODS
  // -----------------------------------------------------

  /// Get current user
  Future<void> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final localUser = await _localRepo.getCurrentUser();

    if (localUser == null) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(user: localUser, isLoading: false, error: null);
    }

    try {
      // Fetch latest user from API and push to Isar + legacy mirror cache.
      final userData = await AuthAPI.getCurrentUser();
      final freshUser = User.fromJson(userData['data'] ?? userData);

      await _localRepo.saveUser(freshUser);
      await prefs.setString('user_data', json.encode(freshUser.toJson()));

      state = state.copyWith(user: freshUser, isLoading: false, error: null);
    } on DioException catch (e) {
      if (localUser != null) {
        // API failed but local Isar cache is already showing user.
        state = state.copyWith(isLoading: false);
        return;
      }

      final cached = prefs.getString('user_data');
      if (cached != null && cached.trim().isNotEmpty) {
        try {
          final user = User.fromJson(jsonDecode(cached));
          await _localRepo.saveUser(user);
          state = state.copyWith(user: user, isLoading: false);
          return;
        } catch (_) {}
      }

      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Failed to fetch user';

      state = state.copyWith(error: errorMessage, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String id) async {
    try {
      final userData = await AuthAPI.getUserById(id);
      return User.fromJson(userData['data'] ?? userData);
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUser(FormData updateData) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      state = state.copyWith(isLoading: true, error: null);

      final currentUser = state.user;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final response = await AuthAPI.updateUser(
        currentUser.id,
        updateData,
      );

      final rawUser = response['user'] ?? response['data'] ?? response;

      if (rawUser is! Map<String, dynamic>) {
        throw Exception(
          response['message'] ?? 'Invalid server response',
        );
      }

      final updatedUser = User.fromJson(rawUser);

      // Persist immediately to Isar so listeners across app rebuild in sync.
      await _localRepo.saveUser(updatedUser);

      // Keep existing SharedPreferences cache for backward compatibility.
      await prefs.setString(
        'user_data',
        jsonEncode(updatedUser.toJson()),
      );

      // Explicitly update state and ensure watcher is triggered
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );

      // Refresh from cache to ensure watcher stream is properly synchronized
      await Future.delayed(const Duration(milliseconds: 100));
      await refreshUserFromCache();
    } on DioException catch (e) {
      final data = e.response?.data;

      String errorMessage = 'Failed to update user';

      if (data is Map<String, dynamic>) {
        errorMessage = data['message'] ?? data['error'] ?? errorMessage;
      } else if (data is String) {
        errorMessage = data;
      } else {
        errorMessage = e.message ?? errorMessage;
      }

      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Update specific user fields
  // Future<void> updateUserPartial({
  //   String? fullName,
  //   String? phoneNumber,
  //   String? profilePhoto,
  //   String? aadhaarCard,
  //   String? gstNumber,
  //   Company? company,
  //   String? address,
  //   String? other,
  //   List<String>? selectedServices,
  //   String? firstName,
  //   String? lastName,
  // }) async {
  //   final updateData = <String, dynamic>{};
  //
  //   if (fullName != null) updateData['fullName'] = fullName;
  //   if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
  //   if (profilePhoto != null) updateData['profilePhoto'] = profilePhoto;
  //   if (aadhaarCard != null) updateData['aadhaarCard'] = aadhaarCard;
  //   if (gstNumber != null) updateData['gstNumber'] = gstNumber;
  //   if (company != null) updateData['company'] = company.toJson();
  //   if (address != null) updateData['address'] = address;
  //   if (other != null) updateData['other'] = other;
  //   if (selectedServices != null) updateData['selectedServices'] = selectedServices;
  //   if (firstName != null) updateData['firstName'] = firstName;
  //   if (lastName != null) updateData['lastName'] = lastName;
  //
  //   await updateUser(updateData);
  // }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set user directly (useful after login/signup)
  void setUser(User user) {
    unawaited(_localRepo.saveUser(user));
    state = state.copyWith(user: user, error: null);
  }

  /// Clear user data (useful for logout)
  void clearUser() {
    unawaited(_localRepo.clearUsers());
    state = const UserState();
  }

  /// Refresh user data from Isar cache
  Future<void> refreshUserFromCache() async {
    final cachedUser = await _localRepo.getCurrentUser();
    if (cachedUser != null && mounted) {
      state = state.copyWith(user: cachedUser, isLoading: false);
    }
  }

  @override
  void dispose() {
    _userWatchSub?.cancel();
    super.dispose();
  }
}

// -----------------------------------------------------
// 🚀 PROVIDER DEFINITIONS
// -----------------------------------------------------

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});

// Convenience providers for specific state parts
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(userNotifierProvider).user;
});

final userLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userNotifierProvider).isLoading;
});

final userErrorProvider = Provider<String?>((ref) {
  return ref.watch(userNotifierProvider).error;
});

// Provider for user by ID (auto-fetches when ID changes)
final userByIdProvider =
    FutureProvider.family<User?, String>((ref, userId) async {
  try {
    final userNotifier = ref.read(userNotifierProvider.notifier);
    return await userNotifier.getUserById(userId);
  } catch (e) {
    throw Exception('Failed to load user: $e');
  }
});

  // -----------------------------------------------------
  // 🚀 USAGE EXAMPLES
  // -----------------------------------------------------

  /*
  // 1. Get current user in widget
  class UserProfile extends ConsumerWidget {
    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final user = ref.watch(currentUserProvider);
      final isLoading = ref.watch(userLoadingProvider);
      final error = ref.watch(userErrorProvider);

      if (isLoading) return CircularProgressIndicator();
      if (error != null) return Text('Error: $error');
      if (user == null) return Text('No user data');

      return Text('Welcome, ${user.fullName}');
    }
  }

  // 2. Update user profile
  ref.read(userNotifierProvider.notifier).updateUserPartial(
    fullName: 'New Name',
    phoneNumber: '1234567890',
  );

  // 3. Get user by ID
  final userAsync = ref.watch(userByIdProvider('user123'));
  return userAsync.when(
    loading: () => CircularProgressIndicator(),
    error: (error, stack) => Text('Error: $error'),
    data: (user) => Text(user?.fullName ?? 'Unknown'),
  );

  // 4. Initialize user on app start
  ref.read(userNotifierProvider.notifier).getCurrentUser();
  */