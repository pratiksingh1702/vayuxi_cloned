import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import '../models/payment_model.dart';
import '../providers/razorpay_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {
  static const bg            = Color(0xFFF5F6FA);
  static const surface       = Color(0xFFEEF0F7);
  static const card          = Color(0xFFFFFFFF);
  static const cardAlt       = Color(0xFFF0F2FA);
  static const divider       = Color(0xFFE2E5F0);
  static const textPrimary   = Color(0xFF0E0F1A);
  static const textSecondary = Color(0xFF5A5F7A);
  static const textMuted     = Color(0xFFA0A5BE);
  static const gold          = Color(0xFFD4920A);
  static const goldDim       = Color(0x1AD4920A);
  static const goldGlow      = Color(0x33D4920A);
  static const teal          = Color(0xFF0AADA2);
  static const tealDim       = Color(0x1A0AADA2);
  static const violet        = Color(0xFF5A4FE0);
  static const violetDim     = Color(0x1A5A4FE0);
  static const rose          = Color(0xFFE03355);
  static const coin          = Color(0xFFD4920A);
  static const coinDim       = Color(0x20D4920A);
  static const coinGlow      = Color(0x40D4920A);
  static const premiumGradStart  = Color(0xFFD4920A);
  static const premiumGradEnd    = Color(0xFFE8610A);
  static const standardGradStart = Color(0xFF0AADA2);
  static const standardGradEnd   = Color(0xFF5A4FE0);
  static const trialGradStart    = Color(0xFFA0A5BE);
  static const trialGradEnd      = Color(0xFFCBCEDE);
}

