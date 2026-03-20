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
    bool trialPaymentPending = false; // ← NEW: trial order created but not yet verified

    try {
      final status = await OnboardingService.getStatus();
      onboardingCompleted = status['isCompleted']    == true;
      trialActivated      = status['trialActivated'] == true;

      // ── KEY FIX: user has gone through trial flow (payment pending/completed)
      // paymentStatus: 'pending' means the ₹1 order was created and payment
      // was made but backend hasn't marked trialActivated yet, OR the trial
      // was activated but the flag wasn't updated. Either way, treat as paid.
      final paymentStatus = status['paymentStatus'] as String? ?? '';
      trialPaymentPending = paymentStatus == 'pending' || paymentStatus == 'completed';
    } catch (e) {
      print('AppAccess: onboarding status fetch failed – $e');
    }

    // ── 4. Check subscription from payment provider ───────────────────────────
    bool hasSubscription = false;
    try {
      final sub = await ref.read(currentSubscriptionProvider.future);
      hasSubscription = sub.hasSubscription && sub.isActive;
    } catch (e) {
      print('AppAccess: subscription fetch failed – $e');
    }

    // ── 5. If trial payment was made (even if not fully activated yet),
    //       treat as having a subscription so plan overlay is skipped.
    //       The access gate will then only check device verification.
    if (!hasSubscription && trialActivated) {
      hasSubscription = true;
    }

    final planSelected = hasSubscription;

    state = AppAccessState(
      isBooting:           false,
      loggedIn:            true,
      planSelected:        planSelected,
      onboardingCompleted: onboardingCompleted,
      trialActivated:      trialActivated || trialPaymentPending,
      hasSubscription:     hasSubscription,
    );
  }

  void markPlanSelected()        => state = state.copyWith(planSelected: true);
  void markOnboardingCompleted() => state = state.copyWith(onboardingCompleted: true);
  void markTrialActivated()      => state = state.copyWith(trialActivated: true);

  Future<void> refreshSubscription() async {

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