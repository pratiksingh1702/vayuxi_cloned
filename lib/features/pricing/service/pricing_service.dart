// features/pricing/service/pricing_service.dart
//
// API ENDPOINTS (matched exactly to v2.0 API docs):
//
//  TRIAL FLOW  (all under /trial-onboarding/*)
//    POST /trial-onboarding/create-order       ← create ₹1 Razorpay order
//    POST /trial-onboarding/activate           ← verify payment + activate
//
//  SUBSCRIPTION (all under /payment/*)
//    POST /payment/create-subscription-order   ← create paid plan order
//    POST /payment/verify-subscription-payment ← verify + activate paid plan
//
//  SUBSCRIPTION STATUS
//    GET  /subscription/current
//
//  MISC
//    GET  /payment/history
//    PUT  /subscription/cancel
//    GET  /coins/balance
//    GET  /referral/my-code

import 'package:dio/dio.dart';

import '../../../core/api/dio.dart';
import '../models/payment_model.dart';

class PaymentService {
  // DioClient.dio already has the base URL + auth interceptor attached.
  final _dio = DioClient.dio;

  // ── TRIAL: Create ₹1 Razorpay order ──────────────────────────────────────
  //
  // POST /api/v1/trial-onboarding/create-order
  // Body: { "referralCode": "ABC123XY" }
  //
  // Response shape:
  // {
  //   "success": true,
  //   "order": { "id": "...", "amount": 100, "currency": "INR" },
  //   "key": "rzp_test_xxx"
  // }
  Future<RazorpayOrder> createTrialOrder({required String referralCode}) async {
    try {
      final response = await _dio.post(
        '/trial-onboarding/create-order',
        data: {'referralCode': referralCode},
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to create trial order');
      }

      // The order lives inside data['order'], key is at data['key']
      final orderMap = data['order'] as Map<String, dynamic>;

      return RazorpayOrder(
        orderId:  orderMap['id']       as String,
        amount:   orderMap['amount']   as int,
        currency: orderMap['currency'] as String,
        key:      data['key']          as String,
      );
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to create trial order'));
    }
  }

  // ── TRIAL: Verify payment + activate trial ────────────────────────────────
  //
  // POST /api/v1/trial-onboarding/activate
  // Body (snake_case — matches what Razorpay SDK returns):
  // {
  //   "razorpay_order_id":   "order_xxx",
  //   "razorpay_payment_id": "pay_xxx",
  //   "razorpay_signature":  "sig_xxx"
  // }
  //
  // Response shape:
  // {
  //   "success": true,
  //   "message": "Trial activated successfully",
  //   "data": {
  //     "subscription": { "plan": "trial", "status": "active", ... },
  //     "refund":        { "id": "rfnd_xxx", "amount": 100, ... }
  //   }
  // }
  Future<void> verifyTrialPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dio.post(
        '/trial-onboarding/activate',
        data: {
          'razorpay_order_id':   razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature':  razorpaySignature,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(
            data['message'] ?? 'Trial activation failed');
      }
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to activate trial'));
    }
  }

  // ── PAID PLAN: Create Razorpay order ─────────────────────────────────────
  //
  // POST /api/v1/payment/create-subscription-order
  // Body: { "plan": "standard"|"premium"|"yearly", "vayuxiCoinsToUse": 0,
  //         "gstApplied": false, "gstNumber"?: "...", ... }
  //
  // Response shape:
  // {
  //   "success":     true,
  //   "orderId":     "order_xxx",
  //   "amount":      99900,
  //   "currency":    "INR",
  //   "key":         "rzp_test_xxx",
  //   "finalAmount": 999,    ← after coin discount (rupees)
  //   ...
  // }
  Future<RazorpayOrder> createSubscriptionOrder({
    required String plan,
    int vayuxiCoinsToUse = 0,
    bool gstApplied = false,
    String? gstNumber,
    String? companyName,
    String? billingAddress,
  }) async {
    try {
      final body = <String, dynamic>{
        'plan':             plan,
        'vayuxiCoinsToUse': vayuxiCoinsToUse,
        'gstApplied':       gstApplied,
        if (gstApplied && gstNumber != null) 'gstNumber': gstNumber,
        if (companyName != null)              'companyName': companyName,
        if (billingAddress != null)           'billingAddress': billingAddress,
      };

      final response = await _dio.post(
        '/payment/create-subscription-order',
        data: body,
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(
            data['message'] ?? 'Failed to create subscription order');
      }

      // Response uses "orderId" (camelCase) at the root level
      return RazorpayOrder(
        orderId:        data['orderId']  as String,
        amount:         data['amount']   as int,
        currency:       data['currency'] as String,
        key:            data['key']      as String,
        coinsUsed:      data['coinsUsed']      as int?,
        discountAmount: _toIntSafe(data['gst']),
      );
    } on DioException catch (e) {
      throw Exception(
          _extractDioError(e, 'Failed to create subscription order'));
    }
  }

  // ── PAID PLAN: Verify payment + activate ──────────────────────────────────
  //
  // POST /api/v1/payment/verify-subscription-payment
  // Body (camelCase — matches API docs):
  // {
  //   "razorpayOrderId":   "order_xxx",
  //   "razorpayPaymentId": "pay_xxx",
  //   "razorpaySignature": "sig_xxx"
  // }
  //
  // Response shape:
  // {
  //   "success": true,
  //   "message": "Subscription payment verified and plan upgraded",
  //   "payment":      { ... },
  //   "subscription": { "plan": "premium", "status": "active", ... }
  // }
  Future<void> verifySubscriptionPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _dio.post(
        '/payment/verify-subscription-payment',
        data: {
          'razorpayOrderId':   razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['success'] != true) {
        throw Exception(
            data['message'] ?? 'Subscription payment verification failed');
      }
    } on DioException catch (e) {
      throw Exception(
          _extractDioError(e, 'Failed to verify subscription payment'));
    }
  }

  // ── GET current subscription ──────────────────────────────────────────────
  //
  // GET /api/v1/subscription/current
  // Response: { "success": true, "subscription": { ... } }
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    try {
      final response = await _dio.get('/subscription/current');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to get subscription'));
    }
  }

  // ── Payment history ───────────────────────────────────────────────────────
  Future<List<PaymentHistory>> getPaymentHistory({
    int limit = 10,
    int page  = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/payment/history',
        queryParameters: {'limit': limit, 'page': page},
      );
      final data     = response.data as Map<String, dynamic>;
      final list     = data['payments'] as List<dynamic>;
      return list.map((p) => PaymentHistory.fromJson(p)).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to get payment history'));
    }
  }

  // ── Cancel subscription ───────────────────────────────────────────────────
  Future<void> cancelSubscription() async {
    try {
      await _dio.put('/subscription/cancel');
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to cancel subscription'));
    }
  }

  // ── Coin balance ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCoinBalance() async {
    try {
      final response = await _dio.get('/coins/balance');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to get coin balance'));
    }
  }

  // ── Referral code ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReferralCode() async {
    try {
      final response = await _dio.get('/referral/my-code');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractDioError(e, 'Failed to get referral code'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Extract a human-readable message from a DioException.
  String _extractDioError(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map) {
      final msg = body['message'] ?? body['error'];
      if (msg != null) return msg.toString();
    }
    return '${e.response?.statusCode ?? ''} $fallback'.trim();
  }

  int? _toIntSafe(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }
}