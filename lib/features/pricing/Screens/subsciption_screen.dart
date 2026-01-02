import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../providers/razorpay_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentNotifierProvider.notifier).initializeRazorpay();
    });
  }

  @override
  void dispose() {
    ref.read(razorpayServiceProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Plans & Billing'),
        centerTitle: true,
        elevation: 0,
      ),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (subscription) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _currentPlanCard(subscription),
                const SizedBox(height: 24),

                _pricingHeader(),
                const SizedBox(height: 16),

                _planCard(
                  title: "Trial",
                  price: "₹1",
                  subtitle: "30 days • Refundable",
                  features: const [
                    "2 AI uploads",
                    "Basic reports",
                    "Email support",
                  ],
                  cta: "Start Trial",
                  color: Colors.blue,
                  disabled: subscription.hasSubscription,
                  onTap: paymentState.isLoading
                      ? null
                      : () => ref
                      .read(paymentNotifierProvider.notifier)
                      .startTrialPayment(),
                ),

                const SizedBox(height: 16),

                _planCard(
                  title: "Standard",
                  price: "₹799 / month",
                  subtitle: "Most popular",
                  highlight: true,
                  features: const [
                    "50 AI uploads / month",
                    "Priority support",
                    "Analytics & reports",
                    "Referral rewards",
                  ],
                  cta: "Upgrade to Standard",
                  color: Colors.green,
                  onTap: paymentState.isLoading
                      ? null
                      : () => ref
                      .read(paymentNotifierProvider.notifier)
                      .startSubscriptionPayment(plan: 'standard'),
                ),

                const SizedBox(height: 16),

                _planCard(
                  title: "Premium",
                  price: "₹1499 / month",
                  subtitle: "For enterprises",
                  features: const [
                    "Unlimited AI uploads",
                    "24/7 priority support",
                    "Advanced analytics",
                    "Unlimited team members",
                  ],
                  cta: "Upgrade to Premium",
                  color: Colors.deepPurple,
                  onTap: paymentState.isLoading
                      ? null
                      : () => ref
                      .read(paymentNotifierProvider.notifier)
                      .startSubscriptionPayment(plan: 'premium'),
                ),

                if (paymentState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),

                if (paymentState.error != null)
                  _statusBanner(
                    message: paymentState.error!,
                    isError: true,
                    onClose: () => ref
                        .read(paymentNotifierProvider.notifier)
                        .clearState(),
                  ),

                if (paymentState.successMessage != null)
                  _statusBanner(
                    message: paymentState.successMessage!,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===================== UI COMPONENTS =====================

  Widget _pricingHeader() {
    return Column(
      children: const [
        Text(
          "Choose the plan that fits your business",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          "Upgrade anytime. Cancel anytime.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _currentPlanCard(Subscription subscription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: subscription.hasSubscription
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Current Plan",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            subscription.plan!.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subscription.hasUnlimitedUploads
                ? "Unlimited AI uploads"
                : "${subscription.aiUploadsRemaining} uploads remaining",
            style: const TextStyle(color: Colors.white),
          ),
          if (!subscription.isTrial)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    _showCancelDialog(context, ref),
                child: const Text(
                  "Cancel Subscription",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      )
          : const Text(
        "No active subscription",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String price,
    required String subtitle,
    required List<String> features,
    required String cta,
    required Color color,
    bool highlight = false,
    bool disabled = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: color, width: 2)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "MOST POPULAR",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Text(title,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Text(price,
              style:
              const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          ...features.map(
                (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: disabled ? null : onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(cta,style: TextStyle(color: Colors.white),),
          )
        ],
      ),
    );
  }

  Widget _statusBanner({
    required String message,
    bool isError = false,
    VoidCallback? onClose,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isError ? Colors.red[50] : Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (onClose != null)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'You will retain access until the end of the billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(paymentNotifierProvider.notifier)
                  .cancelSubscription();
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
