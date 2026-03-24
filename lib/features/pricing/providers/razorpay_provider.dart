// features/pricing/providers/razorpay_provider.dart
//
// FIX SUMMARY:
//  1. razorpayServiceProvider uses keepAlive — singleton stays alive across
//     screen pops, preventing duplicate Razorpay instances + listener leaks
//  2. currentSubscriptionProvider uses ref.read (not ref.watch) for the
//     service — avoids cascading rebuild loops that caused trial screen lag
//  3. PaymentNotifier._handlePaymentSuccess captures isTrialOrder at call-time
//     (not from state) — fixes the race where state.isTrialOrder flips to
//     false between payment complete and verification
//  4. Removed the 100ms delay hack — not needed once the singleton is in place
//  5. successMessage is properly preserved through copyWith (was being cleared)

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_access.dart';
import '../models/payment_model.dart';
import '../service/pricing_service.dart';
import '../service/razor_pay_integeration_service.dart';

// ── Service providers ─────────────────────────────────────────────────────────

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

// keepAlive = true → the singleton RazorpayIntegrationService is NEVER
// garbage-collected by Riverpod, so event listeners stay registered even
// when the pricing screen is popped off the stack.
final razorpayServiceProvider = Provider<RazorpayIntegrationService>((ref) {
  ref.keepAlive();
  return RazorpayIntegrationService();
});

final upgradeCalculationProvider =
FutureProvider.family<UpgradeCalculation, String>((ref, planId) async {
  // ref.read — we don't want this provider to rebuild when paymentService
  // instance changes (it won't, but be explicit)
  return ref.read(paymentServiceProvider).calculateUpgrade(planId);
});

// ── Subscription providers ────────────────────────────────────────────────────

final currentSubscriptionProvider = FutureProvider<Subscription>((ref) async {
  // FIX: use ref.read for service — ref.watch here caused the trial screen to
  // rebuild every time any dependent provider changed, creating visible lag.
  final local   = ref.read(subscriptionLocalProvider);
  final service = ref.read(paymentServiceProvider);

  try {
    final response = await service.getCurrentSubscription();
    if (response['success'] == true) {
      final sub = Subscription.fromJson(response['subscription']);
      await local.save(sub);
      return sub;
    }
    throw Exception('Server returned failure');
  } catch (_) {
    final cached = await local.get();
    if (cached != null) return cached;
    rethrow;
  }
});

final subscriptionLocalProvider = Provider<SubscriptionLocalService>((ref) {
  return SubscriptionLocalService();
});

class SubscriptionLocalService {
  static const _key = 'cached_subscription';

  Future<void> save(Subscription sub) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(sub.toJson()));
  }

  Future<Subscription?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return Subscription.fromJson(jsonDecode(raw));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ── Other providers ───────────────────────────────────────────────────────────

final paymentHistoryProvider =
FutureProvider<List<PaymentHistory>>((ref) async {
  return ref.read(paymentServiceProvider).getPaymentHistory();
});

final coinBalanceProvider = FutureProvider<CoinBalance>((ref) async {
  final res = await ref.read(paymentServiceProvider).getCoinBalance();
  if (res['success'] == true) return CoinBalance.fromJson(res);
  throw Exception('Failed to get coin balance');
});

final referralCodeProvider = FutureProvider<ReferralCode>((ref) async {
  final res = await ref.read(paymentServiceProvider).getReferralCode();
  if (res['success'] == true) return ReferralCode.fromJson(res);
  throw Exception('Failed to get referral code');
});

