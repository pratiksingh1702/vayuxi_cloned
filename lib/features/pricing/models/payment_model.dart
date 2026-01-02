// lib/models/payment/razorpay_order.dart
class RazorpayOrder {
  final String orderId;
  final int amount;
  final String currency;
  final String key;

  final int? originalAmount;
  final int? coinsUsed;
  final int? discountAmount;

  RazorpayOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
    this.originalAmount,
    this.coinsUsed,
    this.discountAmount,
  });

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    return RazorpayOrder(
      orderId: json['orderId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
      key: json['key'] as String,
      originalAmount: json['originalAmount'] as int?,
      coinsUsed: json['coinsUsed'] as int?,
      discountAmount: json['discountAmount'] as int?,
    );
  }
}

// lib/models/payment/payment_verification.dart
class PaymentVerification {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  PaymentVerification({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    };
  }
}

// lib/models/payment/payment_response.dart
class PaymentResponse {
  final bool success;
  final String message;
  final PaymentDetails payment;
  final SubscriptionDetails subscription;

  PaymentResponse({
    required this.success,
    required this.message,
    required this.payment,
    required this.subscription,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      payment: PaymentDetails.fromJson(json['payment']),
      subscription: SubscriptionDetails.fromJson(json['subscription']),
    );
  }
}

class PaymentDetails {
  final String id;
  final double amount;
  final String status;
  final int? coinsUsed;

  PaymentDetails({
    required this.id,
    required this.amount,
    required this.status,
    this.coinsUsed,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      coinsUsed: json['coinsUsed'] as int?,
    );
  }
}

class SubscriptionDetails {
  final String plan;
  final String status;
  final String? trialEndDate;
  final String? currentPeriodEnd;
  final int aiUploadsLimit;
  final int? aiUploadsUsed;

  SubscriptionDetails({
    required this.plan,
    required this.status,
    this.trialEndDate,
    this.currentPeriodEnd,
    required this.aiUploadsLimit,
    this.aiUploadsUsed,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      plan: json['plan'] as String,
      status: json['status'] as String,
      trialEndDate: json['trialEndDate'] as String?,
      currentPeriodEnd: json['currentPeriodEnd'] as String?,
      aiUploadsLimit: json['aiUploadsLimit'] as int,
      aiUploadsUsed: json['aiUploadsUsed'] as int?,
    );
  }
}

// lib/models/payment/payment_history.dart
class PaymentHistory {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String paymentType;
  final String plan;
  final String createdAt;

  PaymentHistory({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentType,
    required this.plan,
    required this.createdAt,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      paymentType: json['paymentType'] as String,
      plan: json['plan'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

// lib/models/payment/subscription_order_request.dart
class SubscriptionOrderRequest {
  final String plan; // 'standard' or 'premium'
  final int vayuxiCoinsToUse;

  SubscriptionOrderRequest({
    required this.plan,
    this.vayuxiCoinsToUse = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'vayuxiCoinsToUse': vayuxiCoinsToUse,
    };
  }
}
class CoinBalance {
  final int balance;
  final int totalReferrals;
  final List<CoinTransaction> recentTransactions;

  CoinBalance({
    required this.balance,
    required this.totalReferrals,
    required this.recentTransactions,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    final transactions = (json['recentTransactions'] as List<dynamic>? ?? [])
        .map((t) => CoinTransaction.fromJson(t))
        .toList();

    return CoinBalance(
      balance: json['balance'] ?? 0,
      totalReferrals: json['totalReferrals'] ?? 0,
      recentTransactions: transactions,
    );
  }
}

class CoinTransaction {
  final String id;
  final int amount;
  final String type;
  final String description;
  final DateTime createdAt;

  CoinTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] ?? '',
      amount: json['amount'] ?? 0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ReferralCode {
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final int coinsEarned;

  ReferralCode({
    required this.referralCode,
    required this.referralLink,
    required this.totalReferrals,
    required this.coinsEarned,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      referralCode: json['referralCode'] ?? '',
      referralLink: json['referralLink'] ?? '',
      totalReferrals: json['totalReferrals'] ?? 0,
      coinsEarned: json['coinsEarned'] ?? 0,
    );
  }
}
class Subscription {
  final bool hasSubscription;
  final String? plan;
  final String? status;
  final int? daysRemaining;
  final int? aiUploadsUsed;
  final int? aiUploadsLimit;
  final int? aiUploadsRemaining;
  final bool? autoRenew;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final int? monthlyPrice;

  Subscription({
    required this.hasSubscription,
    this.plan,
    this.status,
    this.daysRemaining,
    this.aiUploadsUsed,
    this.aiUploadsLimit,
    this.aiUploadsRemaining,
    this.autoRenew,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.monthlyPrice,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      hasSubscription: json['hasSubscription'] ?? false,
      plan: json['plan'],
      status: json['status'],
      daysRemaining: json['daysRemaining'],
      aiUploadsUsed: json['aiUploadsUsed'],
      aiUploadsLimit: json['aiUploadsLimit'],
      aiUploadsRemaining: json['aiUploadsRemaining'],
      autoRenew: json['autoRenew'],
      currentPeriodStart: json['currentPeriodStart'] != null
          ? DateTime.parse(json['currentPeriodStart'])
          : null,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'])
          : null,
      monthlyPrice: json['monthlyPrice'],
    );
  }

  bool get isTrial => plan == 'trial';
  bool get isPremium => plan == 'premium';
  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';

  bool get hasUnlimitedUploads =>
      aiUploadsLimit == -1 || aiUploadsRemaining == -1;
}