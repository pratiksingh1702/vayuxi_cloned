import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/features/pricing/Screens/plan_desc.dart';
import '../models/payment_model.dart';
import '../providers/razorpay_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {
  static const bg                = Color(0xFFF5F6FA);
  static const surface           = Color(0xFFEEF0F7);
  static const card              = Color(0xFFFFFFFF);
  static const cardAlt           = Color(0xFFF0F2FA);
  static const divider           = Color(0xFFE2E5F0);
  static const textPrimary       = Color(0xFF0E0F1A);
  static const textSecondary     = Color(0xFF5A5F7A);
  static const textMuted         = Color(0xFFA0A5BE);
  static const gold              = Color(0xFFD4920A);
  static const goldDim           = Color(0x1AD4920A);
  static const goldGlow          = Color(0x33D4920A);
  static const teal              = Color(0xFF0AADA2);
  static const tealDim           = Color(0x1A0AADA2);
  static const violet            = Color(0xFF5A4FE0);
  static const violetDim         = Color(0x1A5A4FE0);
  static const rose              = Color(0xFFE03355);
  static const roseDim           = Color(0x1AE03355);
  static const coin              = Color(0xFFD4920A);
  static const coinDim           = Color(0x20D4920A);
  static const coinGlow          = Color(0x40D4920A);
  static const premiumGradStart  = Color(0xFFD4920A);
  static const premiumGradEnd    = Color(0xFFE8610A);
  static const standardGradStart = Color(0xFF0AADA2);
  static const standardGradEnd   = Color(0xFF5A4FE0);
  static const trialGradStart    = Color(0xFFA0A5BE);
  static const trialGradEnd      = Color(0xFFCBCEDE);
  static const activeGreen       = Color(0xFF1DB954);
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
    fontFamily: 'DM Sans', fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.rose,
    decoration: TextDecoration.lineThrough,
    decorationColor: AppColors.rose,
    decorationThickness: 2.0,
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
  // kept for future coin UI
  static TextStyle get coinValue => const TextStyle(
    fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w800,
    color: AppColors.coin, letterSpacing: -0.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN MATH — logic preserved, not shown in UI
// ─────────────────────────────────────────────────────────────────────────────

abstract class CoinMath {
  static const int paisePerCoin    = 100;
  static const int maxCoinsPerPlan = 100;

  static int maxUsable(int userCoins, int planPriceRupees) {
    if (userCoins <= 0 || planPriceRupees <= 0) return 0;
    final maxByPrice = (planPriceRupees * 100) ~/ paisePerCoin;
    return math.min(userCoins, math.min(maxByPrice, maxCoinsPerPlan));
  }

  static double discountRs(int coins) => (coins * paisePerCoin) / 100.0;

  static double finalPriceRs(int planPriceRupees, int coinsApplied) =>
      (planPriceRupees - discountRs(coinsApplied)).clamp(0.0, double.infinity);
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum PlanTier { premium, standard, trial }

class PlanData {
  final String       id;
  final String       name;
  final String       tagline;
  final int          priceMonthly;
  final int?         priceYearly;
  final int?         originalYearly;
  final List<String> features;
  final Color        accentColor;
  final Gradient     cardGradient;
  final String       badge;
  final PlanTier     tier;

  const PlanData({
    required this.id,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    this.priceYearly,
    this.originalYearly,
    required this.features,
    required this.accentColor,
    required this.cardGradient,
    this.badge = '',
    required this.tier,
  });
}

final List<PlanData> kPlans = [
  PlanData(
    id: 'premium',
    name: 'Premium',
    tagline: 'Best for growing businesses',
    priceMonthly: 1799,
    priceYearly: 14999,
    originalYearly: 21588,
    features: [
      'Unlimited AI uploads',
      'Attendance & expense tracking',
      'Advanced analytics & predictions',
      'GST billing & custom reports',
      'Unlimited team & site management',
      'Inventory management',
      'Priority support',
    ],
    accentColor: AppColors.gold,
    cardGradient: const LinearGradient(
      colors: [AppColors.premiumGradStart, AppColors.premiumGradEnd],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    badge: 'MOST POPULAR',
    tier: PlanTier.premium,
  ),
  PlanData(
    id: 'standard',
    name: 'Standard',
    tagline: 'Best for small teams',
    priceMonthly: 999,
    features: [
      '1 AI upload / month',
      'Attendance & expense tracking',
      'Advanced analytics',
      'GST billing & reports',
      'Site & manpower management',
      'Unlimited manual entries',
    ],
    accentColor: AppColors.violet,
    cardGradient: const LinearGradient(
      colors: [AppColors.standardGradStart, AppColors.standardGradEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    badge: 'BEST VALUE', // 👈 add this
    tier: PlanTier.standard,
  ),
  PlanData(
    id: 'trial',
    name: 'Free Trial',
    tagline: 'Best for trying things out',
    priceMonthly: 1,
    features: [
      'Limited AI uploads',
      'Attendance & expense tracking',
      'Basic reports & invoices',
      'Full 30-day access',
    ],
    accentColor: AppColors.teal,
    cardGradient: const LinearGradient(
      colors: [AppColors.trialGradStart, AppColors.trialGradEnd],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    badge: '₹1 ',
    tier: PlanTier.trial,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE ENTRY MODEL
// Same title across all plans → consistent row positions.
// Only the value and isIncluded change per plan.
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureEntry {
  final String title;
  final String value;
  final bool   isIncluded;

  const _FeatureEntry({
    required this.title,
    required this.value,
    this.isIncluded = true,
  });
}

// IMPORTANT: Keep same index = same feature category across all three lists.
final List<_FeatureEntry> kTrialFeatures = [
  _FeatureEntry(title: 'AI Uploads',             value: 'Limited'),
  _FeatureEntry(title: 'Attendance & Expense',   value: 'Included'),
  _FeatureEntry(title: 'Reports & Invoices',     value: 'Basic'),
  _FeatureEntry(title: 'GST Billing',            value: 'Not included', isIncluded: false),
  _FeatureEntry(title: 'Site & Team Mgmt',       value: 'Not included', isIncluded: false),
  _FeatureEntry(title: 'Analytics',              value: 'Not included', isIncluded: false),
  _FeatureEntry(title: 'Inventory',              value: 'Not included', isIncluded: false),
  _FeatureEntry(title: 'Support',                value: 'Email only'),
  _FeatureEntry(title: 'Access',                 value: '30 days trial'),
];

final List<_FeatureEntry> kStandardFeatures = [
  _FeatureEntry(title: 'AI Uploads',             value: '1 per month'),
  _FeatureEntry(title: 'Attendance & Expense',   value: 'Included'),
  _FeatureEntry(title: 'Reports & Invoices',     value: 'Advanced'),
  _FeatureEntry(title: 'GST Billing',            value: 'Included'),
  _FeatureEntry(title: 'Site & Team Mgmt',       value: 'Included'),
  _FeatureEntry(title: 'Analytics',              value: 'Advanced'),
  _FeatureEntry(title: 'Inventory',              value: 'Not included', isIncluded: false),
  _FeatureEntry(title: 'Support',                value: 'Priority chat & email'),
  _FeatureEntry(title: 'Access',                 value: 'Monthly subscription'),
];

final List<_FeatureEntry> kPremiumFeatures = [
  _FeatureEntry(title: 'AI Uploads',             value: 'Unlimited'),
  _FeatureEntry(title: 'Attendance & Expense',   value: 'Included'),
  _FeatureEntry(title: 'Reports & Invoices',     value: 'Full + custom'),
  _FeatureEntry(title: 'GST Billing',            value: 'Included'),
  _FeatureEntry(title: 'Site & Team Mgmt',       value: 'Unlimited sites & members'),
  _FeatureEntry(title: 'Analytics',              value: 'Advanced + predictions'),
  _FeatureEntry(title: 'Inventory',              value: 'Included'),
  _FeatureEntry(title: 'Support',                value: '24/7 dedicated'),
  _FeatureEntry(title: 'Access',                 value: 'Monthly or yearly'),
];

List<_FeatureEntry> _featuresForPlan(PlanTier tier) {
  switch (tier) {
    case PlanTier.trial:    return kTrialFeatures;
    case PlanTier.standard: return kStandardFeatures;
    case PlanTier.premium:  return kPremiumFeatures;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1: SUBSCRIPTION SELECTION
// ─────────────────────────────────────────────────────────────────────────────

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen>
    with SingleTickerProviderStateMixin {

  late final AnimationController _fadeCtrl;
  late final Animation<double>    _fadeAnim;

  int _userCoins     = 0;
  int _selectedIndex = 0; // 0=Premium by default

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  PlanData get _selected => kPlans[_selectedIndex];

  void _selectPlan(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _goToDetail(BuildContext context, Subscription sub) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => PlanDetailScreen(
          plan:      _selected,
          userCoins: _userCoins,
          sub:       sub,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final coinAsync         = ref.watch(coinBalanceProvider);

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
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: subscriptionAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2)),
            error: (e, _) => Center(
                child: Text(extractBackendError(e),
                    style: const TextStyle(color: AppColors.rose))),
            data: (sub) => _buildBody(context, sub),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Subscription sub) {
    final plan    = _selected;
    final isTrial = plan.tier == PlanTier.trial;
    final accent  = plan.accentColor;

    final String ctaLabel = isTrial
        ? 'Start Free Trial '
        : 'Continue with ${plan.name} · ₹${plan.priceMonthly}/mo';

    return Column(
      children: [
        // scrollable content
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.bg,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text('Choose a plan',
                    style: AppTextStyles.screenTitle),
                centerTitle: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppColors.divider),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Plan selector pills (3 across) ───────────────────


                      // ── Feature list — updates on plan change ─────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve:  Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _FeatureListBlock(
                          key:  ValueKey(_selectedIndex),
                          plan: _selected,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PlanSelectorRow(
                        plans:         kPlans,
                        selectedIndex: _selectedIndex,
                        currentPlanId: sub.hasSubscription ? sub.plan : null,
                        onSelect:      _selectPlan,
                      ),



                      const SizedBox(height: 100), // clears fixed CTA
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Fixed CTA ────────────────────────────────────────────────────────
        _FixedCTA(
          label:    ctaLabel,
          accent:   accent,
          gradient: isTrial ? null : plan.cardGradient,
          onTap:    () => _goToDetail(context, sub),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN SELECTOR ROW
// ─────────────────────────────────────────────────────────────────────────────

class _PlanSelectorRow extends StatelessWidget {
  final List<PlanData>    plans;
  final int               selectedIndex;
  final String?           currentPlanId;
  final ValueChanged<int> onSelect;

  const _PlanSelectorRow({
    required this.plans,
    required this.selectedIndex,
    required this.currentPlanId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(plans.length, (i) {
        final plan       = plans[i];
        final isSelected = selectedIndex == i;
        final isCurrent  = currentPlanId == plan.id;
        final isTrial    = plan.tier == PlanTier.trial;
        final accent     = plan.accentColor;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < plans.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withOpacity(0.06)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? accent : AppColors.divider,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                      color: accent.withOpacity(0.13),
                      blurRadius: 10,
                      offset: const Offset(0, 3))]
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    if (isCurrent)
                      _MicroChip(label: 'ACTIVE', color: AppColors.activeGreen)
                    else if (plan.badge.isNotEmpty)
                      _MicroChip(label: plan.badge, color: accent)
                    else
                      const SizedBox(height: 16),

                    const SizedBox(height: 5),

                    Text(plan.name,
                        style: AppTextStyles.planTitle.copyWith(
                          fontSize: 13,
                          color: isSelected ? accent : AppColors.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      isTrial ? '₹1' : '₹${plan.priceMonthly}',
                      style: AppTextStyles.priceMain.copyWith(
                        fontSize: 18,
                        color: isSelected ? accent : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isTrial ? 'for trial' : '/mo',
                      style: AppTextStyles.featureText.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE LIST BLOCK
// Same feature titles across all plans — only values change.
// Title is left-aligned, value is right-aligned → feels like a structured list.
// ─────────────────────────────────────────────────────────────────────────────

class _FeatureListBlock extends StatelessWidget {
  final PlanData plan;
  const _FeatureListBlock({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final accent   = plan.accentColor;
    final features = _featuresForPlan(plan.tier);
    final isTrial  = plan.tier == PlanTier.trial;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.20), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card header: plan name + tagline + price ──────────────────────
          // Container(
          //   padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          //   decoration: BoxDecoration(
          //     color: accent.withOpacity(0.05),
          //     borderRadius:
          //     const BorderRadius.vertical(top: Radius.circular(14)),
          //   ),
          //   child: Row(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(plan.name,
          //                 style: AppTextStyles.planTitle.copyWith(
          //                     fontSize: 17, color: accent)),
          //             const SizedBox(height: 2),
          //             Text(plan.tagline,
          //                 style: AppTextStyles.featureText
          //                     .copyWith(fontSize: 12)),
          //           ],
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Column(
          //         crossAxisAlignment: CrossAxisAlignment.end,
          //         children: [
          //           Text(
          //             isTrial ? '₹1' : '₹${plan.priceMonthly}',
          //             style: AppTextStyles.priceMain.copyWith(
          //                 fontSize: 24, color: accent),
          //           ),
          //           Text(
          //             isTrial ? 'refundable' : '/month',
          //             style:
          //             AppTextStyles.featureText.copyWith(fontSize: 10),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),

          Container(height: 1, color: accent.withOpacity(0.12)),

          // ── Feature rows ──────────────────────────────────────────────────
          ...features.asMap().entries.map((entry) {
            final idx    = entry.key;
            final f      = entry.value;
            final isLast = idx == features.length - 1;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Check / dash icon
                      f.isIncluded
                          ? Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 12, color: accent),
                      )
                          : Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.07),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove_rounded,
                            size: 12, color: AppColors.textMuted),
                      ),

                      const SizedBox(width: 12),

                      // Category title (fixed width so values align)
                      SizedBox(
                        width: 118,
                        child: Text(
                          f.title,
                          style: AppTextStyles.featureText.copyWith(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // Value — right-aligned
                      Expanded(
                        child: Text(
                          f.value,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.featureText.copyWith(
                            fontSize: 13,
                            color: f.isIncluded
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontWeight: f.isIncluded
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(height: 1, color: AppColors.divider),
                  ),
              ],
            );
          }).toList(),

          // ── Trial disclaimer at bottom ─────────────────────────────────────
          if (isTrial) ...[
            Container(height: 1, color: accent.withOpacity(0.12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Text(
                'Explore the app in just ₹1 .',
                style: AppTextStyles.featureText.copyWith(
                    fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          ] else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIXED BOTTOM CTA
// ─────────────────────────────────────────────────────────────────────────────

class _FixedCTA extends StatelessWidget {
  final String    label;
  final Color     accent;
  final Gradient? gradient;
  final VoidCallback onTap;

  const _FixedCTA({
    required this.label,
    required this.accent,
    required this.gradient,
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
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? AppColors.teal.withOpacity(0.12)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: gradient != null
                ? [BoxShadow(
                color: accent.withOpacity(0.26),
                blurRadius: 14,
                offset: const Offset(0, 5))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.ctaLabel.copyWith(
              color: gradient != null ? Colors.white : AppColors.teal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _MicroChip extends StatelessWidget {
  final String label;
  final Color  color;
  const _MicroChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label,
        style: AppTextStyles.badgeText.copyWith(color: color, fontSize: 8)),
  );
}