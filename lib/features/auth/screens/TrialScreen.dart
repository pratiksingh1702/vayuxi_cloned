// features/auth/screens/TrialScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../pricing/models/payment_model.dart';
import '../../pricing/providers/razorpay_provider.dart';
import '../../pricing/service/pricing_service.dart';
import '../../pricing/Screens/subsciption_screen.dart';

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
      // FIX: Clear any stale error/success from a previous session before init
      ref.read(paymentNotifierProvider.notifier).clearState();
      ref.read(paymentNotifierProvider.notifier).initializeRazorpay();
    });
  }

  @override
  void dispose() {
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final code = _referralCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _localError = 'Please enter your referral code.');
      return;
    }

    setState(() {
      _creatingOrder = true;
      _localError    = null;
    });

    try {
      // FIX: Use the provider's paymentService instead of a raw PaymentService()
      // instantiation — avoids creating a second Dio client outside the provider
      // graph, which was a source of extra network overhead and missing auth tokens
      // on retry.
      final order = await ref
          .read(paymentServiceProvider)
          .createTrialOrder(referralCode: code);

      if (!mounted) return;
      setState(() => _creatingOrder = false);

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
    // FIX: ref.listen handles side-effects (SnackBar, navigation) without
    // causing build() to re-run. Previously, showing a SnackBar inside build()
    // or a watch callback would trigger another rebuild → lag loop.
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      // Show success snackbar (navigation itself is handled by GoRouter via
      // appAccessProvider.refreshSubscription() inside the notifier)
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(next.successMessage!),
            backgroundColor: Colors.green.shade700,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    });

    final paymentState = ref.watch(paymentNotifierProvider);
    final isLoading    = _creatingOrder || paymentState.isLoading;

    // Merge provider error + local error: local takes priority so the referral
    // field error shows inline, not in the banner
    final bannerError = _localError == null ? paymentState.error : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:          Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor:   AppColors.bg,
          surfaceTintColor:  Colors.transparent,
          elevation:         0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Heading ───────────────────────────────────────────────
              Text('Activate free trial',
                  style: AppTextStyles.planTitle
                      .copyWith(fontSize: 22, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(
                'We sent a referral code to your registered email. Enter it below to get 30-day free access.',
                style: AppTextStyles.featureText
                    .copyWith(fontSize: 13.5, height: 1.5),
              ),

              const SizedBox(height: 32),

              // ── Input label ───────────────────────────────────────────
              Text('Referral code',
                  style: AppTextStyles.featureText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),

              // ── Text field ────────────────────────────────────────────
              TextField(
                controller:            _referralCtrl,
                enabled:               !isLoading,
                textCapitalization:    TextCapitalization.characters,
                style: AppTextStyles.planTitle.copyWith(
                    fontSize: 16, letterSpacing: 2),
                onChanged: (_) {
                  // Clear both local and provider errors as user types
                  if (_localError != null) {
                    setState(() => _localError = null);
                  }
                  // FIX: Also clear the provider error so the banner disappears
                  // when the user edits the field after a failed attempt
                  if (paymentState.error != null) {
                    ref.read(paymentNotifierProvider.notifier).clearState();
                  }
                },
                decoration: InputDecoration(
                  hintText:  'e.g. ABC123XY',
                  hintStyle: AppTextStyles.featureText.copyWith(
                      fontSize: 15,
                      letterSpacing: 0,
                      color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.vpn_key_rounded,
                      size: 18, color: AppColors.textMuted),
                  filled:     true,
                  fillColor:  AppColors.card,
                  errorText:  _localError,
                  errorStyle: AppTextStyles.featureText.copyWith(
                      fontSize: 12, color: AppColors.rose),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.teal, width: 1.8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.rose.withOpacity(0.6)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.rose, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 8),
              Text(
                "Didn't receive it? Check your spam folder.",
                style: AppTextStyles.featureText
                    .copyWith(fontSize: 11.5, color: AppColors.textMuted),
              ),

              // ── Razorpay / network error banner ───────────────────────
              // FIX: Only shows provider errors here (not local field errors,
              // those appear inline in the TextField via errorText above)
              if (bannerError != null) ...[
                const SizedBox(height: 14),
                _ErrorBanner(message: bannerError),
              ],

              const Spacer(),

              // ── ₹1 note ───────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '₹1 is only to Explore the app.',
                      style: AppTextStyles.featureText
                          .copyWith(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── CTA button ────────────────────────────────────────────
              GestureDetector(
                onTap: isLoading ? null : _pay,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width:  double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: isLoading
                        ? null
                        : const LinearGradient(
                      colors: [
                        AppColors.teal,
                        Color(0xFF0891B2),
                      ],
                      begin: Alignment.centerLeft,
                      end:   Alignment.centerRight,
                    ),
                    color:         isLoading ? AppColors.divider : null,
                    borderRadius:  BorderRadius.circular(14),
                    boxShadow: isLoading
                        ? []
                        : [
                      BoxShadow(
                        color: AppColors.teal.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                      : Text('Activate Trial · ₹1',
                      style: AppTextStyles.ctaLabel.copyWith(
                          color: Colors.white, fontSize: 15)),
                ),
              ),

              SizedBox(
                  height: 16 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER  — unchanged
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.rose.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.rose.withOpacity(0.22)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.rose, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: AppTextStyles.featureText.copyWith(
                  fontSize: 12, color: AppColors.textPrimary)),
        ),
      ],
    ),
  );
}