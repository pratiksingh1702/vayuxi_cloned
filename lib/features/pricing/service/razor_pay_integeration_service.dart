import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayIntegrationService {
  late Razorpay _razorpay;
  Function(RazorpaySuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  void initialize({
    required Function(RazorpaySuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onSuccess != null) {
      final successResponse = RazorpaySuccessResponse(
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );
      _onSuccess!(successResponse);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onError != null) {
      _onError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_onExternalWallet != null) {
      _onExternalWallet!(response);
    }
  }

  void openCheckout({
    required String key,
    required String orderId,
    required int amount, // in paise
    required String name,
    required String description,
    Map<String, String>? prefill,
    Map<String, dynamic>? options,
  }) {
    final checkoutOptions = {
      'key': key,
      'amount': amount,
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': prefill ?? {},
      'external': {
        'wallets': ['paytm', 'phonepe', 'googlepay', 'bhim'],
      },
      'theme': {
        'color': '#2563eb',
      },
      ...?options,
    };

    try {
      _razorpay.open(checkoutOptions);
    } catch (e) {
      if (_onError != null) {
        _onError!(
          PaymentFailureResponse(
            Razorpay.UNKNOWN_ERROR,
            'Razorpay open failed',
            {
              'description': e.toString(),
            },
          ),
        );
      }
    }

  }
}

// Custom response models for easier handling
class RazorpaySuccessResponse {
  final String orderId;
  final String paymentId;
  final String signature;

  RazorpaySuccessResponse({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });
}