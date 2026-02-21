import '../../features/auth/provider/auth_provider.dart';
import '../../features/pricing/providers/razorpay_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class AppAccessState {
  final bool isBooting;        // still checking storage/API
  final bool loggedIn;
  final bool hasSubscription;

  AppAccessState({
    required this.isBooting,
    required this.loggedIn,
    required this.hasSubscription,
  });
}
final appAccessProvider =
StateNotifierProvider<AppAccessNotifier, AppAccessState>((ref) {
  return AppAccessNotifier(ref);
});

class AppAccessNotifier extends StateNotifier<AppAccessState> {
  final Ref ref;

  AppAccessNotifier(this.ref)
      : super(AppAccessState(
    isBooting: true,
    loggedIn: false,
    hasSubscription: false,
  )) {
    initialize();
  }
  Future<void> initialize() async {
    AuthState auth = ref.read(authProvider);

    // ⭐ WAIT UNTIL AUTH RESTORE FINISHES
    while (auth.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
      auth = ref.read(authProvider);
    }

    if (!auth.isLoggedIn) {
      state = AppAccessState(
        isBooting: false,
        loggedIn: false,
        hasSubscription: false,
      );
      return;
    }

    try {
      final sub = await ref.read(currentSubscriptionProvider.future);

      state = AppAccessState(
        isBooting: false,
        loggedIn: true,
        hasSubscription: sub.hasSubscription,
      );
    } catch (_) {
      state = AppAccessState(
        isBooting: false,
        loggedIn: true,
        hasSubscription: false,
      );
    }
  }


  Future<void> refreshSubscription() async {
    state = AppAccessState(
      isBooting: true,
      loggedIn: true,
      hasSubscription: false,
    );
    await initialize();
  }
}
