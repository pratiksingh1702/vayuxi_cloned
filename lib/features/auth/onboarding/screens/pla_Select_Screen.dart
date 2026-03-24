// features/pricing/Screens/plan_select_screen.dart
//
// Shown once after login/register (before onboarding).
// Uses the same AppColors + AppTextStyles design tokens as SubscriptionScreen.
//
// FLOW:
//   Trial selected   → markPlanSelected() → router sends to /onboarding
//   Paid plan tapped → Razorpay → on success → refreshSubscription()
//                      → router sends directly to workCategory

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// Re-use design tokens and PlanData model from SubscriptionScreen
import '../../../../core/router/app_access.dart';
import '../../../pricing/providers/razorpay_provider.dart';
import '../../../pricing/Screens/subsciption_screen.dart'
    show AppColors, AppTextStyles, PlanData, PlanWeight, CoinMath, kPlans;

class PlanSelectScreen extends ConsumerStatefulWidget {
  const PlanSelectScreen({super.key});

  @override
  ConsumerState<PlanSelectScreen> createState() => _PlanSelectScreenState();
}

class _PlanSelectScreenState extends ConsumerState<PlanSelectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fadeAnim =
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentNotifierProvider.notifier).initializeRazorpay();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    ref.read(razorpayServiceProvider).dispose();
    super.dispose();
  }

  // ── Plan tap handler ─────────────────────────────────────────────────────
  void _onPlanTap(PlanData plan) {
    HapticFeedback.lightImpact();

    if (plan.id == 'trial') {
      // Mark plan selected → router redirect fires → /onboarding
      ref.read(appAccessProvider.notifier).markPlanSelected();
    } else {
      // Start paid subscription directly
      ref.read(paymentNotifierProvider.notifier).startSubscriptionPayment(
        plan: plan.id,
        coinsToUse: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.goldDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  size: 12, color: AppColors.gold),
                              const SizedBox(width: 6),
                              Text('Welcome to Vayuxi ERP',
                                  style: AppTextStyles.badgeText
                                      .copyWith(color: AppColors.gold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Choose how you\nwant to start',
                          style: AppTextStyles.screenTitle.copyWith(
                            fontSize: 28,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can upgrade or downgrade anytime.',
                          style: AppTextStyles.featureText
                              .copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                // ── Plan cards ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        if (i >= kPlans.length) return null;
                        final plan = kPlans[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SelectablePlanCard(
                            plan: plan,
                            isLoading: paymentState.isLoading,
                            onTap: paymentState.isLoading
                                ? null
                                : () => _onPlanTap(plan),
                          ),
                        );
                      },
                      childCount: kPlans.length,
                    ),
                  ),
                ),

                // ── Error / success banner ─────────────────────────────────
                if (paymentState.error != null ||
                    paymentState.successMessage != null)
                  SliverPadding(
                    padding:
                    const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _StatusBanner(state: paymentState),
                    ),
                  ),

                // ── Loading indicator ──────────────────────────────────────
                if (paymentState.isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  color: AppColors.gold, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text('Processing payment…',
                                style: AppTextStyles.featureText),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Trust row ──────────────────────────────────────────────
                SliverPadding(
                  padding:
                  const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TrustChip(
                                icon: Icons.lock_rounded,
                                label: 'Secure payment'),
                            const SizedBox(width: 16),
                            _TrustChip(
                                icon: Icons.cancel_outlined,
                                label: 'Cancel anytime'),
                            const SizedBox(width: 16),
                            _TrustChip(
                                icon: Icons.replay_rounded,
                                label: '₹1 '),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'By continuing you agree to our Terms of Service.',
                          style: AppTextStyles.featureText
                              .copyWith(fontSize: 11,
                              color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SELECTABLE PLAN CARD
// Stripped-down version of _PlanCard — no coin toggle, no secondary expand.
// Just the key info + one clear CTA.
// ─────────────────────────────────────────────────────────────────────────────

class _SelectablePlanCard extends StatelessWidget {
  final PlanData plan;
  final bool isLoading;
  final VoidCallback? onTap;

  const _SelectablePlanCard({
    required this.plan,
    required this.isLoading,
    this.onTap,
  });

  bool get _isTrial => plan.id == 'trial';

  String get _ctaLabel {
    switch (plan.id) {
      case 'premium':  return 'Start Premium · ₹${plan.priceMonthly}/mo';
      case 'yearly':   return 'Get Yearly · ₹${plan.priceMonthly}/yr  ≈ ₹1,250/mo';
      case 'standard': return 'Start Standard · ₹${plan.priceMonthly}/mo';
      case 'trial':    return 'Try for 30 days ';
      default:         return 'Get started';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = plan.accentColor;
    final isHero = plan.badge.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHero
              ? accent.withOpacity(0.35)
              : AppColors.divider,
          width: isHero ? 1.5 : 1.0,
        ),
        boxShadow: isHero
            ? [
          BoxShadow(
            color: accent.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ]
            : [],
      ),
      child: Opacity(
        opacity: _isTrial ? 0.82 : 1.0,
        child: Column(
          children: [
            // Gradient top strip
            Container(
              height: _isTrial ? 3 : 5,
              decoration: BoxDecoration(
                gradient: plan.cardGradient,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name + badge
                  Row(
                    children: [
                      Text(plan.name, style: AppTextStyles.planTitle),
                      const SizedBox(width: 8),
                      if (plan.badge.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(plan.badge,
                              style: AppTextStyles.badgeText
                                  .copyWith(color: accent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(plan.tagline,
                      style: AppTextStyles.featureText
                          .copyWith(fontSize: 11)),
                  const SizedBox(height: 12),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isTrial ? '₹1' : '₹${plan.priceMonthly}',
                        style: AppTextStyles.priceMain,
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          _isTrial
                              ? ' for Trial'
                              : plan.id == 'yearly'
                              ? '/year'
                              : '/month',
                          style: AppTextStyles.featureText.copyWith(fontSize: 11),
                        ),
                      ),
                      // Yearly: show effective monthly cost next to price
                      if (plan.id == 'yearly') ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '≈ ₹1,250/mo',
                              style: AppTextStyles.badgeText
                                  .copyWith(color: AppColors.teal),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Features
                  ...plan.features.map(
                        (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(Icons.check_rounded,
                              size: 13, color: accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(f,
                                style: AppTextStyles.featureText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: GestureDetector(
                      onTap: isLoading ? null : onTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isLoading || _isTrial
                              ? null
                              : plan.cardGradient,
                          color: isLoading
                              ? AppColors.divider
                              : _isTrial
                              ? AppColors.surface
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          border: _isTrial
                              ? Border.all(color: AppColors.divider)
                              : null,
                          boxShadow: !isLoading && !_isTrial
                              ? [
                            BoxShadow(
                              color: accent.withOpacity(0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: isLoading
                            ? SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textMuted),
                        )
                            : Text(
                          _ctaLabel,
                          style: AppTextStyles.ctaLabel.copyWith(
                            color: isLoading
                                ? AppColors.textMuted
                                : _isTrial
                                ? AppColors.textSecondary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Delta nudge (Standard → Premium upsell)
                  // if (plan.deltaText.isNotEmpty) ...[
                  //   const SizedBox(height: 8),
                  //   Text(
                  //     plan.deltaText,
                  //     style: AppTextStyles.deltaLabel.copyWith(
                  //       color: plan.id == 'standard'
                  //           ? AppColors.gold.withOpacity(0.65)
                  //           : AppColors.textMuted,
                  //       fontStyle: FontStyle.italic,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(label,
          style: AppTextStyles.featureText.copyWith(fontSize: 10)),
    ],
  );
}

class _StatusBanner extends StatelessWidget {
  final PaymentState state;
  const _StatusBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final isError = state.error != null;
    final msg = state.error ?? state.successMessage ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.rose.withOpacity(0.09)
            : AppColors.teal.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? AppColors.rose.withOpacity(0.28)
              : AppColors.teal.withOpacity(0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.rose : AppColors.teal,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: AppTextStyles.featureText
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}