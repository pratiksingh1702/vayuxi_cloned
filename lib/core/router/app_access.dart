// core/router/app_access.dart
//
// OFFLINE-FIRST STRATEGY
// ──────────────────────
// Every remote call has a local-cache fallback (SharedPreferences).
// Boot sequence:
//   1. Restore auth from cache (already done in AuthNotifier)
//   2. Emit cached AppAccessState immediately → app is visible, no spinner
//   3. In background (parallel):
//        a. Sync onboarding status  → cache result
//        b. Sync subscription       → cache result
//        c. Pre-warm siteProvider   → loads Hive cache then syncs API
//        d. Pre-warm language home  → loads local storage then syncs API
//   4. Emit final state with fresh values
//   5. Call accessControlProvider.notifier.evaluate() → one clean gate check
//
// ─────────────────────────────────────────────────────────────────────────────
// CHANGES FROM PREVIOUS VERSION
// ─────────────────────────────────────────────────────────────────────────────
//
// accessControlProvider is now a StateNotifier, NOT a FutureProvider.
// This means it does NOT re-run automatically when appAccessProvider changes.
// We must explicitly call evaluate() at the right moments:
//
//   1. After _syncOnboardingAndSubscription completes → fresh data ready
//   2. After refreshSubscription() → post-payment re-boot
//   3. NOT in markPlanSelected/markTrialActivated/markOnboardingCompleted
//      because those are optimistic local updates — evaluate() will be
//      triggered by the next full sync cycle anyway.
//
// graceStatusProvider is still invalidated before evaluate() so the gate
// always reads fresh backend trust data.
//
// ─────────────────────────────────────────────────────────────────────────────
// Cache keys (SharedPreferences):
//   app_access_onboarding_completed  → bool
//   app_access_trial_activated       → bool
//   app_access_has_subscription      → bool

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/onboarding/service/onboarding_Service.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/language/service/lang_providers.dart';
import '../../features/modules/screen/device_id_helper.dart';
import '../../features/pricing/providers/razorpay_provider.dart';
import '../../features/modules/all_Modules/site_Details/providers/siteProvider.dart';
import '../../features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../api/dio.dart';
import 'access_control_provider.dart';

// ---------------------------------------------------------------------------
// CACHE KEYS
// ---------------------------------------------------------------------------

const _kOnboardingCompleted = 'app_access_onboarding_completed';
const _kTrialActivated      = 'app_access_trial_activated';
const _kHasSubscription     = 'app_access_has_subscription';

// ---------------------------------------------------------------------------
// LOCAL CACHE HELPER
// ---------------------------------------------------------------------------

class _AppAccessCache {
  static Future<({bool onboardingCompleted, bool trialActivated, bool hasSubscription})>
  read() async {
    final prefs = await SharedPreferences.getInstance();
    return (
    onboardingCompleted: prefs.getBool(_kOnboardingCompleted) ?? false,
    trialActivated:      prefs.getBool(_kTrialActivated)      ?? false,
    hasSubscription:     prefs.getBool(_kHasSubscription)     ?? false,
    );
  }

  static Future<void> writeOnboarding({
    required bool onboardingCompleted,
    required bool trialActivated,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleted, onboardingCompleted);
    await prefs.setBool(_kTrialActivated,      trialActivated);
  }

