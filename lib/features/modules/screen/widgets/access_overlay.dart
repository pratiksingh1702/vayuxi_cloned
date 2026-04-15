// features/modules/screen/widgets/access_overlay.dart
//
// ═══════════════════════════════════════════════════════════════════════════
// OVERLAY PHILOSOPHY: THIS WIDGET RENDERS STATE, IT DOES NOT DECIDE TRUST
// ═══════════════════════════════════════════════════════════════════════════
//
// ─────────────────────────────────────────────────────────────────────────────
// BUG FIXED IN THIS VERSION
// ─────────────────────────────────────────────────────────────────────────────
//
// PREVIOUS BUG: _InlinePlanCards had a "grace period safety valve":
//   if (graceData != null && graceData['isWithinGracePeriod'] == true) {
//     widget.onUnlocked();   ← WRONG
//   }
//
// This caused an infinite loop:
//   1. Plan overlay shows (Gate 1: no subscription)
//   2. graceStatusProvider loads → isWithinGracePeriod=true
//   3. _InlinePlanCards calls onUnlocked() (which is _onUnlocked in module_screen)
//   4. _onUnlocked calls evaluate() → hasSubscription still false → noSubscription
//   5. module_screen sets _overlayType = noSubscription → rebuilds plan overlay
//   6. graceStatusProvider still has data → onUnlocked() again → loop
//
// WHY IT WAS WRONG:
//   Grace period bypasses DEVICE OTP only.
//   Grace does NOT bypass the subscription gate.
//   A user within 24h grace who has no plan MUST still pick a plan.
//   The "safety valve" was based on a misunderstanding.
//
// FIX:
//   Removed the grace auto-unlock from _InlinePlanCards entirely.
//   _InlinePlanCards only auto-unlocks when subscription is actually active.
//   accessControlProvider already handles grace correctly at Gate 2.
//
// DEVICE CARD (_InlineDeviceCard) KEEPS its grace check — that one IS correct:
//   If someone lands on deviceNotVerified but grace says requiresDeviceAuth=false,
//   that's a genuine race condition where the overlay should auto-unlock.
//   Grace period DOES bypass device OTP — so that check is right.
//
// ═══════════════════════════════════════════════════════════════════════════
// PLAN VISIBILITY RULES
// ═══════════════════════════════════════════════════════════════════════════
//   sub == null / pending/unknown  → show ALL plans including trial
//   sub exists, status == expired  → hide trial, show paid plans only
//   sub exists, status == active   → hide ALL, unlock immediately
//   sub.hasSubscription == true    → hide ALL, unlock immediately
//   appAccess.trialActivated       → hide ALL, unlock immediately
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../../core/api/dio.dart';
import '../../../../core/router/app_access.dart';
import '../../../../core/router/access_control_provider.dart';
import '../../../auth/service/auth_client.dart';
import '../../../pricing/Screens/subsciption_screen.dart'
    show AppColors, AppTextStyles, PlanData, PlanTier, kPlans;
import '../../../pricing/providers/razorpay_provider.dart';
import '../device_id_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET — AccessOverlay
// ─────────────────────────────────────────────────────────────────────────────

class AccessOverlay extends ConsumerWidget {
  final AccessState type;
  final VoidCallback onUnlocked;
  final VoidCallback onDismiss;

