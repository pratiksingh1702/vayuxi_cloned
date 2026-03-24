// core/router/access_control_provider.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// PROGRESSIVE TRUST SYSTEM — FRONTEND IS A STATE RENDERER, NOT A DECISION MAKER
// ═══════════════════════════════════════════════════════════════════════════
//
// ─────────────────────────────────────────────────────────────────────────────
// CRITICAL DESIGN DECISION — GRACE PERIOD = FULL ACCESS MODE
// ─────────────────────────────────────────────────────────────────────────────
//
// PREVIOUS (WRONG) MENTAL MODEL:
//   Grace period = skip device OTP only
//   Subscription gate still enforced during grace
//
// CORRECT MENTAL MODEL:
//   Grace period = TRUST EVERYONE, ZERO FRICTION, FULL ACCESS
//   Backend is intentionally "blind" during grace — device identity,
//   subscription status, onboarding state — NONE of it matters.
//   The user can explore everything freely.
//
// WHY THIS IS THE RIGHT PRODUCT DECISION:
//   The entire point of a 24-hour grace period is to maximize onboarding
//   and reduce drop-off. If you show a plan screen the moment someone
//   taps Setup or Reports, you've killed the exploration phase.
//   Grace = "we trust you, go explore" — not "we trust your device but
//   you still need to pay before you can see anything".
//
// ─────────────────────────────────────────────────────────────────────────────
// GATE ORDER (evaluated top to bottom)
// ─────────────────────────────────────────────────────────────────────────────
//
//   Gate 0 — GRACE PERIOD (HIGHEST PRIORITY — bypasses ALL gates below)
//     isWithinGracePeriod = true → AccessResult.allowed() immediately
//     No subscription check. No OTP. No onboarding. Full access.
//
//   Gate 1 — SUBSCRIPTION (only enforced after grace expires)
//     !hasSubscription → noSubscription
//
//   Gate 2 — DEVICE AUTH (only enforced after grace expires)
//     requiresDeviceAuth = true from backend → continue to gate 3
//     requiresDeviceAuth = false (primary device) → skip to allowed
//
//   Gate 3 — ONBOARDING (trial plan only)
//     trialActivated && !onboardingCompleted → needsOnboarding
//
//   Gate 4 — DEVICE OTP
//     requiresDeviceAuth = true → deviceNotVerified
//
// ─────────────────────────────────────────────────────────────────────────────
// TRUST MODEL (backend-defined, frontend obeys)
// ─────────────────────────────────────────────────────────────────────────────
//
//   First 24 hours (GRACE PERIOD)
//     → TRUST EVERYONE. FULL ACCESS. Zero friction.
//     → isWithinGracePeriod = true → allowed immediately
//
//   After 24 hours (SUBSCRIPTION REQUIRED)
//     → Must have a plan to access Setup/Reports
//
//   After 24 hours — Primary Device (Device A or B)
//     → requiresDeviceAuth = false → no OTP, full access
//
//   After 24 hours — Unknown Device (Device C+)
//     → requiresDeviceAuth = true → OTP required
//
// ─────────────────────────────────────────────────────────────────────────────
// SCENARIO MATRIX
// ─────────────────────────────────────────────────────────────────────────────
//
//   New user, <24h,  any plan status → ALLOWED  ← grace = full bypass
//   New user, <24h,  any device      → ALLOWED  ← grace = full bypass
//   User,     >24h,  no plan         → noSubscription
//   User,     >24h,  has plan, Device A → ALLOWED  ← primary device
//   User,     >24h,  has plan, Device B → ALLOWED  ← purchase device
//   User,     >24h,  has plan, Device C → deviceNotVerified (OTP)
//   Trial,    >24h,  Device A, no onboarding → needsOnboarding
//   Trial,    >24h,  Device C, no onboarding → needsOnboarding (before OTP)
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/app_access.dart';
import '../../features/auth/service/auth_client.dart';

// ─── ENUMS ──────────────────────────────────────────────────────────────────

