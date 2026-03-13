// features/pricing/providers/razorpay_provider.dart
//
// Aligned with v2.0 API docs:
//   Trial flow   → /trial-onboarding/create-order  + /trial-onboarding/activate
//   Paid flow    → /payment/create-subscription-order + /payment/verify-subscription-payment
//
// Key body-field differences (see API docs):
//   Trial activate  → snake_case  { razorpay_order_id, razorpay_payment_id, razorpay_signature }
//   Paid verify     → camelCase   { razorpayOrderId, razorpayPaymentId, razorpaySignature }

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

final razorpayServiceProvider = Provider<RazorpayIntegrationService>((ref) {
  return RazorpayIntegrationService();
});

// ── Subscription providers ────────────────────────────────────────────────────

final currentSubscriptionProvider = FutureProvider<Subscription>((ref) async {
  final local   = ref.watch(subscriptionLocalProvider);
  final service = ref.watch(paymentServiceProvider);

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
    throw Exception('No subscription available');
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
  return ref.watch(paymentServiceProvider).getPaymentHistory();
});

final coinBalanceProvider = FutureProvider<CoinBalance>((ref) async {
  final res = await ref.watch(paymentServiceProvider).getCoinBalance();
  if (res['success'] == true) return CoinBalance.fromJson(res);
  throw Exception('Failed to get coin balance');
});

final referralCodeProvider = FutureProvider<ReferralCode>((ref) async {
  final res = await ref.watch(paymentServiceProvider).getReferralCode();
  if (res['success'] == true) return ReferralCode.fromJson(res);
  throw Exception('Failed to get referral code');
});

// ── Payment state ─────────────────────────────────────────────────────────────

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final RazorpayOrder? currentOrder;

  /// True when the current order is for the trial (amount == 100 paise / ₹1).
  final bool isTrialOrder;

  PaymentState({
    this.isLoading    = false,
    this.error,
    this.successMessage,
    this.currentOrder,
    this.isTrialOrder = false,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    RazorpayOrder? currentOrder,
    bool? isTrialOrder,
  }) {
    return PaymentState(
      isLoading:      isLoading      ?? this.isLoading,
      error:          error,
      successMessage: successMessage,
      currentOrder:   currentOrder   ?? this.currentOrder,
      isTrialOrder:   isTrialOrder   ?? this.isTrialOrder,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PaymentNotifier extends StateNotifier<PaymentState> {
  final Ref ref;
  final RazorpayIntegrationService razorpayService;
  final PaymentService paymentService;

  PaymentNotifier(this.ref, this.razorpayService, this.paymentService)
      : super(PaymentState());

  // ── Init ──────────────────────────────────────────────────────────────────
  void initializeRazorpay() {
    razorpayService.initialize(
      onSuccess:        _handlePaymentSuccess,
      onError:          _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  // ── Trial payment ─────────────────────────────────────────────────────────
  //
  // Called by TrialScreen after it has already created the order via
  // /trial-onboarding/create-order (with the user's referral code).
  // The pre-built RazorpayOrder is passed in directly.
  //
  // If prebuiltOrder is null (legacy / fallback), we throw — the referral
  // code flow is required in v2.0.
  Future<void> startTrialPayment({required RazorpayOrder prebuiltOrder}) async {
    state = state.copyWith(
      isLoading:    true,
      error:        null,
      currentOrder: prebuiltOrder,
      isTrialOrder: true,
    );

    // Small delay so state update propagates before Razorpay opens
    await Future.delayed(const Duration(milliseconds: 100));

    state = state.copyWith(isLoading: false);

    razorpayService.openCheckout(
      key:         prebuiltOrder.key,
      orderId:     prebuiltOrder.orderId,
      amount:      prebuiltOrder.amount,
      name:        'Vayuxi ERP',
      description: 'Trial Activation — ₹1 (Refundable)',
      prefill:     {},
    );
  }

  // ── Paid subscription payment ─────────────────────────────────────────────
  //
  // Calls POST /payment/create-subscription-order then opens Razorpay.
  Future<void> startSubscriptionPayment({
    required String plan,
    int coinsToUse = 0,
    bool gstApplied = false,
    String? gstNumber,
    String? companyName,
    String? billingAddress,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, isTrialOrder: false);

      final order = await paymentService.createSubscriptionOrder(
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

      razorpayService.openCheckout(
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
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── Handle success ────────────────────────────────────────────────────────
  //
  // Razorpay SDK calls this on successful payment.
  // Routes to the correct verify endpoint based on isTrialOrder.
  Future<void> _handlePaymentSuccess(
      RazorpaySuccessResponse response) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (state.isTrialOrder) {
        // ── TRIAL: POST /trial-onboarding/activate
        // Body must use snake_case keys (per API docs)
        await paymentService.verifyTrialPayment(
          razorpayOrderId:   response.orderId   ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
      } else {
        // ── PAID: POST /payment/verify-subscription-payment
        // Body uses camelCase keys (per API docs)
        await paymentService.verifySubscriptionPayment(
          razorpayOrderId:   response.orderId   ?? '',
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        );
      }

      // Refresh local cache
      try {
        final local   = ref.read(subscriptionLocalProvider);
        final updated = await ref.read(currentSubscriptionProvider.future);
        await local.save(updated);
      } catch (_) {}

      state = state.copyWith(
        isLoading:      false,
        successMessage: state.isTrialOrder
            ? 'Trial activated! ₹1 will be refunded within 5–7 days.'
            : 'Subscription activated successfully!',
      );

      // Invalidate so UI re-fetches
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(paymentHistoryProvider);
      ref.invalidate(coinBalanceProvider);

      // Re-run AppAccess → GoRouter re-evaluates → navigates to correct screen
      await ref.read(appAccessProvider.notifier).refreshSubscription();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ── Handle failure ────────────────────────────────────────────────────────
  void _handlePaymentError(PaymentFailureResponse response) {
    final msg = response.code == 0
        ? 'Payment cancelled'
        : (response.message ?? 'Payment failed. Please try again.');
    state = state.copyWith(isLoading: false, error: msg);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) print('External wallet: ${response.walletName}');
  }

  // ── Cancel subscription ───────────────────────────────────────────────────
  Future<void> cancelSubscription() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await paymentService.cancelSubscription();
      state = state.copyWith(
        isLoading:      false,
        successMessage: 'Subscription cancelled.',
      );
      ref.invalidate(currentSubscriptionProvider);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearState() => state = PaymentState();
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