  const AccessOverlay({
    super.key,
    required this.type,
    required this.onUnlocked,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 320),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          color: colorScheme.scrim.withOpacity(0.58),
          child: Column(
            children: [
              _OverlayTopBar(showClose: false, onClose: onDismiss),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _bodyFor(type),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bodyFor(AccessState type) {
    switch (type) {
      case AccessState.noSubscription:
        return _InlinePlanCards(onUnlocked: onUnlocked);
      case AccessState.needsOnboarding:
        return _InlineOnboardingCard(onUnlocked: onUnlocked);
      case AccessState.deviceNotVerified:
        return _InlineDeviceCard(onUnlocked: onUnlocked);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRACE PERIOD BANNER — exported for use inside the main app screens
// ─────────────────────────────────────────────────────────────────────────────

class GracePeriodBanner extends ConsumerWidget {
  const GracePeriodBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graceAsync = ref.watch(graceStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return graceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (graceData) {
        final bool isWithinGrace = graceData['isWithinGracePeriod'] == true;
        final bool isPrimaryDevice = graceData['isPrimaryDevice'] == true;
        final double hours =
            (graceData['hoursRemaining'] as num?)?.toDouble() ?? 0;

        if (!isWithinGrace || isPrimaryDevice) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.tertiary.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 16, color: colorScheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${hours.toStringAsFixed(1)}h left in your free exploration window. '
                  'After that, device verification will be required on new devices.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onTertiaryContainer,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// ─────────────────────────────────────────────────────────────────────────────

class _OverlayTopBar extends StatelessWidget {
  final bool showClose;
  final VoidCallback onClose;
  const _OverlayTopBar({required this.showClose, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding:
          EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showClose)
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.close, color: colorScheme.onSurface, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAN CARDS
//
// IMPORTANT: NO grace period auto-unlock here.
// Grace period bypasses device OTP, not subscription.
// If user is in grace but has no subscription, they MUST pick a plan.
// Auto-unlock only happens when subscription is genuinely active.
// ─────────────────────────────────────────────────────────────────────────────

class _InlinePlanCards extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const _InlinePlanCards({required this.onUnlocked});

  @override
  ConsumerState<_InlinePlanCards> createState() => _InlinePlanCardsState();
}

class _InlinePlanCardsState extends ConsumerState<_InlinePlanCards> {
  String? _activePlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentNotifierProvider.notifier).clearState();
      ref.read(paymentNotifierProvider.notifier).initializeRazorpay();
    });
  }

  void _onPlanTap(PlanData plan) {
    HapticFeedback.lightImpact();
    ref.read(paymentNotifierProvider.notifier).clearState();

    if (plan.id == 'trial') {
      final appAccess = ref.read(appAccessProvider);
      if (!appAccess.onboardingCompleted) {
        context.push('/onboarding');
      } else {
        context.push('/trial');
      }
    } else {
      setState(() => _activePlanId = plan.id);
      ref.read(paymentNotifierProvider.notifier).startSubscriptionPayment(
            plan: plan.id,
            coinsToUse: 0,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final payState = ref.watch(paymentNotifierProvider);
    final sub = ref.watch(currentSubscriptionProvider).valueOrNull;
    final appAccessState = ref.watch(appAccessProvider);

    // ── Auto-unlock ONLY when subscription is genuinely active ───────────
    // Do NOT auto-unlock based on grace period here.
    // Grace bypasses device OTP, not subscription requirement.
    final bool alreadyUnlocked = (sub != null &&
            (sub.hasSubscription == true || sub.status == 'active')) ||
        appAccessState.trialActivated;

    if (alreadyUnlocked) {
      print('✅ [_InlinePlanCards] Subscription active — auto-unlocking');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onUnlocked();
      });
      return const SizedBox.shrink();
    }

    // ── Hide trial for users with known subscription history ─────────────
    final String? subStatus = sub?.status;
    final bool hasKnownStatus = subStatus != null && subStatus.isNotEmpty;
    final visiblePlans =
        hasKnownStatus ? kPlans.where((p) => p.id != 'trial').toList() : kPlans;

    // ── Payment success listener ─────────────────────────────────────────
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      if (next.successMessage != null &&
          (prev?.successMessage == null ||
              prev?.successMessage != next.successMessage)) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            ref.invalidate(graceStatusProvider);
            ref.invalidate(deviceTrustProvider);
            ref
                .read(appAccessProvider.notifier)
                .refreshSubscription()
                .then((_) {
              if (mounted) widget.onUnlocked();
            }).catchError((_) {
              if (mounted) widget.onUnlocked();
            });
          }
        });
      }
      if (!next.isLoading && mounted) {
        setState(() => _activePlanId = null);
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OverlayHeader(
          icon: Icons.lock_open_rounded,
          iconGradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          title: "",
          subtitle:
              "Choose a plan to use Setup, Reports, and all project modules.",
        ),
        const SizedBox(height: 20),
        if (payState.error != null)
          _StatusBanner(isError: true, message: payState.error!),
        if (payState.successMessage != null)
          _StatusBanner(isError: false, message: payState.successMessage!),
        ...visiblePlans.map((plan) {
          final isThisPlanLoading =
              _activePlanId == plan.id && payState.isLoading;
          final anyLoading = payState.isLoading;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CompactPlanCard(
              plan: plan,
              isLoading: isThisPlanLoading,
              disabled: anyLoading && _activePlanId != plan.id,
              onTap: anyLoading ? null : () => _onPlanTap(plan),
            ),
          );
        }),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            "🔒 Secure payment  •  Cancel anytime  ",
            style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                decoration: TextDecoration.none),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPACT PLAN CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CompactPlanCard extends StatelessWidget {
  final PlanData plan;
  final bool isLoading;
  final bool disabled;
  final VoidCallback? onTap;

  const _CompactPlanCard({
    required this.plan,
    required this.isLoading,
    required this.disabled,
    this.onTap,
  });

  bool get _isPremium => plan.tier == PlanTier.premium;
  bool get _isTrial => plan.tier == PlanTier.trial;

  @override
  Widget build(BuildContext context) {
    final accent = plan.accentColor;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isPremium ? accent.withOpacity(0.40) : AppColors.divider,
            width: _isPremium ? 1.5 : 1.0,
          ),
          boxShadow: _isPremium
              ? [
                  BoxShadow(
                      color: accent.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Opacity(
          opacity: _isTrial ? 0.82 : 1.0,
          child: Column(
            children: [
              Container(
                height: _isPremium ? 6 : (_isTrial ? 3 : 5),
                decoration: BoxDecoration(
                  gradient: _isTrial
                      ? LinearGradient(colors: [
                          AppColors.trialGradStart.withOpacity(0.4),
                          AppColors.trialGradEnd.withOpacity(0.25),
                        ])
                      : plan.cardGradient,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(plan.name,
                                  style: AppTextStyles.planTitle.copyWith(
                                      fontSize: 15,
                                      decoration: TextDecoration.none)),
                              if (plan.badge.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: accent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(plan.badge,
                                      style: AppTextStyles.badgeText.copyWith(
                                          color: accent,
                                          fontSize: 9,
                                          decoration: TextDecoration.none)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _isTrial ? '₹1' : '₹${plan.priceMonthly}',
                                style: AppTextStyles.priceMain.copyWith(
                                    fontSize: 24,
                                    decoration: TextDecoration.none),
                              ),
                              const SizedBox(width: 3),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  _isTrial ? ' for trial' : '/mo',
                                  style: AppTextStyles.featureText.copyWith(
                                      fontSize: 10,
                                      decoration: TextDecoration.none),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...plan.features.take(2).map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_rounded,
                                          size: 11, color: accent),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(f,
                                            style: AppTextStyles.featureText
                                                .copyWith(
                                                    fontSize: 11,
                                                    decoration:
                                                        TextDecoration.none),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: (isLoading || disabled) ? null : onTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: (isLoading || disabled || _isTrial)
                              ? null
                              : plan.cardGradient,
                          color: isLoading
                              ? AppColors.divider
                              : disabled
                                  ? AppColors.divider
                                  : _isTrial
                                      ? AppColors.surface
                                      : null,
                          borderRadius: BorderRadius.circular(12),
                          border: _isTrial
                              ? Border.all(color: AppColors.divider)
                              : null,
                          boxShadow: (!isLoading && !disabled && !_isTrial)
                              ? [
                                  BoxShadow(
                                      color: accent.withOpacity(0.28),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3))
                                ]
                              : [],
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.textMuted),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _isTrial ? 'Try Free' : 'Select',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.none,
                                      color: disabled
                                          ? AppColors.textMuted
                                          : _isTrial
                                              ? AppColors.textSecondary
                                              : Colors.white,
                                    ),
                                  ),
                                  if (!_isTrial)
                                    Text('/mo',
                                        style: TextStyle(
                                            fontSize: 9,
                                            decoration: TextDecoration.none,
                                            color:
                                                Colors.white.withOpacity(0.75),
                                            fontWeight: FontWeight.w500)),
                                ],
                              ),
                      ),
                    ),
                  ],
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
// ONBOARDING CARD
// ─────────────────────────────────────────────────────────────────────────────

class _InlineOnboardingCard extends ConsumerWidget {
  final VoidCallback onUnlocked;
  const _InlineOnboardingCard({required this.onUnlocked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return _WhiteCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OverlayHeader(
              icon: Icons.rocket_launch_rounded,
              iconGradient: LinearGradient(
                colors: [colorScheme.tertiary, colorScheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              title: "Complete Setup First",
              subtitle:
                  "Your free plan is active. A quick one-time setup unlocks all modules.",
            ),
            const SizedBox(height: 20),
            ...[
              ('1', 'Add your first site'),
              ('2', 'Configure team & rates'),
              ('3', "You're all set!"),
            ].map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: colorScheme.tertiary.withOpacity(0.35)),
                      ),
                      child: Center(
                        child: Text(s.$1,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: colorScheme.onTertiaryContainer,
                                decoration: TextDecoration.none)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(s.$2,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                            decoration: TextDecoration.none)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _PlainButton(
              label: "Start Setup →",
              color: colorScheme.primary,
              onTap: () async {
                ref.read(appAccessProvider.notifier).markOnboardingCompleted();
                await Future.delayed(const Duration(milliseconds: 100));
                onUnlocked();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE OTP CARD
//
// This CORRECTLY checks grace period before showing OTP UI.
// Grace period bypasses device OTP — so if backend says requiresDeviceAuth=false,
// auto-unlock is correct here.
//
// This is different from _InlinePlanCards:
//   - Plan cards: grace does NOT bypass subscription → no auto-unlock
//   - Device card: grace DOES bypass device OTP → auto-unlock is correct
// ─────────────────────────────────────────────────────────────────────────────

class _InlineDeviceCard extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const _InlineDeviceCard({required this.onUnlocked});

  @override
  ConsumerState<_InlineDeviceCard> createState() => _InlineDeviceCardState();
}

class _InlineDeviceCardState extends ConsumerState<_InlineDeviceCard> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final res = await AuthAPI.generateDeviceOtp();
      setState(() {
        _otpSent = true;
        _message = res['message'] ?? "OTP sent to your email";
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _message = "Failed to send OTP. Try again.";
        _isSuccess = false;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length != 4) {
      setState(() {
        _message = "Please enter the 4-digit code";
        _isSuccess = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final res = await AuthAPI.verifyDeviceOtp({'otp': _otpCtrl.text.trim()});

      final newDeviceId = res['deviceId']?.toString() ?? '';
      if (newDeviceId.isNotEmpty) {
        await DioClient.setDeviceIdCookie(newDeviceId);
        await DevicePrefs.saveDeviceId(newDeviceId);
      }

      ref.invalidate(graceStatusProvider);
      ref.invalidate(deviceTrustProvider);
      ref.read(accessControlProvider.notifier).evaluate();

      widget.onUnlocked();
    } catch (e) {
      setState(() {
        _message = "Invalid OTP. Please try again.";
        _isSuccess = false;
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Use deviceTrustProvider for requiresDeviceAuth — this is the correct source
    final trustAsync = ref.watch(deviceTrustProvider);

    return trustAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              SizedBox(height: 16),
              Text('Checking device status...',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
      error: (_, __) => _buildOtpContent(colorScheme),
      data: (trustData) {
        final bool requiresDeviceAuth = trustData['requiresDeviceAuth'] == true;

        if (!requiresDeviceAuth) {
          print(
              '✅ [_InlineDeviceCard] requiresDeviceAuth=false — auto-unlocking');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onUnlocked();
          });
          return const SizedBox.shrink();
        }

        return _buildOtpContent(colorScheme);
      },
    );
  }

  Widget _buildOtpContent(ColorScheme colorScheme) {
    return _WhiteCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OverlayHeader(
              icon: Icons.shield_rounded,
              iconGradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              title:
                  _otpSent ? "Enter Verification Code" : "Verify Your Device",
              subtitle: _otpSent
                  ? "A 4-digit code has been sent to your registered email."
                  : "One-time verification to protect your project data.",
            ),
            const SizedBox(height: 20),
            if (!_otpSent) ...[
              _InfoTile(
                  icon: Icons.lock_outline,
                  text: "Data accessible only to you",
                  color: colorScheme.primary),
              const SizedBox(height: 8),
              _InfoTile(
                  icon: Icons.block,
                  text: "Stops misuse from shared APKs",
                  color: colorScheme.primary),
              const SizedBox(height: 8),
              _InfoTile(
                  icon: Icons.verified_user_outlined,
                  text: "Done once — never repeated on this device",
                  color: colorScheme.primary),
              const SizedBox(height: 20),
            ],
            if (_otpSent) ...[
              PinCodeTextField(
                length: 4,
                appContext: context,
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                cursorColor: colorScheme.primary,
                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  decoration: TextDecoration.none,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 42,
                  activeColor: colorScheme.primary,
                  selectedColor: colorScheme.primary,
                  inactiveColor: colorScheme.outlineVariant,
                  activeFillColor: colorScheme.surface,
                  selectedFillColor: colorScheme.surfaceContainerLow,
                  inactiveFillColor: colorScheme.surface,
                  borderWidth: 2,
                ),
                enableActiveFill: true,
                animationDuration: const Duration(milliseconds: 180),
                onChanged: (_) {},
                autoDisposeControllers: false,
                backgroundColor: Colors.transparent,
              ),
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Didn't receive it? ",
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.none)),
                    GestureDetector(
                      onTap: _loading ? null : _sendOtp,
                      child: Text("Resend",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                              color: _loading
                                  ? colorScheme.outline
                                  : colorScheme.primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_message != null)
              _StatusBanner(isError: !_isSuccess, message: _message!),
            const SizedBox(height: 16),
            _PlainButton(
              label: _loading
                  ? ''
                  : _otpSent
                      ? "Verify & Unlock"
                      : "Send Verification Code",
              color: colorScheme.primary,
              isLoading: _loading,
              onTap: _loading ? null : (_otpSent ? _verifyOtp : _sendOtp),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAIN BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _PlainButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PlainButton(
      {required this.label,
      required this.color,
      this.onTap,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: onTap == null ? color.withOpacity(0.5) : color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap == null
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: Colors.white))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.1,
                      decoration: TextDecoration.none)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(32),
      elevation: 0,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
          border:
              Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _OverlayHeader extends StatelessWidget {
  final IconData icon;
  final Gradient iconGradient;
  final String title;
  final String subtitle;

  const _OverlayHeader(
      {required this.icon,
      required this.iconGradient,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (title.isNotEmpty)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (iconGradient as LinearGradient)
                      .colors
                      .first
                      .withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        if (title.isNotEmpty) const SizedBox(height: 20),
        if (title.isNotEmpty)
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                  decoration: TextDecoration.none)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.none)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoTile(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none)),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool isError;
  final String message;
  const _StatusBanner({required this.isError, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        isError ? colorScheme.errorContainer : colorScheme.tertiaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onTertiaryContainer;
    final border = isError
        ? colorScheme.error.withOpacity(0.45)
        : colorScheme.tertiary.withOpacity(0.4);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 12.5,
                    color: foreground,
                    decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }
}