enum AccessState {
  loading,           // Evaluation in progress
  noSubscription,    // Gate 1 failed — must pick a plan (only after grace)
  needsOnboarding,   // Gate 3 failed — trial user, onboarding incomplete
  deviceNotVerified, // Gate 4 failed — OTP required (backend confirmed)
  allowed,           // All gates clear
}

// ─── ACCESS RESULT ───────────────────────────────────────────────────────────

class AccessResult {
  final AccessState state;
  final bool onboardingCompleted;
  final bool deviceVerified;

  // Grace/primary device context — for UI banners only, not for gating
  final bool isWithinGracePeriod;
  final bool isPrimaryDevice;
  final double? hoursRemaining;

  const AccessResult({
    required this.state,
    required this.onboardingCompleted,
    required this.deviceVerified,
    this.isWithinGracePeriod = false,
    this.isPrimaryDevice = false,
    this.hoursRemaining,
  });

  const AccessResult.allowed({
    this.isWithinGracePeriod = false,
    this.isPrimaryDevice = false,
    this.hoursRemaining,
  })  : state = AccessState.allowed,
        onboardingCompleted = true,
        deviceVerified = true;
}

// ─── GRACE STATUS PROVIDER ───────────────────────────────────────────────────
//
// Fetches GET /auth/grace-period-status once. Cached by Riverpod.
// Invalidated explicitly after OTP verification or subscription change.
//
// On failure → returns {} → grace defaults to false → safe (gates still work,
// just no free pass. Better to show plan screen than to crash).
// ─────────────────────────────────────────────────────────────────────────────

final graceStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  print('🔍 [graceStatusProvider] Fetching grace period status from backend...');
  try {
    final res = await AuthAPI.getGracePeriodStatus();
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      print('✅ [graceStatusProvider] Response received:');
      print('   ├─ isWithinGracePeriod : ${data['isWithinGracePeriod']}');
      print('   ├─ isPrimaryDevice     : ${data['isPrimaryDevice']}');
      print('   ├─ requiresDeviceAuth  : ${data['requiresDeviceAuth']}');
      print('   ├─ hoursRemaining      : ${data['hoursRemaining']}');
      print('   ├─ hasRegistrationDevice: ${data['hasRegistrationDevice']}');
      print('   └─ hasPurchaseDevice   : ${data['hasPurchaseDevice']}');
      return data;
    }
    print('⚠️  [graceStatusProvider] No "data" field — returning {}');
    return {};
  } catch (e) {
    print('❌ [graceStatusProvider] Fetch FAILED: $e');
    print('   └─ Returning {} (grace defaults to false — gates still enforced)');
    return {};
  }
});


// Add this NEW provider — do NOT touch graceStatusProvider

final deviceTrustProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  print('🔍 [deviceTrustProvider] Checking device trust...');
  try {
    final res = await AuthAPI.checkDeviceTrust();
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      print('✅ [deviceTrustProvider] Response received:');
      print('   ├─ isTrustedDevice      : ${data['isTrustedDevice']}');
      print('   ├─ isWithinGracePeriod  : ${data['isWithinGracePeriod']}');
      print('   ├─ requiresDeviceAuth   : ${data['requiresDeviceAuth']}');
      print('   └─ hoursRemaining       : ${data['hoursRemaining']}');
      return data;
    }
    print('⚠️  [deviceTrustProvider] No "data" field — failing closed');
    // Fail CLOSED: unknown state = require auth
    return {'requiresDeviceAuth': true, 'isTrustedDevice': false};
  } catch (e) {
    print('❌ [deviceTrustProvider] Fetch FAILED: $e');
    // Fail CLOSED: on any error, require device auth
    // This prevents a network failure from granting access
    return {'requiresDeviceAuth': true, 'isTrustedDevice': false};
  }
});

// ─── ACCESS CONTROL NOTIFIER ─────────────────────────────────────────────────
//
// StateNotifier — runs ONLY when evaluate() is explicitly called.
// Never re-runs due to widget rebuilds or watched provider changes.
//
// Call evaluate() after:
//   - App boot sync completes (AppAccessNotifier._syncOnboardingAndSubscription)
//   - OTP verification succeeds (_InlineDeviceCard._verifyOtp)
//   - Plan purchased (AppAccessNotifier.refreshSubscription)
//   - Onboarding completed (AppAccessNotifier.markOnboardingCompleted)
//   - Trial activated (AppAccessNotifier.markTrialActivated)
// ─────────────────────────────────────────────────────────────────────────────