// ── Payment state ─────────────────────────────────────────────────────────────

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final RazorpayOrder? currentOrder;
  final bool isTrialOrder;

  const PaymentState({
    this.isLoading      = false,
    this.error,
    this.successMessage,
    this.currentOrder,
    this.isTrialOrder   = false,
  });

  // FIX: explicit clearError / clearSuccess flags so callers can null them
  // deliberately, rather than relying on "pass null to clear".
  PaymentState copyWith({
    bool?          isLoading,
    String?        error,
    bool           clearError   = false,
    String?        successMessage,
    bool           clearSuccess = false,
    RazorpayOrder? currentOrder,
    bool?          isTrialOrder,
  }) {
    return PaymentState(
      isLoading:      isLoading      ?? this.isLoading,
      error:          clearError     ? null : (error ?? this.error),
      successMessage: clearSuccess   ? null : (successMessage ?? this.successMessage),
      currentOrder:   currentOrder   ?? this.currentOrder,
      isTrialOrder:   isTrialOrder   ?? this.isTrialOrder,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PaymentNotifier extends StateNotifier<PaymentState> {
  final Ref _ref;
  final RazorpayIntegrationService _razorpayService;
  final PaymentService _paymentService;

  PaymentNotifier(this._ref, this._razorpayService, this._paymentService)
      : super(const PaymentState());

  // ── Init ──────────────────────────────────────────────────────────────────
  //
  // Call once from the screen's initState / ref.listen setup.
  // Safe to call again on screen re-entry — the service guards duplicate init.
  void initializeRazorpay() {
    _razorpayService.initialize(
      onSuccess:        _handlePaymentSuccess,
      onError:          _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  // ── Trial payment ─────────────────────────────────────────────────────────
  Future<void> startTrialPayment({required RazorpayOrder prebuiltOrder}) async {
    if (state.isLoading) return; // guard double-tap

    state = state.copyWith(
      isLoading:    true,
      clearError:   true,
      clearSuccess: true,
      currentOrder: prebuiltOrder,
      isTrialOrder: true,
    );

    // No artificial delay needed — singleton is already initialized
    state = state.copyWith(isLoading: false);

    _razorpayService.openCheckout(
      key:         prebuiltOrder.key,
      orderId:     prebuiltOrder.orderId,
      amount:      prebuiltOrder.amount,
      name:        'Vayuxi ERP',
      description: 'Trial Activation ',
      prefill:     {},
    );
  }

  // ── Paid subscription payment ─────────────────────────────────────────────
  Future<void> startSubscriptionPayment({
    required String plan,
    int coinsToUse       = 0,
    bool gstApplied      = false,
    String? gstNumber,
    String? companyName,
    String? billingAddress,
  }) async {
    if (state.isLoading) return; // guard double-tap

    try {
      state = state.copyWith(
        isLoading:    true,
        clearError:   true,
        clearSuccess: true,
        isTrialOrder: false,
      );

      final order = await _paymentService.createSubscriptionOrder(
        plan:             plan,
        vayuxiCoinsToUse: coinsToUse,
        gstApplied:       gstApplied,
        gstNumber:        gstNumber,
        companyName:      companyName,
        billingAddress:   billingAddress,
      );

      state = state.copyWith(
        currentOrder: order,
        isLoading:    false,
        isTrialOrder: false,
      );

      final planName     = plan[0].toUpperCase() + plan.substring(1);
      final amountRupees = (order.amount / 100).toStringAsFixed(0);

      _razorpayService.openCheckout(
        key:         order.key,
        orderId:     order.orderId,
        amount:      order.amount,
        name:        'Vayuxi ERP',
        description: '$planName Plan — ₹$amountRupees',
        prefill:     {},
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     _clean(e),
      );
    }
  }

  // ── Handle success ────────────────────────────────────────────────────────
  //
  // Called via Future.microtask from the service — already off the SDK thread.
  // Capture isTrialOrder NOW (before any await) to prevent the race condition
  // where state updates between the callback firing and verification finishing.
  Future<void> _handlePaymentSuccess(RazorpaySuccessResponse response) async {
    // Snapshot before any await
    final wasTrial = state.isTrialOrder;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      if (wasTrial) {
        await _paymentService.verifyTrialPayment(
          razorpayOrderId:   response.orderId,
          razorpayPaymentId: response.paymentId,
          razorpaySignature: response.signature,
        );
      } else {
        await _paymentService.verifySubscriptionPayment(
          razorpayOrderId:   response.orderId,
          razorpayPaymentId: response.paymentId,
          razorpaySignature: response.signature,
        );
      }

      // Update local cache (best-effort)
      try {
        final local   = _ref.read(subscriptionLocalProvider);
        final updated = await _ref.read(currentSubscriptionProvider.future);
        await local.save(updated);
      } catch (_) {}

      state = state.copyWith(
        isLoading:      false,
        successMessage: wasTrial
            ? 'Trial activated!.'
            : 'Subscription activated successfully!',
      );

      // Invalidate → UI re-fetches fresh data
      _ref.invalidate(currentSubscriptionProvider);
      _ref.invalidate(paymentHistoryProvider);
      _ref.invalidate(coinBalanceProvider);

      // GoRouter re-evaluates redirect → navigates to correct screen
      await _ref.read(appAccessProvider.notifier).refreshSubscription();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  // ── Handle failure ────────────────────────────────────────────────────────
  void _handlePaymentError(PaymentFailureResponse response) {
    final msg = response.code == 0
        ? 'Payment cancelled'
        : (response.message ?? 'Payment failed. Please try again.');
    state = state.copyWith(isLoading: false, error: msg, clearSuccess: true);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) print('[Razorpay] External wallet: ${response.walletName}');
  }

  // ── Cancel subscription ───────────────────────────────────────────────────
  Future<void> cancelSubscription() async {
    if (state.isLoading) return;
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _paymentService.cancelSubscription();
      state = state.copyWith(
        isLoading:      false,
        successMessage: 'Subscription cancelled.',
      );
      _ref.invalidate(currentSubscriptionProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  void clearState() => state = const PaymentState();

  // ── Helper ────────────────────────────────────────────────────────────────
  String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}

// ── Provider ──────────────────────────────────────────────────────────────────

final paymentNotifierProvider =
StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(
    ref,
    ref.watch(razorpayServiceProvider),
    ref.watch(paymentServiceProvider),
  );
});