abstract class AppTextStyles {
  static TextStyle get screenTitle => const TextStyle(
    fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static TextStyle get sectionLabel => const TextStyle(
    fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textMuted, letterSpacing: 1.4,
  );
  static TextStyle get planTitle => const TextStyle(
    fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.2,
  );
  static TextStyle get priceMain => const TextStyle(
    fontFamily: 'Outfit', fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -1.2,
  );
  static TextStyle get priceStrike => const TextStyle(
    fontFamily: 'DM Sans', fontSize: 15, fontWeight: FontWeight.w400,
    color: AppColors.textMuted, decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.textMuted,
  );
  static TextStyle get featureText => const TextStyle(
    fontFamily: 'DM Sans', fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );
  static TextStyle get ctaLabel => const TextStyle(
    fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
  static TextStyle get badgeText => const TextStyle(
    fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
  static TextStyle get coinValue => const TextStyle(
    fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800,
    color: AppColors.coin, letterSpacing: -0.5,
  );
  static TextStyle get deltaLabel => const TextStyle(
    fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textMuted, letterSpacing: 0.2,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN MATH — single source of truth
// 1 coin = ₹0.50 = 50 paise
// ─────────────────────────────────────────────────────────────────────────────

abstract class CoinMath {
  static const int paisePerCoin = 100;

  // 🔒 HARD CAP
  static const int maxCoinsPerPlan = 100;

  static int maxUsable(int userCoins, int planPriceRupees) {
    if (userCoins <= 0 || planPriceRupees <= 0) return 0;

    final maxByPrice = (planPriceRupees * 100) ~/ paisePerCoin;

    return math.min(
      userCoins,
      math.min(maxByPrice, maxCoinsPerPlan),
    );
  }

  static double discountRs(int coins) =>
      (coins * paisePerCoin) / 100.0;

  static double finalPriceRs(int planPriceRupees, int coinsApplied) =>
      (planPriceRupees - discountRs(coinsApplied))
          .clamp(0.0, double.infinity);
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum PlanWeight { hero, secondary, minimal }

class PlanData {
  final String id;
  final String name;
  final String tagline;
  final int priceMonthly;
  final List<String> primaryFeatures;
  final List<String> secondaryFeatures;
  final Color accentColor;
  final Gradient cardGradient;
  final bool isHighlighted;
  final String badge;
  final PlanWeight weight;
  final String deltaText;
  final String socialProof;

  const PlanData({
    required this.id,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.primaryFeatures,
    this.secondaryFeatures = const [],
    required this.accentColor,
    required this.cardGradient,
    this.isHighlighted = false,
    this.badge = '',
    required this.weight,
    this.deltaText = '',
    this.socialProof = '',
  });
}

// Plan order: Premium → Standard → Trial (high-anchor first)
// Replace kPlans in subsciption_screen.dart

final List<PlanData> kPlans = [
  PlanData(
    id: 'yearly',
    name: 'Yearly',
    tagline: 'Best value — save ₹6,589 vs monthly.',
    priceMonthly: 14999, // billed once per year
    primaryFeatures: [
      'Unlimited AI uploads all year',
      'Everything in Premium included',
      'Lock in price — no renewal hikes',
    ],
    secondaryFeatures: [
      'Dedicated account manager',
      'Early access to new features',
      'Custom onboarding session',
    ],
    accentColor: AppColors.teal,
    cardGradient: const LinearGradient(
      colors: [Color(0xFF0AADA2), Color(0xFF0A8FAD)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    badge: 'BEST VALUE',
    isHighlighted: false,
    weight: PlanWeight.secondary,
    deltaText: '₹1,250/mo effective — vs ₹1,799/mo on monthly Premium',
    socialProof: 'Save ₹6,589 compared to 12 × Premium',
  ),
  PlanData(
    id: 'premium',
    name: 'Premium',
    tagline: 'Everything, unlimited — forever.',
    priceMonthly: 1799,
    primaryFeatures: [
      'Unlimited AI uploads, every month',
      'API access + white-label ready',
      '24 / 7 dedicated support',
    ],
    secondaryFeatures: [
      'Full analytics + custom reports',
      'Unlimited team members',
      'Priority processing queue',
    ],
    accentColor: AppColors.gold,
    cardGradient: const LinearGradient(
      colors: [AppColors.premiumGradStart, AppColors.premiumGradEnd],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    badge: 'MOST POPULAR',
    isHighlighted: true,
    weight: PlanWeight.hero,
    deltaText: 'Only ₹700 more than Standard — unlimited everything',
    socialProof: '68% of users choose Premium',
  ),

  // ── NEW: Yearly plan ────────────────────────────────────────────────────


  PlanData(
    id: 'standard',
    name: 'Standard',
    tagline: 'For teams that are growing.',
    priceMonthly: 999,
    primaryFeatures: [
      '50 AI uploads per month',
      'Advanced analytics dashboard',
      'Priority email & chat support',
    ],
    secondaryFeatures: [
      'Referral rewards program',
      'Export to PDF & Excel',
    ],
    accentColor: AppColors.violet,
    cardGradient: const LinearGradient(
      colors: [AppColors.standardGradStart, AppColors.standardGradEnd],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    badge: 'GOOD START',
    weight: PlanWeight.secondary,
    deltaText: 'Upgrade to Premium for only ₹700 more — remove every limit',
  ),

  PlanData(
    id: 'trial',
    name: 'Try first',
    tagline: '30 days to explore. Fully refundable.',
    priceMonthly: 1,
    primaryFeatures: [
      '2 AI uploads to explore',
      'Core reports & insights',
      'Full 30-day access',
    ],
    accentColor: AppColors.textMuted,
    cardGradient: const LinearGradient(
      colors: [AppColors.trialGradStart, AppColors.trialGradEnd],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    badge: '₹1 REFUNDABLE',
    weight: PlanWeight.minimal,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Per-plan: coins currently applied (0 = none)
  final Map<String, int> _coinsApplied = {
    'trial': 0, 'standard': 0, 'premium': 0,
  };

  // Per-plan: whether user has switched coins ON for that plan
  final Map<String, bool> _coinsEnabled = {
    'trial': false, 'standard': false, 'premium': false,
  };

  int _userCoins = 0; // overwritten by coinBalanceProvider

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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

  /// Toggle coins on/off for a plan.
  /// OFF → 0 coins. ON → auto-apply maximum.
  void _toggleCoins(String planId) {
    final plan = kPlans.firstWhere((p) => p.id == planId);
    final isOn = _coinsEnabled[planId] ?? false;
    setState(() {
      if (isOn) {
        _coinsEnabled[planId] = false;
        _coinsApplied[planId] = 0;
      } else {
        _coinsEnabled[planId] = true;
        _coinsApplied[planId] =
            CoinMath.maxUsable(_userCoins, plan.priceMonthly);
      }
    });
    HapticFeedback.selectionClick();
  }

  /// Fine-tune coin amount (from the adjust sheet).
  void _setCoins(String planId, int value) {
    setState(() {
      _coinsApplied[planId] = value;
      _coinsEnabled[planId] = value > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final coinAsync         = ref.watch(coinBalanceProvider);
    final paymentState      = ref.watch(paymentNotifierProvider);

    coinAsync.whenData((c) {
      if (_userCoins != c.balance) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _userCoins = c.balance);
        });
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: subscriptionAsync.when(
            loading: _buildLoading,
            error:   (e, _) => _buildError(e),
            data:    (sub)  => _buildContent(sub, paymentState),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(
      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2));

  Widget _buildError(Object e) => Center(
      child: Text(extractBackendError(e), style: const TextStyle(color: AppColors.rose)));

  // ── Main scroll body ──────────────────────────────────────────────────────
  Widget _buildContent(Subscription sub, PaymentState paymentState) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildAppBar(sub),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildStatusHero(sub),
                const SizedBox(height: 14),

                // ── COIN WALLET — always visible (even when 0 coins) ──────────
                _buildCoinWallet(),
                const SizedBox(height: 22),

                _buildSectionHeader(sub),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),

        // ── Plan cards ───────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                if (i >= kPlans.length) return null;
                final plan = kPlans[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan:          plan,
                    subscription:  sub,
                    userCoins:     _userCoins,
                    coinsApplied:  _coinsApplied[plan.id] ?? 0,
                    coinsEnabled:  _coinsEnabled[plan.id] ?? false,
                    onToggleCoins: () => _toggleCoins(plan.id),
                    onAdjustCoins: (v) => _setCoins(plan.id, v),
                    isLoading:     paymentState.isLoading,
                    onTap: paymentState.isLoading
                        ? null
                        : () => _handlePlanTap(plan, sub),
                  ),
                );
              },
              childCount: kPlans.length,
            ),
          ),
        ),

        // ── Footer ───────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 4),
                _buildSocialProofBanner(),
                const SizedBox(height: 14),
                _buildTrustRow(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),

        if (paymentState.error != null || paymentState.successMessage != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(
                child: _buildStatusBanner(paymentState)),
          ),

        if (paymentState.isLoading)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                            color: AppColors.gold, strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Text('Processing…',
                        style: AppTextStyles.featureText
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────
  SliverAppBar _buildAppBar(Subscription sub) {
    return SliverAppBar(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppColors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Plans & Billing', style: AppTextStyles.screenTitle),
      centerTitle: true,
      actions: [
        if (sub.hasSubscription && !sub.isTrial)
          TextButton(
            onPressed: _showCancelDialog,
            child: Text('Manage',
                style: AppTextStyles.featureText
                    .copyWith(color: AppColors.textMuted)),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  // ── Status Hero ───────────────────────────────────────────────────────────
  Widget _buildStatusHero(Subscription sub) {
    if (!sub.hasSubscription) return const _NoSubHero();

    final planColor = sub.isPremium
        ? AppColors.gold
        : sub.isTrial
        ? AppColors.textMuted
        : AppColors.teal;

    final uploadsText = sub.hasUnlimitedUploads
        ? 'Unlimited uploads active'
        : '${sub.aiUploadsRemaining} of ${sub.aiUploadsLimit} uploads remaining';

    final uploadProgress = sub.hasUnlimitedUploads
        ? 1.0
        : ((sub.aiUploadsUsed ?? 0) /
        (sub.aiUploadsLimit ?? 1).clamp(1, 999999))
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: planColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PlanBadge(
                  label: sub.plan?.toUpperCase() ?? '', color: planColor),
              const Spacer(),
              if (sub.daysRemaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (sub.daysRemaining! < 7
                        ? AppColors.rose
                        : AppColors.teal)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${sub.daysRemaining}d remaining',
                    style: AppTextStyles.badgeText.copyWith(
                      color: sub.daysRemaining! < 7
                          ? AppColors.rose
                          : AppColors.teal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(uploadsText,
              style: AppTextStyles.featureText
                  .copyWith(color: AppColors.textPrimary, fontSize: 13)),
          if (!sub.hasUnlimitedUploads) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: uploadProgress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  uploadProgress > 0.8 ? AppColors.rose : planColor,
                ),
              ),
            ),
            if (uploadProgress > 0.8) ...[
              const SizedBox(height: 6),
              Text('Running low — consider upgrading.',
                  style: AppTextStyles.badgeText
                      .copyWith(color: AppColors.rose, letterSpacing: 0)),
            ],
          ],
          if (!sub.isPremium && sub.hasSubscription) ...[
            const SizedBox(height: 12),
            _UpgradeNudgeBanner(currentPlan: sub.plan ?? ''),
          ],
        ],
      ),
    );
  }

  // ── COIN WALLET ───────────────────────────────────────────────────────────
  // Always rendered — zero coins shows "earn" state, not nothing.
  Widget _buildCoinWallet() {
    final hasCoins = _userCoins > 0;
    final totalPossibleDiscount = CoinMath.discountRs(_userCoins);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCoins
              ? AppColors.coin.withOpacity(0.25)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Coin icon — always shown
          _CoinIcon(size: 44),
          const SizedBox(width: 14),

          // Balance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Vayuuxi Coins',
                        style: AppTextStyles.sectionLabel
                            .copyWith(letterSpacing: 0.8)),
                    const SizedBox(width: 5),
                    const Icon(Icons.info_outline_rounded,
                        size: 12, color: AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 3),
                // Coin count — prominent even when 0
                Text(
                  hasCoins ? '$_userCoins coins' : '0 coins',
                  style: AppTextStyles.coinValue.copyWith(
                    color: hasCoins ? AppColors.coin : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hasCoins
                      ? '≈ ₹${totalPossibleDiscount.toStringAsFixed(0)} off any paid plan'
                      : 'Refer friends to earn coins',
                  style: AppTextStyles.featureText.copyWith(
                    fontSize: 11,
                    color: hasCoins
                        ? AppColors.coin.withOpacity(0.72)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Earn more — always shown
          GestureDetector(
            onTap: _showReferralSheet,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coinDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.coin.withOpacity(0.22)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_add_rounded,
                      size: 18, color: AppColors.coin),
                  const SizedBox(height: 2),
                  Text('Earn more',
                      style: AppTextStyles.badgeText
                          .copyWith(color: AppColors.coin, fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(Subscription sub) {
    String title = 'Choose your plan';
    String subtitle = _userCoins > 0
        ? 'Apply your coins on any plan below to reduce the price'
        : 'Earn coins by referring friends — save on any plan';

    if (!sub.hasSubscription) {
      title = 'Start with Premium';
      subtitle = 'Most teams see results within their first week';
    } else if (sub.isTrial) {
      title = 'Ready to go further?';
      subtitle = 'Your trial gave you a taste — here\'s the full picture';
    } else if (sub.plan == 'standard') {
      title = 'Remove the limits';
      subtitle = 'Only ₹700 more separates you from unlimited everything';
    } else if (sub.isPremium) {
      title = 'You\'re on Premium ✦';
      subtitle = 'All features active — renews automatically';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.planTitle.copyWith(fontSize: 19)),
        const SizedBox(height: 3),
        Text(subtitle,
            style: AppTextStyles.featureText.copyWith(fontSize: 12)),
      ],
    );
  }

  // ── Social proof banner ───────────────────────────────────────────────────
  Widget _buildSocialProofBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline_rounded,
              size: 13, color: AppColors.gold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '78% of users choose Premium — most upgrade within 14 days.',
              style: AppTextStyles.featureText.copyWith(
                  fontSize: 11, color: AppColors.gold.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Trust row ─────────────────────────────────────────────────────────────
  Widget _buildTrustRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TrustItem(icon: Icons.lock_rounded, label: 'Secure payment'),
        const SizedBox(width: 20),
        _TrustItem(icon: Icons.cancel_outlined, label: 'Cancel anytime'),
        const SizedBox(width: 20),
        _TrustItem(icon: Icons.support_agent_rounded, label: '24h support'),
      ],
    );
  }

  // ── Status banner ─────────────────────────────────────────────────────────
  Widget _buildStatusBanner(PaymentState state) {
    final isError = state.error != null;
    final msg = state.error ?? state.successMessage ?? '';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.rose.withOpacity(0.1)
            : AppColors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? AppColors.rose.withOpacity(0.3)
              : AppColors.teal.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.rose : AppColors.teal,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: AppTextStyles.featureText
                    .copyWith(color: AppColors.textPrimary)),
          ),
          if (isError)
            GestureDetector(
              onTap: () =>
                  ref.read(paymentNotifierProvider.notifier).clearState(),
              child: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _handlePlanTap(PlanData plan, Subscription sub) {
    HapticFeedback.lightImpact();
    if (plan.id == 'trial') {
      // Trial requires a referral code — send user to TrialScreen where
      // they enter the code, create the order, and complete the ₹1 payment.
      context.push('/trial');
    } else {
      ref.read(paymentNotifierProvider.notifier).startSubscriptionPayment(
        plan:       plan.id,
        coinsToUse: _coinsApplied[plan.id] ?? 0,
      );
    }
  }
  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel subscription?', style: AppTextStyles.planTitle),
              const SizedBox(height: 10),
              Text(
                'You\'ll keep full access until the end of your billing period.',
                style: AppTextStyles.featureText,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _GhostButton(
                      label: 'Keep plan',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DangerButton(
                      label: 'Yes, cancel',
                      onTap: () {
                        Navigator.pop(context);
                        ref
                            .read(paymentNotifierProvider.notifier)
                            .cancelSubscription();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferralSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // ✅ Use builder that receives a fresh BuildContext — wrap with Consumer
      builder: (_) => _ReferralSheet(),
    );
  }
}
class _ReferralSheet extends ConsumerWidget {
  const _ReferralSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ ref.watch here — rebuilds automatically when data arrives
    final codeAsync = ref.watch(referralCodeProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _CoinIcon(size: 48),
          const SizedBox(height: 12),
          Text('Earn Vayuuxi Coins', style: AppTextStyles.planTitle),
          const SizedBox(height: 6),
          Text(
            'Invite friends and earn coins for every signup.\n100 coins = ₹50 off any subscription.',
            textAlign: TextAlign.center,
            style: AppTextStyles.featureText,
          ),
          const SizedBox(height: 20),
          codeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: CircularProgressIndicator(
                color: AppColors.coin, strokeWidth: 2,
              ),
            ),
            error: (_, __) => Text(
              'Could not load referral code. Try again.',
              style: AppTextStyles.featureText
                  .copyWith(color: AppColors.rose),
              textAlign: TextAlign.center,
            ),
            data: (code) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14,
              ),
              decoration: BoxDecoration(
                color: AppColors.coinDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.coin.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code.referralCode,
                    style: AppTextStyles.coinValue.copyWith(fontSize: 20),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: code.referralCode),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied!'),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.coin,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final PlanData plan;
  final Subscription subscription;
  final int userCoins;
  final int coinsApplied;
  final bool coinsEnabled;
  final VoidCallback onToggleCoins;
  final ValueChanged<int> onAdjustCoins;
  final bool isLoading;
  final VoidCallback? onTap;

  const _PlanCard({
    required this.plan,
    required this.subscription,
    required this.userCoins,
    required this.coinsApplied,
    required this.coinsEnabled,
    required this.onToggleCoins,
    required this.onAdjustCoins,
    required this.isLoading,
    this.onTap,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {

  bool _secondaryExpanded = false;
  late AnimationController _expandCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _expandAnim =
        CurvedAnimation(parent: _expandCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  bool get _isCurrent =>
      widget.subscription.plan == widget.plan.id &&
          widget.subscription.hasSubscription;

  bool get _isTrialPlan => widget.plan.id == 'trial';

  bool get _isDisabled =>
      _isCurrent ||
          (_isTrialPlan && widget.subscription.hasSubscription) ||
          widget.isLoading;

  bool get _hasSavings =>
      widget.coinsEnabled && widget.coinsApplied > 0 && !_isTrialPlan;

  int    get _originalPrice => widget.plan.priceMonthly;
  double get _finalPrice =>
      CoinMath.finalPriceRs(_originalPrice, widget.coinsApplied);
  double get _savingRs => CoinMath.discountRs(widget.coinsApplied);
  int    get _maxCoins =>
      CoinMath.maxUsable(widget.userCoins, _originalPrice);

  String get _ctaLabel {
    if (_isCurrent) return 'Your current plan ✓';
    switch (widget.plan.id) {
      case 'premium':
        return _hasSavings
            ? 'Unlock Premium · ₹${_finalPrice.toStringAsFixed(0)}/mo'
            : 'Unlock Premium · ₹$_originalPrice/mo';
      case 'yearly':
        return _hasSavings
            ? 'Get Yearly · ₹${_finalPrice.toStringAsFixed(0)}/yr'
            : 'Get Yearly · ₹$_originalPrice/yr';
      case 'standard':
        return _hasSavings
            ? 'Get Standard · ₹${_finalPrice.toStringAsFixed(0)}/mo'
            : 'Get Standard · ₹$_originalPrice/mo';
      case 'trial':
        return 'Start exploring · ₹1 refundable';
      default:
        return 'Get started';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent      = widget.plan.accentColor;
    final isHighlight = widget.plan.isHighlighted;

    return Opacity(
      opacity: _isTrialPlan ? 0.78 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isCurrent
                ? accent.withOpacity(0.55)
                : isHighlight
                ? accent.withOpacity(0.32)
                : AppColors.divider,
            width: isHighlight ? 1.5 : 1.0,
          ),
          boxShadow: isHighlight && !_isCurrent
              ? [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ]
              : [],
        ),
        child: Column(
          children: [
            // Gradient top strip
            _GradientStrip(
              gradient: _isTrialPlan
                  ? LinearGradient(colors: [
                AppColors.trialGradStart.withOpacity(0.5),
                AppColors.trialGradEnd.withOpacity(0.3),
              ])
                  : widget.plan.cardGradient,
              height: _isTrialPlan ? 3 : 5,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(accent),
                  const SizedBox(height: 14),

                  // ── Price block (before & after coins) ─────────────────────
                  _buildPriceBlock(accent),
                  const SizedBox(height: 12),

                  // ── Coin section — shown for all non-trial plans ────────────
                  if (!_isTrialPlan) _buildCoinSection(accent),

                  // Features
                  ...widget.plan.primaryFeatures
                      .map((f) => _FeatureRow(text: f, color: accent)),

                  if (widget.plan.secondaryFeatures.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildSecondaryExpand(accent),
                  ],

                  const SizedBox(height: 16),

                  // CTA
                  _buildCtaButton(accent),

                  // Social proof (Premium)
                  if (widget.plan.socialProof.isNotEmpty && !_isCurrent) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        widget.plan.socialProof,
                        style: AppTextStyles.badgeText.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 0.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // Delta framing (Standard)
                  if (widget.plan.deltaText.isNotEmpty && !_isCurrent) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.plan.deltaText,
                      style: AppTextStyles.deltaLabel.copyWith(
                        color: widget.plan.id == 'standard'
                            ? AppColors.gold.withOpacity(0.65)
                            : AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.plan.name, style: AppTextStyles.planTitle),
                  const SizedBox(width: 8),
                  if (_isCurrent)
                    _PlanBadge(label: 'CURRENT', color: accent)
                  else if (widget.plan.badge.isNotEmpty)
                    _PlanBadge(label: widget.plan.badge, color: accent),
                ],
              ),
              const SizedBox(height: 3),
              Text(widget.plan.tagline,
                  style: AppTextStyles.featureText.copyWith(fontSize: 11)),
            ],
          ),
        ),
        if (!widget.plan.isHighlighted)
          GestureDetector(
            onTap: _toggleExpand,
            child: AnimatedRotation(
              turns: _secondaryExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }

  // ── Price block ───────────────────────────────────────────────────────────
  // Clearly shows BEFORE and AFTER price when coins are applied.
  //   No coins: ₹1499                  /month
  //   Coins on: ₹1339  ~~₹1499~~      /month
  Widget _buildPriceBlock(Color accent) {
    final isYearly = widget.plan.id == 'yearly';
    final periodLabel = _isTrialPlan
        ? null
        : isYearly
        ? '/year'
        : '/month';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Animated price area
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: _hasSavings
              ? Row(
            key: const ValueKey('discounted'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_finalPrice.toStringAsFixed(0)}',
                style: AppTextStyles.priceMain.copyWith(color: accent),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('₹$_originalPrice',
                    style: AppTextStyles.priceStrike),
              ),
            ],
          )
              : Row(
            key: const ValueKey('original'),
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _isTrialPlan ? '₹1' : '₹$_originalPrice',
                style: AppTextStyles.priceMain,
              ),
            ],
          ),
        ),
        const Spacer(),

        // Period label / badge
        if (_isTrialPlan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.tealDim,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('REFUNDABLE',
                style: AppTextStyles.badgeText.copyWith(color: AppColors.teal)),
          )
        else if (isYearly)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(periodLabel!,
                    style: AppTextStyles.featureText.copyWith(fontSize: 11)),
              ),
              // Effective monthly cost chip
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '≈ ₹1,250/mo',
                  style: AppTextStyles.badgeText.copyWith(color: accent),
                ),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(periodLabel!,
                style: AppTextStyles.featureText.copyWith(fontSize: 11)),
          ),
      ],
    );
  }

  // ── Coin section ──────────────────────────────────────────────────────────
  //
  // Three visual states:
  //
  // [A] userCoins = 0
  //     Greyed row: "No coins yet — earn some by referring friends"
  //
  // [B] userCoins > 0, coins OFF
  //     Yellow-border row: "320 coins available · save up to ₹160"
  //     + [Apply coins] button
  //
  // [C] userCoins > 0, coins ON
  //     Filled yellow row: "320 coins applied · saving ₹160"
  //     + inline before→after: "₹1499 → ₹1339/mo"
  //     + [Remove] button  +  "Adjust" link
  Widget _buildCoinSection(Color accent) {
    // ── State A: no coins ──────────────────────────────────────────────────
    if (widget.userCoins <= 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            _CoinIcon(size: 15),
            const SizedBox(width: 8),
            Text(
              'No coins yet — earn by referring friends',
              style: AppTextStyles.featureText
                  .copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // ── State B / C ────────────────────────────────────────────────────────
    final coinsOn = widget.coinsEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: coinsOn
                ? AppColors.coinDim
                : AppColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: coinsOn
                  ? AppColors.coin.withOpacity(0.32)
                  : AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: _CoinIcon(size: 18),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: coinsOn
                // ── Coins ON: show applied count + before→after ──────────
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.featureText
                            .copyWith(fontSize: 12),
                        children: [
                          TextSpan(
                            text: '${widget.coinsApplied} coins applied',
                            style: const TextStyle(
                              color: AppColors.coin,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text:
                            ' · saving ₹${_savingRs.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    // ── Before → After price line ─────────────────────
                    Row(
                      children: [
                        Text(
                          '₹$_originalPrice',
                          style: AppTextStyles.featureText.copyWith(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 11, color: AppColors.textMuted),
                        ),
                        Text(
                          '₹${_finalPrice.toStringAsFixed(0)}/mo',
                          style: AppTextStyles.featureText.copyWith(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                // ── Coins OFF: show available balance + potential saving ──
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.userCoins} coins available',
                      style: AppTextStyles.featureText.copyWith(
                        fontSize: 12,
                        color: AppColors.coin,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Apply to save up to ₹${CoinMath.discountRs(_maxCoins).toStringAsFixed(0)} on this plan',
                      style: AppTextStyles.featureText.copyWith(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // ── Toggle button ─────────────────────────────────────────────
              GestureDetector(
                onTap: widget.onToggleCoins,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: coinsOn
                        ? AppColors.bg
                        : AppColors.coin.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: coinsOn
                          ? AppColors.textMuted.withOpacity(0.3)
                          : AppColors.coin.withOpacity(0.45),
                    ),
                  ),
                  child: Text(
                    coinsOn ? 'Remove' : 'Apply',
                    style: AppTextStyles.badgeText.copyWith(
                      fontSize: 11,
                      color: coinsOn
                          ? AppColors.textMuted
                          : AppColors.coin,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Adjust link — only when coins are ON ──────────────────────────
        if (coinsOn) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showCoinAdjustSheet(accent),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Adjust (${widget.coinsApplied} of ${widget.userCoins} coins used)',
                    style: AppTextStyles.featureText.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.underline,
                      decorationColor:
                      AppColors.textMuted.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 12),
      ],
    );
  }

  // ── Coin adjust sheet ─────────────────────────────────────────────────────
  void _showCoinAdjustSheet(Color accent) {
    int tempCoins = widget.coinsApplied;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final saving  = CoinMath.discountRs(tempCoins);
          final finalP  = CoinMath.finalPriceRs(_originalPrice, tempCoins);

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),

                Text('Adjust coins — ${widget.plan.name}',
                    style: AppTextStyles.planTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  'You have ${widget.userCoins} coins · max usable: $_maxCoins',
                  style: AppTextStyles.featureText.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 20),

                // Live before/after card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.coinDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.coin.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Original',
                              style: AppTextStyles.featureText
                                  .copyWith(fontSize: 10)),
                          Text(
                            '₹$_originalPrice/mo',
                            style: AppTextStyles.priceMain.copyWith(
                              fontSize: 18,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: AppColors.textMuted),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('With $tempCoins coins',
                              style: AppTextStyles.featureText
                                  .copyWith(fontSize: 10)),
                          Text(
                            '₹${finalP.toStringAsFixed(0)}/mo',
                            style: AppTextStyles.priceMain.copyWith(
                              fontSize: 22,
                              color: accent,
                            ),
                          ),
                          if (saving > 0)
                            Text(
                              'You save ₹${saving.toStringAsFixed(0)}',
                              style: AppTextStyles.badgeText
                                  .copyWith(color: AppColors.coin),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.coin,
                    inactiveTrackColor: AppColors.coinDim,
                    thumbColor: AppColors.coin,
                    overlayColor: AppColors.coinGlow.withOpacity(0.15),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16),
                  ),
                  child: Slider(
                    value: tempCoins.toDouble(),
                    min: 0,
                    max: _maxCoins.toDouble(),
                    divisions: _maxCoins > 0 ? _maxCoins : 1,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setSheet(() => tempCoins = v.round());
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0',
                        style: AppTextStyles.featureText
                            .copyWith(fontSize: 10)),
                    Text('$_maxCoins max',
                        style: AppTextStyles.featureText
                            .copyWith(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 20),

                // Confirm
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GestureDetector(
                    onTap: () {
                      widget.onAdjustCoins(tempCoins);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: widget.plan.cardGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tempCoins > 0
                            ? 'Apply $tempCoins coins · ₹${CoinMath.finalPriceRs(_originalPrice, tempCoins).toStringAsFixed(0)}/mo'
                            : 'Remove coins',
                        style: AppTextStyles.ctaLabel
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Secondary features ────────────────────────────────────────────────────
  Widget _buildSecondaryExpand(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Column(
            children: widget.plan.secondaryFeatures
                .map((f) => _FeatureRow(
                text: f, color: accent.withOpacity(0.7)))
                .toList(),
          ),
        ),
        GestureDetector(
          onTap: _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _secondaryExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: accent.withOpacity(0.6),
                ),
                const SizedBox(width: 3),
                Text(
                  _secondaryExpanded
                      ? 'Show less'
                      : '+${widget.plan.secondaryFeatures.length} more features',
                  style: AppTextStyles.featureText.copyWith(
                    fontSize: 11,
                    color: accent.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── CTA button ────────────────────────────────────────────────────────────
  Widget _buildCtaButton(Color accent) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: _isCurrent
          ? Container(
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.22)),
        ),
        alignment: Alignment.center,
        child: Text(_ctaLabel,
            style: AppTextStyles.ctaLabel.copyWith(color: accent)),
      )
          : GestureDetector(
        onTap: _isDisabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: _isDisabled || _isTrialPlan
                ? null
                : widget.plan.cardGradient,
            color: _isDisabled
                ? AppColors.divider
                : _isTrialPlan
                ? AppColors.cardAlt
                : null,
            borderRadius: BorderRadius.circular(14),
            border: _isTrialPlan
                ? Border.all(color: AppColors.divider)
                : null,
            boxShadow: !_isDisabled && !_isTrialPlan
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
          child: Text(
            _ctaLabel,
            style: AppTextStyles.ctaLabel.copyWith(
              color: _isDisabled
                  ? AppColors.textMuted
                  : _isTrialPlan
                  ? AppColors.textSecondary
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleExpand() {
    setState(() => _secondaryExpanded = !_secondaryExpanded);
    _secondaryExpanded ? _expandCtrl.forward() : _expandCtrl.reverse();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _GradientStrip extends StatelessWidget {
  final Gradient gradient;
  final double height;
  const _GradientStrip({required this.gradient, this.height = 5});

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );
}

class _NoSubHero extends StatelessWidget {
  const _NoSubHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.goldDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No active plan',
                    style: TextStyle(
                      fontFamily: 'Outfit', fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                SizedBox(height: 2),
                Text(
                  'Most teams start with Premium and never look back.',
                  style: TextStyle(
                    fontFamily: 'DM Sans', fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeNudgeBanner extends StatelessWidget {
  final String currentPlan;
  const _UpgradeNudgeBanner({required this.currentPlan});

  @override
  Widget build(BuildContext context) {
    final isTrial = currentPlan == 'trial';
    final msg = isTrial
        ? 'Trial gives you 2 uploads. Standard gives 50. Premium removes the cap.'
        : 'You\'re at 50/mo. Premium is unlimited — for only ₹700 more.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gold.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Text('✦',
              style: TextStyle(color: AppColors.gold, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                style: AppTextStyles.featureText
                    .copyWith(fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PlanBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(label,
        style: AppTextStyles.badgeText.copyWith(color: color)),
  );
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final Color color;
  const _FeatureRow({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3.5),
    child: Row(
      children: [
        Icon(Icons.check_rounded, size: 13, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.featureText)),
      ],
    ),
  );
}

class _CoinIcon extends StatelessWidget {
  final double size;
  const _CoinIcon({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [
          Color(0xFFFFF0A0), AppColors.coin, Color(0xFFD4900A),
        ],
        stops: [0.0, 0.6, 1.0],
      ),
      boxShadow: [
        BoxShadow(
            color: AppColors.coinGlow,
            blurRadius: size * 0.4,
            spreadRadius: 1),
      ],
    ),
    child: Center(
      child: Text(
        '₹',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: size * 0.44,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF7A5500),
        ),
      ),
    ),
  );
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(label,
          style: AppTextStyles.featureText.copyWith(fontSize: 10)),
    ],
  );
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: AppTextStyles.ctaLabel
              .copyWith(color: AppColors.textSecondary, fontSize: 14)),
    ),
  );
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DangerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.rose.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rose.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: AppTextStyles.ctaLabel
              .copyWith(color: AppColors.rose, fontSize: 14)),
    ),
  );
}

extension StringCapitalize on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}