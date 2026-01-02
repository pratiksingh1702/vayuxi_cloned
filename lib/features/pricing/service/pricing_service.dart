import 'package:dio/dio.dart';

import '../../../core/api/dio.dart';
import '../models/payment_model.dart';


class PaymentService {
  final Dio _dio;

  PaymentService() : _dio = DioClient.dio;

  // 1. Create Trial Order (₹1)
  Future<RazorpayOrder> createTrialOrder() async {
    try {
      final response = await _dio.post(
        '/payment/create-trial-order',
        data: {},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return RazorpayOrder.fromJson(data);
      } else {
        throw Exception('Failed to create trial order: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create trial order');
    } catch (e) {
      throw Exception('Error creating trial order: $e');
    }
  }

  // 2. Verify Trial Payment
  Future<PaymentResponse> verifyTrialPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final request = PaymentVerification(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      final response = await _dio.post(
        '/payment/verify-trial-payment',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return PaymentResponse.fromJson(data);
      } else {
        throw Exception('Payment verification failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to verify trial payment');
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  // 3. Create Subscription Order
  Future<RazorpayOrder> createSubscriptionOrder({
    required String plan, // 'standard' or 'premium'
    int vayuxiCoinsToUse = 0,
  }) async {
    try {
      final request = SubscriptionOrderRequest(
        plan: plan,
        vayuxiCoinsToUse: vayuxiCoinsToUse,
      );

      final response = await _dio.post(
        '/payment/create-subscription-order',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return RazorpayOrder.fromJson(data);
      } else {
        throw Exception('Failed to create subscription order: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create subscription order');
    } catch (e) {
      throw Exception('Error creating subscription order: $e');
    }
  }

  // 4. Verify Subscription Payment
  Future<PaymentResponse> verifySubscriptionPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final request = PaymentVerification(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

      final response = await _dio.post(
        '/payment/verify-subscription-payment',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return PaymentResponse.fromJson(data);
      } else {
        throw Exception('Payment verification failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to verify subscription payment');
    } catch (e) {
      throw Exception('Error verifying payment: $e');
    }
  }

  // 5. Get Current Subscription
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    try {
      final response = await _dio.get('/subscription/current');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get subscription: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get current subscription');
    } catch (e) {
      throw Exception('Error getting subscription: $e');
    }
  }

  // 6. Get Payment History
  Future<List<PaymentHistory>> getPaymentHistory({
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/payment/history',
        queryParameters: {'limit': limit, 'page': page},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final paymentsList = data['payments'] as List<dynamic>;
        return paymentsList.map((p) => PaymentHistory.fromJson(p)).toList();
      } else {
        throw Exception('Failed to get payment history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get payment history');
    } catch (e) {
      throw Exception('Error getting payment history: $e');
    }
  }

  // 7. Cancel Subscription
  Future<void> cancelSubscription() async {
    try {
      final response = await _dio.put('/subscription/cancel');

      if (response.statusCode != 200) {
        throw Exception('Failed to cancel subscription: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to cancel subscription');
    } catch (e) {
      throw Exception('Error cancelling subscription: $e');
    }
  }

  // 8. Get Coin Balance
  Future<Map<String, dynamic>> getCoinBalance() async {
    try {
      final response = await _dio.get('/coins/balance');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get coin balance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get coin balance');
    } catch (e) {
      throw Exception('Error getting coin balance: $e');
    }
  }

  // 9. Get Referral Code
  Future<Map<String, dynamic>> getReferralCode() async {
    try {
      final response = await _dio.get('/referral/my-code');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get referral code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get referral code');
    } catch (e) {
      throw Exception('Error getting referral code: $e');
    }
  }

  // Helper method to handle Dio errors
  String _handleDioError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'] as String;
      }
      return '${e.response!.statusCode}: ${e.response!.statusMessage}';
    }
    return defaultMessage;
  }
}