// features/auth/screens/TrialScreen.dart
//
// Uses /trial-onboarding/create-order (with referralCode) directly via
// PaymentService, then hands the pre-built order to PaymentNotifier so
// Razorpay opens. On Razorpay success, the notifier calls
// /trial-onboarding/activate (snake_case body) and refreshes AppAccess.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pricing/models/payment_model.dart';
import '../../pricing/providers/razorpay_provider.dart';
import '../../pricing/service/pricing_service.dart';

class TrialScreen extends ConsumerStatefulWidget {
  const TrialScreen({super.key});

  @override
  ConsumerState<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends ConsumerState<TrialScreen> {
  final _referralCtrl = TextEditingController();
  bool    _creatingOrder = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentNotifierProvider.notifier).initializeRazorpay();
    });
  }

  @override
  void dispose() {
    _referralCtrl.dispose();

    super.dispose();
  }

  // ── Create order via /trial-onboarding/create-order then open Razorpay ───
  Future<void> _pay() async {
    final code = _referralCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _localError = 'Please enter your referral code from the email.');
      return;
    }

    setState(() {
      _creatingOrder = true;
      _localError    = null;
    });

    try {
      // PaymentService.createTrialOrder now takes referralCode
      final order = await PaymentService().createTrialOrder(
        referralCode: code,
      );

      if (!mounted) return;
      setState(() => _creatingOrder = false);

      // Hand off to notifier — it opens Razorpay and calls /trial-onboarding/activate
      await ref
          .read(paymentNotifierProvider.notifier)
          .startTrialPayment(prebuiltOrder: order);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _creatingOrder = false;
        _localError    = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final isLoading    = _creatingOrder || paymentState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Hero icon ──────────────────────────────────────────────
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 20, offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 32),

              const Text(
                'Activate Your Trial',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B), letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the referral code from your email to activate 30 days of full access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16, color: Color(0xFF64748B), height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // ── Features ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _Feature(icon: Icons.check_circle_outline,
                        title: 'Full Access',
                        subtitle: 'All features unlocked for 30 days'),
                    const SizedBox(height: 20),
                    _Feature(icon: Icons.cloud_upload_outlined,
                        title: '2 AI Uploads',
                        subtitle: 'Explore our AI analysis feature'),
                    const SizedBox(height: 20),
                    _Feature(icon: Icons.security,
                        title: 'Secure & Private',
                        subtitle: 'Your data is safe with us'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Referral code input ────────────────────────────────────
              _ReferralField(
                controller: _referralCtrl,
                error:      _localError,
                enabled:    !isLoading,
              ),
              const SizedBox(height: 16),

              // ── ₹1 info card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline,
                          color: Color(0xFF6366F1), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '₹1 refundable verification. Refund within 5–7 business days.',
                        style: TextStyle(
                          fontSize: 13, color: Color(0xFF475569), height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── CTA ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Activate Trial · ₹1',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          )),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),

              // ── Razorpay / network error ───────────────────────────────
              if (paymentState.error != null) ...[
                const SizedBox(height: 16),
                _ErrorBanner(message: paymentState.error!),
              ],

              const SizedBox(height: 24),
              const Text(
                'By continuing you agree to our Terms of Service and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, color: Color(0xFF94A3B8), height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final bool enabled;
  const _ReferralField(
      {required this.controller, required this.error, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Referral Code',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'e.g. ABC123XY',
            prefixIcon: const Icon(Icons.vpn_key_rounded,
                color: Color(0xFF6366F1), size: 20),
            filled: true,
            fillColor: Colors.white,
            errorText: error,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Check your email for the code sent after completing the questionnaire.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6366F1), size: 22),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                )),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      ),
    ],
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline,
            color: Color(0xFFDC2626), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                  color: Color(0xFFDC2626), fontSize: 13)),
        ),
      ],
    ),
  );
}