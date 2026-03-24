import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_access.dart';
import '../providers/razorpay_provider.dart';
import '../models/payment_model.dart';
import 'subsciption_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLAN DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PlanDetailScreen extends ConsumerStatefulWidget {
  final PlanData     plan;
  final int          userCoins; // kept for future coin logic
  final Subscription sub;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    required this.userCoins,
    required this.sub,
  });

  @override
  ConsumerState<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends ConsumerState<PlanDetailScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final Animation<double>    _fadeAnim;

  // ── Coins hidden from UI — logic preserved ────────────────────────────────
  // int  _coinsApplied = 0;
  // bool _coinsEnabled = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
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

  bool get _isTrial    => widget.plan.tier == PlanTier.trial;
  bool get _isPremium  => widget.plan.tier == PlanTier.premium;
  bool get _isStandard => widget.plan.tier == PlanTier.standard;
  bool get _isThisPlan => widget.sub.plan == widget.plan.id;
  bool get _isActive   => _isThisPlan && widget.sub.isActive;

  bool get _shouldFetchProration =>
      widget.sub.hasSubscription &&
          widget.sub.isActive &&
          widget.sub.plan != widget.plan.id &&
          !_isTrial;

  void _payMonthly() {
    HapticFeedback.lightImpact();
    if (_isTrial) {
      final appAccess = ref.read(appAccessProvider);
      if (!appAccess.onboardingCompleted) {
        context.push('/onboarding');
      } else {
        context.push('/trial');
      }
    } else {
      ref.read(paymentNotifierProvider.notifier).startSubscriptionPayment(
        plan:       widget.plan.id,
        coinsToUse: 0, // _coinsApplied
      );
    }
  }

  void _payYearly() {
    HapticFeedback.lightImpact();
    ref.read(paymentNotifierProvider.notifier).startSubscriptionPayment(
      plan:       'yearly',
      coinsToUse: 0, // _coinsApplied
    );
  }

  // Bottom CTA label based on plan & state
  String _bottomCtaLabel(bool onboardingOk) {
    if (_isActive) return 'You are on this plan';
    if (_isTrial) {
      return onboardingOk
          ? 'Start Free Trial · ₹1 '
          : 'Answer 10 questions & unlock free trial';
    }
    if (_isPremium) return 'Choose Monthly · ₹${widget.plan.priceMonthly}/mo';
    return 'Get ${widget.plan.name} · ₹${widget.plan.priceMonthly}/mo';
  }

  @override
  Widget build(BuildContext context) {
    final paymentState   = ref.watch(paymentNotifierProvider);
    final accent         = widget.plan.accentColor;
    final onboardingOk   = ref.watch(appAccessProvider).onboardingCompleted;

    final upgradeAsync = _shouldFetchProration
        ? ref.watch(upgradeCalculationProvider(widget.plan.id))
        : null;
    final UpgradeCalculation? calc = upgradeAsync?.valueOrNull;

    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      if (next.successMessage != null &&
          prev?.successMessage != next.successMessage) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:        Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Scrollable content with sliver app bar ───────────────────
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [

                    // ── Gradient sliver app bar ──────────────────────────────
                    _DetailAppBar(plan: widget.plan),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Active banner
                            if (_isActive) ...[
                              _ActiveBanner(),
                              const SizedBox(height: 16),
                            ],

                            // ══════════════════════════════════════════════════
                            // FREE TRIAL
                            // ══════════════════════════════════════════════════
                            if (_isTrial) ...[
                              _TrialPricingCard(),
                              // bottom CTA handles action — no inline button
                            ],

                            // ══════════════════════════════════════════════════
                            // PREMIUM — monthly (no inline btn) + yearly (inline btn)
                            // ══════════════════════════════════════════════════
                            if (_isPremium) ...[
                              _MonthlyPricingCard(
                                plan:            widget.plan,
                                calc:            calc,
                                isActive:        _isActive,
                                showInlineButton: false, // bottom CTA handles this
                                isLoading:       paymentState.isLoading,
                                onTap:           _payMonthly,
                              ),
                              const SizedBox(height: 12),
                              if (widget.plan.priceYearly != null)
                                _YearlyPricingCard(
                                  discountedYearly: widget.plan.priceYearly!,
                                  originalYearly:   widget.plan.originalYearly!,
                                  isLoading:        paymentState.isLoading,
                                  onTap:            _payYearly,
                                  showInlineButton: true, // ← inline button for yearly only
                                ),
                            ],

                            // ══════════════════════════════════════════════════
                            // STANDARD — bottom CTA only
                            // ══════════════════════════════════════════════════
                            if (_isStandard) ...[
                              _MonthlyPricingCard(
                                plan:            widget.plan,
                                calc:            calc,
                                isActive:        _isActive,
                                showInlineButton: false,
                                isLoading:       paymentState.isLoading,
                                onTap:           _payMonthly,
                              ),
                            ],

                            // Proration notice
                            if (_shouldFetchProration && calc != null) ...[
                              const SizedBox(height: 16),
                              _ProrationNotice(calc: calc),
                            ],

                            // Error banner
                            if (paymentState.error != null) ...[
                              const SizedBox(height: 16),
                              _ErrorBanner(
                                message:   paymentState.error!,
                                onDismiss: () => ref
                                    .read(paymentNotifierProvider.notifier)
                                    .clearState(),
                              ),
                            ],

                            // Onboarding hint for trial
                            if (_isTrial && !onboardingOk && !_isActive) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Takes about 2 minutes. Unlocks your free trial instantly.',
                                style: AppTextStyles.featureText.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Fixed bottom CTA (not shown for premium — yearly has inline) ──
              // For premium we still show bottom CTA for monthly selection
              _BottomCTA(
                label:     _bottomCtaLabel(onboardingOk),
                accent:    accent,
                gradient:  _isActive ? null : widget.plan.cardGradient,
                isLoading: paymentState.isLoading,
                disabled:  _isActive,
                onTap:     _payMonthly,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIVER APP BAR WITH GRADIENT ACCENT — restored from original design
// ─────────────────────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  final PlanData plan;
  const _DetailAppBar({required this.plan});

  static const double _expandedHeight = 158.0;

  @override
  Widget build(BuildContext context) {
    final topPad          = MediaQuery.of(context).padding.top;
    final collapsedHeight = kToolbarHeight + topPad;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _AppBarDelegate(
        plan:            plan,
        accent:          plan.accentColor,
        topPad:          topPad,
        expandedHeight:  _expandedHeight + topPad,
        collapsedHeight: collapsedHeight,
        isTrial:         plan.tier == PlanTier.trial,
      ),
    );
  }
}

class _AppBarDelegate extends SliverPersistentHeaderDelegate {
  final PlanData plan;
  final Color    accent;
  final double   topPad;
  final double   expandedHeight;
  final double   collapsedHeight;
  final bool     isTrial;

  const _AppBarDelegate({
    required this.plan,
    required this.accent,
    required this.topPad,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.isTrial,
  });

  @override double get minExtent => collapsedHeight;
  @override double get maxExtent => expandedHeight;
  @override bool shouldRebuild(_AppBarDelegate old) =>
      old.plan != plan || old.accent != accent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (expandedHeight - collapsedHeight))
        .clamp(0.0, 1.0);
    final expandedOpacity  = (1.0 - t * 2.5).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.5) * 2.5).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [

          // Gradient background fades out as it collapses
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(
                      (isTrial ? 0.06 : 0.13) * (1 - t)),
                  AppColors.bg,
                ],
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
              ),
            ),
          ),

          // Solid bg overlay as it collapses
          Opacity(
              opacity: t,
              child: Container(color: AppColors.bg)),

          // Expanded content: badge + name + tagline
          Positioned(
            left: 20, right: 20, bottom: 16,
            child: Opacity(
              opacity: expandedOpacity,
              child: Transform.translate(
                offset: Offset(0, shrinkOffset * 0.22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.badge.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(plan.badge,
                            style: AppTextStyles.badgeText.copyWith(
                                color: accent, fontSize: 9)),
                      ),
                    Text(plan.name,
                        style: AppTextStyles.planTitle.copyWith(
                            fontSize: 26, letterSpacing: -0.6)),
                    const SizedBox(height: 2),
                    Text(plan.tagline,
                        style: AppTextStyles.featureText
                            .copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Collapsed content: plan name centred + back button
          Positioned(
            left: 0, right: 0,
            top: topPad, height: kToolbarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back button
                Positioned(
                  left: 4,
                  child: Opacity(
                    opacity: collapsedOpacity,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Title
                Opacity(
                  opacity: collapsedOpacity,
                  child: Text(plan.name,
                      style: AppTextStyles.planTitle.copyWith(
                          fontSize: 17, letterSpacing: -0.4)),
                ),
              ],
            ),
          ),

          // Expanded back button (always visible)
          Positioned(
            left: 4,
            top: topPad,
            height: kToolbarHeight,
            child: Opacity(
              opacity: expandedOpacity,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Bottom divider line appears when collapsed
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Opacity(
              opacity: t,
              child: Container(height: 1, color: AppColors.divider),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.activeGreen.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.activeGreen.withOpacity(0.22)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_rounded,
            size: 14, color: AppColors.activeGreen),
        const SizedBox(width: 8),
        Text('You are currently on this plan',
            style: AppTextStyles.featureText.copyWith(
              fontSize: 12,
              color: AppColors.activeGreen,
              fontWeight: FontWeight.w600,
            )),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIAL PRICING CARD — no inline button (bottom CTA handles it)
// ─────────────────────────────────────────────────────────────────────────────

class _TrialPricingCard extends StatelessWidget {
  const _TrialPricingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹1',
                  style: AppTextStyles.priceMain
                      .copyWith(fontSize: 44, color: AppColors.teal)),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('For Explore',
                    style: AppTextStyles.featureText
                        .copyWith(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('30-day full access  •  New users only',
              style: AppTextStyles.featureText.copyWith(fontSize: 12)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Explore the app in ₹1',
                style: AppTextStyles.featureText
                    .copyWith(fontSize: 11.5, color: AppColors.teal)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MONTHLY PRICING CARD
// showInlineButton = false → bottom CTA handles action
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyPricingCard extends StatelessWidget {
  final PlanData            plan;
  final UpgradeCalculation? calc;
  final bool                isActive;
  final bool                isLoading;
  final bool                showInlineButton;
  final VoidCallback        onTap;

  const _MonthlyPricingCard({
    required this.plan,
    required this.calc,
    required this.isActive,
    required this.isLoading,
    required this.showInlineButton,
    required this.onTap,
  });

  bool get _hasProration  => calc != null && calc!.proratedCredit > 0;
  int  get _effectivePrice => calc?.priceAfterProration ?? plan.priceMonthly;

  @override
  Widget build(BuildContext context) {
    final accent = plan.accentColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.22), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MONTHLY',
              style: AppTextStyles.badgeText
                  .copyWith(color: accent, fontSize: 10)),
          const SizedBox(height: 10),

          // Price row — inline button only if showInlineButton is true
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$_effectivePrice',
                          style: AppTextStyles.priceMain.copyWith(
                              fontSize: 36, color: accent),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_hasProration)
                                Text('₹${plan.priceMonthly}',
                                    style: AppTextStyles.priceStrike
                                        .copyWith(fontSize: 13)),
                              Text(
                                _hasProration ? 'today only' : '/month',
                                style: AppTextStyles.featureText
                                    .copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_hasProration)
                      Text('then ₹${plan.priceMonthly}/mo',
                          style: AppTextStyles.featureText
                              .copyWith(fontSize: 11)),
                  ],
                ),
              ),

              // Inline button only when explicitly requested
              if (showInlineButton) ...[
                const SizedBox(width: 12),
                _CompactButton(
                  label:    isActive ? 'Current plan' : 'Choose Monthly',
                  gradient: isActive ? null : plan.cardGradient,
                  fill:     AppColors.divider,
                  text:     isActive ? AppColors.textMuted : Colors.white,
                  loading:  isLoading,
                  disabled: isActive,
                  onTap:    onTap,
                ),
              ],
            ],
          ),

          // Proration note
          if (_hasProration) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.activeGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${calc!.unusedDays} unused days → ₹${calc!.proratedCredit} credited',
                style: AppTextStyles.badgeText.copyWith(
                    color: AppColors.activeGreen, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// YEARLY PRICING CARD — always has inline button (showInlineButton=true)
// ─────────────────────────────────────────────────────────────────────────────

class _YearlyPricingCard extends StatelessWidget {
  final int          discountedYearly;
  final int          originalYearly;
  final bool         isLoading;
  final bool         showInlineButton;
  final VoidCallback onTap;

  const _YearlyPricingCard({
    required this.discountedYearly,
    required this.originalYearly,
    required this.isLoading,
    required this.onTap,
    this.showInlineButton = true,
  });

  int get _saving           => originalYearly - discountedYearly;
  int get _pctOff           => (_saving / originalYearly * 100).round();
  int get _effectiveMonthly => (discountedYearly / 12).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.gold.withOpacity(0.28), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + % off badge
          Row(
            children: [
              Text('YEARLY',
                  style: AppTextStyles.badgeText.copyWith(
                      color: AppColors.gold, fontSize: 10)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('$_pctOff% OFF',
                    style: AppTextStyles.badgeText.copyWith(
                        color: Colors.white, fontSize: 9)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Price row + inline button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$discountedYearly',
                          style: AppTextStyles.priceMain.copyWith(
                              fontSize: 36, color: AppColors.gold),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹$originalYearly',
                                  style: AppTextStyles.priceStrike
                                      .copyWith(fontSize: 13)),
                              Text('/year',
                                  style: AppTextStyles.featureText
                                      .copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '≈ ₹$_effectiveMonthly/month  •  saves ₹$_saving',
                      style: AppTextStyles.featureText.copyWith(
                          fontSize: 11.5,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Inline button — only on yearly card
              if (showInlineButton)
                _CompactButton(
                  label: 'Choose Yearly',
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.premiumGradStart,
                      AppColors.premiumGradEnd,
                    ],
                    begin: Alignment.centerLeft,
                    end:   Alignment.centerRight,
                  ),
                  fill:    AppColors.divider,
                  text:    Colors.white,
                  loading: isLoading,
                  disabled: false,
                  onTap:   onTap,
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Benefit note
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 Best value — pay once, use all year without renewals',
              style: AppTextStyles.featureText.copyWith(
                  fontSize: 11.5, color: AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT BUTTON — sits inline inside price row
// ─────────────────────────────────────────────────────────────────────────────

class _CompactButton extends StatelessWidget {
  final String    label;
  final Gradient? gradient;
  final Color     fill;
  final Color     text;
  final bool      loading;
  final bool      disabled;
  final VoidCallback onTap;

  const _CompactButton({
    required this.label,
    required this.gradient,
    required this.fill,
    required this.text,
    required this.loading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled || loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: (!disabled && gradient != null) ? gradient : null,
          color:    (disabled || gradient == null) ? fill : null,
          borderRadius: BorderRadius.circular(11),
          boxShadow: (!disabled && gradient != null)
              ? [BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: 8,
              offset: const Offset(0, 3))]
              : [],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.white),
        )
            : Text(label,
          style: AppTextStyles.ctaLabel.copyWith(
              color: text, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIXED BOTTOM CTA
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCTA extends StatelessWidget {
  final String    label;
  final Color     accent;
  final Gradient? gradient;
  final bool      isLoading;
  final bool      disabled;
  final VoidCallback onTap;

  const _BottomCTA({
    required this.label,
    required this.accent,
    required this.gradient,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: GestureDetector(
        onTap: disabled || isLoading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 52,
          decoration: BoxDecoration(
            gradient: (!disabled && gradient != null) ? gradient : null,
            color: (disabled || gradient == null)
                ? AppColors.divider
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: (!disabled && gradient != null)
                ? [BoxShadow(
                color: accent.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 5))]
                : [],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          )
              : Text(
            label,
            style: AppTextStyles.ctaLabel.copyWith(
              color: disabled ? AppColors.textMuted : Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRORATION NOTICE
// ─────────────────────────────────────────────────────────────────────────────

class _ProrationNotice extends StatelessWidget {
  final UpgradeCalculation calc;
  const _ProrationNotice({required this.calc});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.activeGreen.withOpacity(0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.activeGreen.withOpacity(0.20)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.calendar_today_rounded,
              size: 13, color: AppColors.activeGreen),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${calc.unusedDays} days remaining on your current plan — ₹${calc.proratedCredit} will be credited towards this upgrade.',
            style: AppTextStyles.featureText.copyWith(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                    color: AppColors.textPrimary, fontSize: 12))),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close_rounded,
              size: 14, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN BLOCK — hidden, preserved for later
// ─────────────────────────────────────────────────────────────────────────────
// To re-enable:
// 1. Uncomment _coinsApplied, _coinsEnabled in state
// 2. Pass coinsToUse: _coinsApplied in _payMonthly / _payYearly
// 3. Render _CoinBlock widget in the build column
// 4. Show _finalPrice(calc) instead of raw plan price
//
// class _CoinBlock extends StatelessWidget { ... }  ← full logic in original file