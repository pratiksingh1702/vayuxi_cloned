import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pricing/providers/razorpay_provider.dart';

Future<void> ensureTrialIfNoSubscription(Ref ref) async {
  try {
    final subscription = await ref.read(currentSubscriptionProvider.future);

    if (subscription.hasSubscription == false) {
      // 🚨 Force trial payment
      await Future.delayed(const Duration(milliseconds: 300));


      await ref.read(paymentNotifierProvider.notifier).startTrialPayment();
    }
  } catch (e) {
    // If API fails, still force trial
    await Future.delayed(const Duration(milliseconds: 300));
    await ref.read(paymentNotifierProvider.notifier).startTrialPayment();

  }
}