  static Future<void> writeSubscription({required bool hasSubscription}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSubscription, hasSubscription);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOnboardingCompleted);
    await prefs.remove(_kTrialActivated);
    await prefs.remove(_kHasSubscription);
  }
}

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

  /// True when the current state was loaded from local cache (i.e. offline).
  final bool isFromCache;

  AppAccessState({
    required this.isBooting,
    required this.loggedIn,
    required this.planSelected,
    required this.onboardingCompleted,
    required this.trialActivated,
    required this.hasSubscription,
    this.isFromCache = false,
  });

  factory AppAccessState.booting() => AppAccessState(
    isBooting:           true,
    loggedIn:            false,
    planSelected:        false,
    onboardingCompleted: false,
    trialActivated:      false,
    hasSubscription:     false,
  );

  AppAccessState copyWith({
    bool? isBooting,
    bool? loggedIn,
    bool? planSelected,
    bool? onboardingCompleted,
    bool? trialActivated,
    bool? hasSubscription,
    bool? isFromCache,
  }) {
    return AppAccessState(
      isBooting:           isBooting           ?? this.isBooting,
      loggedIn:            loggedIn            ?? this.loggedIn,
      planSelected:        planSelected        ?? this.planSelected,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      trialActivated:      trialActivated      ?? this.trialActivated,
      hasSubscription:     hasSubscription     ?? this.hasSubscription,
      isFromCache:         isFromCache         ?? this.isFromCache,
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

  // ── Main boot / refresh ───────────────────────────────────────────────────

  Future<void> initialize() async {
    print('\n🚀 [AppAccess] ══════════ INITIALIZE STARTED ══════════');
    final savedDeviceId = await DevicePrefs.getDeviceId();
    if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
      await DioClient.setDeviceIdCookie(savedDeviceId);
      print('🍪 [AppAccess] DeviceId cookie restored: ${savedDeviceId.substring(0, 8)}...');
    } else {
      print('⚠️  [AppAccess] No saved DeviceId — new device or first install');
    }

    // ── 1. Wait until auth restores from SharedPreferences ──────────────────
    print('⏳ [AppAccess] Waiting for AuthNotifier to restore from cache...');
    AuthState auth = ref.read(authProvider);
    int waitCount = 0;
    while (auth.isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
      auth = ref.read(authProvider);
      waitCount++;
    }
    print('✅ [AppAccess] Auth restored after ${waitCount * 50}ms');
    print('   ├─ isLoggedIn : ${auth.isLoggedIn}');
    print('   └─ role       : ${auth.role}');

    // ── 2. Not logged in → clear cached flags ────────────────────────────────
    if (!auth.isLoggedIn) {
      print('🔴 [AppAccess] Not logged in — clearing cache and grace state');
      await _AppAccessCache.clear();
      print('🔄 [AppAccess] Invalidating trust providers for fresh data...');
      ref.invalidate(graceStatusProvider);
      ref.invalidate(deviceTrustProvider);   // ← ADD
      state = AppAccessState(
        isBooting:           false,
        loggedIn:            false,
        planSelected:        false,
        onboardingCompleted: false,
        trialActivated:      false,
        hasSubscription:     false,
      );
      print('🚀 [AppAccess] ══════════ INITIALIZE COMPLETE (not logged in) ══════════\n');
      return;
    }

    // ── 3. Emit cached state immediately → app opens with no spinner ─────────
    print('📦 [AppAccess] Reading cached access flags...');
    final cached = await _AppAccessCache.read();
    print('   ├─ onboardingCompleted : ${cached.onboardingCompleted}');
    print('   ├─ trialActivated      : ${cached.trialActivated}');
    print('   └─ hasSubscription     : ${cached.hasSubscription}');

    state = AppAccessState(
      isBooting:           false,
      loggedIn:            true,
      planSelected:        cached.hasSubscription,
      onboardingCompleted: cached.onboardingCompleted,
      trialActivated:      cached.trialActivated,
      hasSubscription:     cached.hasSubscription,
      isFromCache:         true,
    );
    print('✅ [AppAccess] Cached state emitted — app is visible immediately');

    // ── 4. Background syncs in parallel ──────────────────────────────────────
    // _syncOnboardingAndSubscription will call evaluate() when done.
    print('🔄 [AppAccess] Starting parallel background syncs...');
    await Future.wait([
      _syncOnboardingAndSubscription(cached),
      // _prewarmSites(auth),
      _prewarmLanguage(auth),
    ]);

    print('🚀 [AppAccess] ══════════ INITIALIZE COMPLETE ══════════\n');
  }

  // ── Sync: onboarding + subscription ──────────────────────────────────────
  //
  // After fresh data is in state, we:
  //   1. Invalidate graceStatusProvider — forces a fresh backend trust check
  //   2. Call evaluate() on accessControlProvider — runs gate logic ONCE
  //      with the fresh data
  //
  // This is the ONLY place evaluate() is called during boot.
  // It replaces the old pattern of watching appAccessProvider inside
  // accessControlProvider (which caused the infinite loop).

  Future<void> _syncOnboardingAndSubscription(
      ({bool onboardingCompleted, bool trialActivated, bool hasSubscription}) cached,
      ) async {
    print('🔄 [AppAccess] _syncOnboardingAndSubscription started');

    bool onboardingCompleted = cached.onboardingCompleted;
    bool trialActivated      = cached.trialActivated;
    bool fetchedOnboarding   = false;

    // 4a. Onboarding status
    print('   ├─ Fetching onboarding status from API...');
    try {
      final status        = await OnboardingService.getStatus();
      onboardingCompleted = status['isCompleted']    == true;
      trialActivated      = status['trialActivated'] == true;
      fetchedOnboarding   = true;
      await _AppAccessCache.writeOnboarding(
        onboardingCompleted: onboardingCompleted,
        trialActivated:      trialActivated,
      );
      print('   ├─ Onboarding sync ✅');
      print('      ├─ isCompleted    : $onboardingCompleted');
      print('      └─ trialActivated : $trialActivated');
    } catch (e) {
      print('   ├─ Onboarding sync ❌ (using cache) — $e');
    }

    // 4b. Subscription
    bool hasSubscription     = cached.hasSubscription;
    bool fetchedSubscription = false;
    print('   └─ Fetching subscription status from API...');
    try {
      final sub       = await ref.read(currentSubscriptionProvider.future);
      hasSubscription = sub.hasSubscription && sub.isActive;
      fetchedSubscription = true;
      await _AppAccessCache.writeSubscription(hasSubscription: hasSubscription);
      print('      Subscription sync ✅');
      print('      ├─ hasSubscription : ${sub.hasSubscription}');
      print('      ├─ isActive        : ${sub.isActive}');
      print('      └─ final value     : $hasSubscription');
    } catch (e) {
      print('      Subscription sync ❌ (using cache) — $e');
    }

    // Emit final authoritative AppAccessState
    state = AppAccessState(
      isBooting:           false,
      loggedIn:            true,
      planSelected:        hasSubscription,
      onboardingCompleted: onboardingCompleted,
      trialActivated:      trialActivated,
      hasSubscription:     hasSubscription,
      isFromCache:         !fetchedOnboarding && !fetchedSubscription,
    );

    print('📊 [AppAccess] Final authoritative state emitted:');
    print('   ├─ hasSubscription    : $hasSubscription');
    print('   ├─ onboardingCompleted: $onboardingCompleted');
    print('   ├─ trialActivated     : $trialActivated');
    print('   └─ isFromCache        : ${state.isFromCache}');

    // ── Trigger ONE clean access evaluation ──────────────────────────────────
    // Invalidate grace status first so evaluate() reads fresh backend trust.
    // Then call evaluate() exactly once — no loops, no watchers.
    print('🔄 [AppAccess] Invalidating graceStatusProvider for fresh trust data...');
    ref.invalidate(graceStatusProvider);
    ref.invalidate(deviceTrustProvider);

    print('🔄 [AppAccess] Calling accessControlProvider.evaluate()...');
    await ref.read(accessControlProvider.notifier).evaluate();
  }

  // ── Pre-warm: sites ───────────────────────────────────────────────────────

  Future<void> _prewarmSites(AuthState auth) async {
    print(' [AppAccess] Pre-warming siteProvider...');
    try {
      await ref.read(siteProvider.notifier).fetchSites();
      print(' [AppAccess] siteProvider pre-warmed ✅');
    } catch (e) {
      print(' [AppAccess] siteProvider pre-warm failed (Hive fallback active) ❌ — $e');
    }
  }

  // ── Pre-warm: language module 'home' ─────────────────────────────────────

  Future<void> _prewarmLanguage(AuthState auth) async {
    print(' [AppAccess] Pre-warming languageModuleProvider[home]...');
    try {
      await ref.read(languageModuleProvider('home').future);
      print(' [AppAccess] languageModuleProvider[home] pre-warmed ✅');
    } catch (e) {
      print(' [AppAccess] languageModuleProvider[home] pre-warm failed ❌ — $e');
    }
  }

  // ── Convenience mutators ──────────────────────────────────────────────────
  // These are optimistic local updates only.
  // They do NOT call evaluate() — the next sync cycle will do that.
  // If you need immediate re-evaluation after one of these (e.g. after
  // marking onboarding complete), call evaluate() at the call site:
  //   ref.read(accessControlProvider.notifier).evaluate()

  void markPlanSelected() {
    print('📝 [AppAccess] markPlanSelected()');
    state = state.copyWith(planSelected: true);
  }

  void markOnboardingCompleted() {
    print('📝 [AppAccess] markOnboardingCompleted()');
    state = state.copyWith(onboardingCompleted: true);
    _AppAccessCache.writeOnboarding(
      onboardingCompleted: true,
      trialActivated:      state.trialActivated,
    );
    // Re-evaluate gates immediately — onboarding completion may unblock access
    ref.read(accessControlProvider.notifier).evaluate();
  }

  void markTrialActivated() {
    print('📝 [AppAccess] markTrialActivated()');
    state = state.copyWith(trialActivated: true, hasSubscription: true, planSelected: true);
    _AppAccessCache.writeOnboarding(
      onboardingCompleted: state.onboardingCompleted,
      trialActivated:      true,
    );
    // Re-evaluate — trial activation means subscription gate may now pass
    ref.read(accessControlProvider.notifier).evaluate();
  }

  // ── refreshSubscription ───────────────────────────────────────────────────
  //
  // Called after a successful payment. Re-runs the full boot sequence.
  // The purchase device becomes purchaseDeviceId on backend (Device B trust).
  // graceStatusProvider is invalidated before re-boot so the next evaluate()
  // reads the updated isPrimaryDevice flag for this device.

  Future<void> refreshSubscription() async {
    print('\n🔄 [AppAccess] refreshSubscription() — post-payment re-boot');
    print('   └─ Invalidating graceStatusProvider (device may now be purchaseDevice)');
    ref.invalidate(graceStatusProvider);
    ref.invalidate(deviceTrustProvider);

    state = state.copyWith(isBooting: true);
    await initialize();
    print('🔄 [AppAccess] refreshSubscription() complete\n');
  }
}

// ---------------------------------------------------------------------------
// PROVIDER
// ---------------------------------------------------------------------------

final appAccessProvider =
StateNotifierProvider<AppAccessNotifier, AppAccessState>(
      (ref) => AppAccessNotifier(ref),
);