// core/router/app_access.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/onboarding/service/onboarding_Service.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/pricing/providers/razorpay_provider.dart';

// ---------------------------------------------------------------------------
// STATE
// ---------------------------------------------------------------------------

class AppAccessState {
  final bool isBooting;
  final bool loggedIn;
  final bool planSelected;
  final bool onboardingCompleted;
  final bool trialActivated;
  final bool hasSubscription;

  AppAccessState({
    required this.isBooting,
    required this.loggedIn,
    required this.planSelected,
    required this.onboardingCompleted,
    required this.trialActivated,
    required this.hasSubscription,
  });

  factory AppAccessState.booting() => AppAccessState(
    isBooting: true,
    loggedIn: false,
    planSelected: false,
    onboardingCompleted: false,
    trialActivated: false,
    hasSubscription: false,
  );

  AppAccessState copyWith({
    bool? isBooting,
    bool? loggedIn,
    bool? planSelected,
    bool? onboardingCompleted,
    bool? trialActivated,
    bool? hasSubscription,
  }) {
    return AppAccessState(
      isBooting:           isBooting           ?? this.isBooting,
      loggedIn:            loggedIn            ?? this.loggedIn,
      planSelected:        planSelected        ?? this.planSelected,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      trialActivated:      trialActivated      ?? this.trialActivated,
      hasSubscription:     hasSubscription     ?? this.hasSubscription,
    );
  }
}

// ---------------------------------------------------------------------------
// NOTIFIER
// ---------------------------------------------------------------------------

class AppAccessNotifier extends StateNotifier<AppAccessState> {
  final Ref ref;

  AppAccessNotifier(this.ref) : super(AppAccessState.booting()) {
    initialize();
  }

  Future<void> initialize() async {
    // ── 1. Wait until auth restores ─────────────────────────────────────────
    AuthState auth = ref.read(authProvider);
    while (auth.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
      auth = ref.read(authProvider);
    }

    // ── 2. Not logged in ─────────────────────────────────────────────────────
    if (!auth.isLoggedIn) {
      state = AppAccessState(
        isBooting:           false,
        loggedIn:            false,
        planSelected:        false,
        onboardingCompleted: false,
        trialActivated:      false,
        hasSubscription:     false,
      );
      return;
    }

    // ── 3. Fetch onboarding status ───────────────────────────────────────────
    bool onboardingCompleted = false;
    bool trialActivated      = false;

    try {
      final status        = await OnboardingService.getStatus();
      onboardingCompleted = status['isCompleted']    == true;
      trialActivated      = status['trialActivated'] == true;
    } catch (e) {
      print('AppAccess: onboarding status fetch failed – $e');
    }

    // ── 4. Check subscription ────────────────────────────────────────────────
    bool hasSubscription = false;
    try {
      final sub    = await ref.read(currentSubscriptionProvider.future);
      hasSubscription = sub.hasSubscription && sub.isActive;
    } catch (e) {
      print('AppAccess: subscription fetch failed – $e');
    }

    // ── 5. planSelected is ONLY true when user has an active subscription ────
    // Without a subscription the router ALWAYS shows plan-select first,
    // regardless of onboarding history. onboardingCompleted is tracked
    // separately so the router can skip that step if already done.
    final planSelected = hasSubscription;

    state = AppAccessState(
      isBooting:           false,
      loggedIn:            true,
      planSelected:        planSelected,
      onboardingCompleted: onboardingCompleted,
      trialActivated:      trialActivated,
      hasSubscription:     hasSubscription,
    );
  }

  void markPlanSelected()        => state = state.copyWith(planSelected: true);
  void markOnboardingCompleted() => state = state.copyWith(onboardingCompleted: true);
  void markTrialActivated()      => state = state.copyWith(trialActivated: true);

  Future<void> refreshSubscription() async {
    state = state.copyWith(isBooting: true);
    await initialize();
  }
}

// ---------------------------------------------------------------------------
// PROVIDER
// ---------------------------------------------------------------------------

final appAccessProvider =
StateNotifierProvider<AppAccessNotifier, AppAccessState>(
      (ref) => AppAccessNotifier(ref),
);