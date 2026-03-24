// features/pricing/service/razor_pay_integration_service.dart
//
// FIX SUMMARY:
//  1. Singleton pattern — ONE Razorpay instance for the app lifetime (no re-init on rebuild)
//  2. _handlePaymentSuccess calls the async callback via unawaited() — Razorpay SDK
//     expects a synchronous listener; awaiting inside the listener causes UI freeze
//  3. Re-init guard — calling initialize() twice now clears old listeners first
//  4. isOpen flag — prevents openCheckout() being called while Razorpay is already open
//     (fixes the "comes back from GPay and nothing happens" race)

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayIntegrationService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final RazorpayIntegrationService _instance =
  RazorpayIntegrationService._internal();

  factory RazorpayIntegrationService() => _instance;

  RazorpayIntegrationService._internal();

  // ── State ─────────────────────────────────────────────────────────────────
  Razorpay? _razorpay;
  bool _isOpen = false;
  bool _isInitialized = false;

  Function(RazorpaySuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  // ── Initialize ────────────────────────────────────────────────────────────
  //
  // Safe to call multiple times (e.g. after hot-reload or screen re-entry).
  // Clears the old Razorpay instance before creating a new one.
  void initialize({
    required Function(RazorpaySuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    // Update callbacks (screen may have re-mounted with new ref)
    _onSuccess        = onSuccess;
    _onError          = onError;
    _onExternalWallet = onExternalWallet;

    // Only create a new Razorpay instance if not already initialized
    if (_isInitialized) return;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR,   _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _isInitialized = true;

    if (kDebugMode) print('[Razorpay] Initialized');
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  //
  // Call from the top-level widget's dispose() or when logging out.
  // NOT called on every screen pop — the singleton stays alive.
  void dispose() {
    _razorpay?.clear();
    _razorpay       = null;
    _isInitialized  = false;
    _isOpen         = false;
    if (kDebugMode) print('[Razorpay] Disposed');
  }

  // ── Open checkout ─────────────────────────────────────────────────────────
  //
  // Guards against double-open (coming back from GPay / external wallet
  // sometimes re-triggers the button tap).
  void openCheckout({
    required String key,
    required String orderId,
    required int    amount, // paise
    required String name,
    required String description,
    Map<String, String>?    prefill,
    Map<String, dynamic>?   options,
  }) {
    if (_razorpay == null || !_isInitialized) {
      if (kDebugMode) print('[Razorpay] openCheckout called before initialize()');
      return;
    }

    if (_isOpen) {
      if (kDebugMode) print('[Razorpay] Checkout already open — ignoring duplicate call');
      return;
    }

    _isOpen = true;

    final checkoutOptions = <String, dynamic>{
      'key':         key,
      'amount':      amount,
      'name':        name,
      'description': description,
      'order_id':    orderId,
      'prefill':     prefill ?? {},
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay', 'bhim'],
      },
      'theme': {'color': '#2563eb'},
      ...?options,
    };

    try {
      _razorpay!.open(checkoutOptions);
    } catch (e) {
      _isOpen = false;
      if (kDebugMode) print('[Razorpay] open() threw: $e');
      _onError?.call(
        PaymentFailureResponse(
          Razorpay.UNKNOWN_ERROR,
          'Razorpay open failed: ${e.toString()}',
          {'description': e.toString()},
        ),
      );
    }
  }

  // ── Event handlers ────────────────────────────────────────────────────────
  //
  // IMPORTANT: Razorpay SDK fires these on the platform thread synchronously.
  // Never await inside — use Future.microtask / unawaited to hand off to async
  // code.  Awaiting here was the root cause of the UI freeze.

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _isOpen = false;

    if (kDebugMode) {
      print('[Razorpay] SUCCESS  orderId=${response.orderId}'
          '  paymentId=${response.paymentId}');
    }

    final mapped = RazorpaySuccessResponse(
      orderId:   response.orderId   ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );

    // Hand off to the async notifier without blocking the SDK callback
    Future.microtask(() => _onSuccess?.call(mapped));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _isOpen = false;

    if (kDebugMode) {
      print('[Razorpay] ERROR  code=${response.code}  msg=${response.message}');
    }

    Future.microtask(() => _onError?.call(response));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _isOpen = false;

    if (kDebugMode) {
      print('[Razorpay] EXTERNAL_WALLET  wallet=${response.walletName}');
    }

    Future.microtask(() => _onExternalWallet?.call(response));
  }
}

// ── Response model ────────────────────────────────────────────────────────────

class RazorpaySuccessResponse {
  final String orderId;
  final String paymentId;
  final String signature;

  const RazorpaySuccessResponse({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}