class AccessControlNotifier extends StateNotifier<AsyncValue<AccessResult>> {
  final Ref ref;

  AccessControlNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> evaluate() async {
    print('\n🚦 [accessControlProvider] ══════════ ACCESS CHECK STARTED ══════════');
    state = const AsyncValue.loading();

    try {
      final appAccess = ref.read(appAccessProvider);

      print('📊 [accessControlProvider] AppAccessState:');
      print('   ├─ isBooting          : ${appAccess.isBooting}');
      print('   ├─ loggedIn           : ${appAccess.loggedIn}');
      print('   ├─ hasSubscription    : ${appAccess.hasSubscription}');
      print('   ├─ trialActivated     : ${appAccess.trialActivated}');
      print('   ├─ onboardingCompleted: ${appAccess.onboardingCompleted}');
      print('   └─ isFromCache        : ${appAccess.isFromCache}');

      if (appAccess.isBooting) {
        print('⏳ [accessControlProvider] → Still booting');
        state = const AsyncValue.data(AccessResult(
          state: AccessState.loading,
          onboardingCompleted: false,
          deviceVerified: false,
        ));
        return;
      }

      // ════════════════════════════════════════════════════════════════════
      // GATE 0 — FETCH BOTH TRUST + GRACE DATA IN PARALLEL
      // deviceTrustProvider  → requiresDeviceAuth, isTrustedDevice
      // graceStatusProvider  → isWithinGracePeriod, hoursRemaining
      // ════════════════════════════════════════════════════════════════════
      print('🔐 [accessControlProvider] Gate 0 — Fetching trust + grace data...');

      Map<String, dynamic> trustData = {};
      Map<String, dynamic> graceData = {};

      try {
        final results = await Future.wait([
          ref.read(deviceTrustProvider.future),
          ref.read(graceStatusProvider.future),
        ]);
        trustData = results[0];
        graceData = results[1];
      } catch (e) {
        print('⚠️  [accessControlProvider] Trust/grace fetch failed: $e');
      }

      // requiresDeviceAuth and isTrustedDevice come from deviceTrustProvider
      final bool requiresDeviceAuth  = trustData['requiresDeviceAuth'] == true;
      final bool isTrustedDevice     = trustData['isTrustedDevice']    == true;

      // isWithinGracePeriod and hoursRemaining come from graceStatusProvider
      final bool isWithinGracePeriod = graceData['isWithinGracePeriod'] == true
          || trustData['isWithinGracePeriod'] == true; // fallback: check both
      final bool isPrimaryDevice     = isTrustedDevice;
      final double? hoursRemaining   = (trustData['hoursRemaining'] as num?)?.toDouble()
          ?? (graceData['hoursRemaining'] as num?)?.toDouble();

      print('📡 [accessControlProvider] Trust result:');
      print('   ├─ isTrustedDevice     : $isTrustedDevice');
      print('   ├─ requiresDeviceAuth  : $requiresDeviceAuth');
      print('   ├─ isWithinGracePeriod : $isWithinGracePeriod');
      print('   └─ hoursRemaining      : $hoursRemaining');

      // ── GRACE PERIOD → FULL ACCESS ──────────────────────────────────────
      if (isWithinGracePeriod) {
        print('🟢 [accessControlProvider] Gate 0 PASSED — grace period active');
        print('✅ [accessControlProvider] → RESULT: allowed (grace period full access)');
        print('🚦 [accessControlProvider] ══════════ ACCESS CHECK COMPLETE ══════════\n');
        state = AsyncValue.data(AccessResult.allowed(
          isWithinGracePeriod: true,
          isPrimaryDevice: isPrimaryDevice,
          hoursRemaining: hoursRemaining,
        ));
        return;
      }

      print('🔴 [accessControlProvider] Gate 0 — Grace period NOT active');
      print('   └─ Proceeding to enforce subscription and device gates...');

      // ════════════════════════════════════════════════════════════════════
      // GATE 1 — SUBSCRIPTION
      // ════════════════════════════════════════════════════════════════════
      print('🔐 [accessControlProvider] Gate 1 — Subscription check...');

      if (!appAccess.hasSubscription) {
        print('🔴 [accessControlProvider] Gate 1 FAILED — no active subscription');
        state = AsyncValue.data(AccessResult(
          state: AccessState.noSubscription,
          onboardingCompleted: appAccess.onboardingCompleted,
          deviceVerified: false,
        ));
        return;
      }

      print('🟢 [accessControlProvider] Gate 1 PASSED — subscription active');

      // ════════════════════════════════════════════════════════════════════
      // GATE 2 — DEVICE TRUST
      // requiresDeviceAuth=false means trusted device → bypass OTP
      // ════════════════════════════════════════════════════════════════════
      print('🔐 [accessControlProvider] Gate 2 — Device trust check...');

      if (!requiresDeviceAuth) {
        print('🟢 [accessControlProvider] Gate 2 PASSED — device trusted');
        print('   └─ isTrustedDevice: $isTrustedDevice');

        if (appAccess.trialActivated && !appAccess.onboardingCompleted) {
          print('🔴 [accessControlProvider] Gate 3 FAILED — trial, onboarding incomplete');
          state = AsyncValue.data(AccessResult(
            state: AccessState.needsOnboarding,
            onboardingCompleted: false,
            deviceVerified: true,
            isPrimaryDevice: isPrimaryDevice,
          ));
          return;
        }

        print('✅ [accessControlProvider] ALL GATES PASSED → RESULT: allowed');
        print('🚦 [accessControlProvider] ══════════ ACCESS CHECK COMPLETE ══════════\n');
        state = AsyncValue.data(AccessResult.allowed(
          isWithinGracePeriod: false,
          isPrimaryDevice: isPrimaryDevice,
        ));
        return;
      }

      print('🔴 [accessControlProvider] Gate 2 FAILED — device auth required');

      // ════════════════════════════════════════════════════════════════════
      // GATE 3 — ONBOARDING
      // ════════════════════════════════════════════════════════════════════
      print('🔐 [accessControlProvider] Gate 3 — Onboarding check (trial only)...');

      if (appAccess.trialActivated && !appAccess.onboardingCompleted) {
        print('🔴 [accessControlProvider] Gate 3 FAILED — trial, onboarding incomplete');
        state = AsyncValue.data(AccessResult(
          state: AccessState.needsOnboarding,
          onboardingCompleted: false,
          deviceVerified: false,
        ));
        return;
      }

      // ════════════════════════════════════════════════════════════════════
      // GATE 4 — DEVICE OTP REQUIRED
      // ════════════════════════════════════════════════════════════════════
      print('🔴 [accessControlProvider] Gate 4 FAILED — OTP required for this device');
      print('🚦 [accessControlProvider] ══════════ ACCESS CHECK COMPLETE ══════════\n');

      state = AsyncValue.data(AccessResult(
        state: AccessState.deviceNotVerified,
        onboardingCompleted: appAccess.onboardingCompleted,
        deviceVerified: false,
      ));
    } catch (e, st) {
      print('❌ [accessControlProvider] Evaluation threw: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

// ─── PROVIDER ────────────────────────────────────────────────────────────────

final accessControlProvider = StateNotifierProvider<
    AccessControlNotifier, AsyncValue<AccessResult>>(
      (ref) => AccessControlNotifier(ref),
);

// ─── OVERLAY CONTROLLER ──────────────────────────────────────────────────────

class OverlayController extends StateNotifier<AccessState?> {
  OverlayController() : super(null);

  void show(AccessState type) {
    print('🎭 [OverlayController] Showing overlay: $type');
    state = type;
  }

  void hide() {
    print('🎭 [OverlayController] Hiding overlay');
    state = null;
  }

  bool get isVisible => state != null;
}

final overlayControllerProvider =
StateNotifierProvider<OverlayController, AccessState?>(
      (ref) => OverlayController(),
);