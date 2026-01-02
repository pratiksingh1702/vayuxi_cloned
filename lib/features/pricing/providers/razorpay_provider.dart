import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/payment_model.dart';
import '../service/pricing_service.dart';
import '../service/razor_pay_integeration_service.dart';


// Service Providers
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final razorpayServiceProvider = Provider<RazorpayIntegrationService>((ref) {
  return RazorpayIntegrationService();
});

// Current Subscription Provider
final currentSubscriptionProvider = FutureProvider<Subscription>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  final response = await service.getCurrentSubscription();

  if (response['success'] == true) {
    return Subscription.fromJson(response['subscription']);
  } else {
    throw Exception('Failed to get subscription');
  }
});

// Payment History Provider
final paymentHistoryProvider = FutureProvider<List<PaymentHistory>>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getPaymentHistory();
});

// Coin Balance Provider
final coinBalanceProvider = FutureProvider<CoinBalance>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  final response = await service.getCoinBalance();

  if (response['success'] == true) {
    return CoinBalance.fromJson(response);
  } else {
    throw Exception('Failed to get coin balance');
  }
});

// Referral Code Provider
final referralCodeProvider = FutureProvider<ReferralCode>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  final response = await service.getReferralCode();

  if (response['success'] == true) {
    return ReferralCode.fromJson(response);
  } else {
    throw Exception('Failed to get referral code');
  }
});

// Payment State Management
class PaymentState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final RazorpayOrder? currentOrder;

  PaymentState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.currentOrder,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    RazorpayOrder? currentOrder,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      currentOrder: currentOrder ?? this.currentOrder,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final Ref ref;
  final RazorpayIntegrationService razorpayService;
  final PaymentService paymentService;

  PaymentNotifier(this.ref, this.razorpayService, this.paymentService)
      : super(PaymentState());

  // Initialize Razorpay with callbacks
  void initializeRazorpay() {
    razorpayService.initialize(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  // Start Trial Payment
  Future<void> startTrialPayment() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final order = await paymentService.createTrialOrder();

      state = state.copyWith(currentOrder: order, isLoading: false);

      // Open Razorpay checkout
      _openTrialCheckout(order);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create trial order: $e',
      );
    }
  }

  // Start Subscription Payment
  Future<void> startSubscriptionPayment({
    required String plan,
    int coinsToUse = 0,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final order = await paymentService.createSubscriptionOrder(
        plan: plan,
        vayuxiCoinsToUse: coinsToUse,
      );

      state = state.copyWith(currentOrder: order, isLoading: false);

      // Open Razorpay checkout
      _openSubscriptionCheckout(order, plan);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create subscription order: $e',
      );
    }
  }

  // Open Trial Checkout
  void _openTrialCheckout(RazorpayOrder order) {
    // Get user details from shared preferences or auth provider
    final prefill = <String, String>{};
    print("opening checkout for trial ❤️❤️");

    razorpayService.openCheckout(
      key: order.key,
      orderId: order.orderId,
      amount: order.amount,
      name: 'Vayuxi ERP',
      description: 'Trial Subscription (₹1 Refundable)',
      prefill: prefill,
    );
  }

  // Open Subscription Checkout
  void _openSubscriptionCheckout(RazorpayOrder order, String plan) {
    final planName = plan == 'premium' ? 'Premium' : 'Standard';
    final amountInRupees = (order.amount / 100).toStringAsFixed(2);

    final prefill = <String, String>{};

    razorpayService.openCheckout(
      key: order.key,
      orderId: order.orderId,
      amount: order.amount,
      name: 'Vayuxi ERP',
      description: '$planName Plan - ₹$amountInRupees',
      prefill: prefill,
    );
  }

  // Handle Payment Success
  Future<void> _handlePaymentSuccess(RazorpaySuccessResponse response) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final order = state.currentOrder;

      if (order == null) {
        throw Exception('No order found');
      }

      // Determine if this is trial or subscription
      final isTrial = order.amount == 100; // ₹1 in paise

      if (isTrial) {
        await paymentService.verifyTrialPayment(
          razorpayOrderId: response.orderId,
          razorpayPaymentId: response.paymentId,
          razorpaySignature: response.signature,
        );
      } else {
        await paymentService.verifySubscriptionPayment(
          razorpayOrderId: response.orderId,
          razorpayPaymentId: response.paymentId,
          razorpaySignature: response.signature,
        );
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Payment successful! Subscription activated.',
      );

      // Invalidate subscription providers to refresh data
      ref.invalidate(currentSubscriptionProvider);
      ref.invalidate(paymentHistoryProvider);
      ref.invalidate(coinBalanceProvider);
      ref.invalidate(referralCodeProvider);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Payment verification failed: $e',
      );
    }
  }

  // Handle Payment Error
  void _handlePaymentError(PaymentFailureResponse response) {
    String errorMessage;

    switch (response.code) {
      case 0:
        errorMessage = 'Payment cancelled by user';
        break;
      default:
        errorMessage = response.message ?? 'Payment failed';
    }

    state = state.copyWith(
      isLoading: false,
      error: errorMessage,
    );
  }

  // Handle External Wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    // Can be used for tracking wallet usage
    if (kDebugMode) {
      print('External wallet selected: ${response.walletName}');
    }
  }

  // Cancel Subscription
  Future<void> cancelSubscription() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await paymentService.cancelSubscription();

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Subscription cancelled successfully.',
      );

      // Refresh subscription data
      ref.invalidate(currentSubscriptionProvider);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel subscription: $e',
      );
    }
  }

  // Clear payment state
  void clearState() {
    state = PaymentState();
  }
}

final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, PaymentState>(
      (ref) {
    final razorpayService = ref.watch(razorpayServiceProvider);
    final paymentService = ref.watch(paymentServiceProvider);
    return PaymentNotifier(ref, razorpayService, paymentService);
  },
);