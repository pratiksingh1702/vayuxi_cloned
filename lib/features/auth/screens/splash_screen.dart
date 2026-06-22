import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _logoAnimation;
  late final Animation<double> _wordmarkAnimation;
  late final Animation<double> _taglineAnimation;
  late final Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
    );
    _wordmarkAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.22, 0.78, curve: Curves.easeOutCubic),
    );
    _taglineAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.48, 0.92, curve: Curves.easeOutCubic),
    );
    _badgeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.62, 1, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _animationController.forward();
      await Future<void>.delayed(const Duration(milliseconds: 1550));
      if (!mounted) return;
      ref.read(authProvider.notifier).checkLogin();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = (width * 0.4).clamp(145.0, 190.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _logoAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - _logoAnimation.value)),
                          child: Transform.scale(
                            scale: 0.94 + (_logoAnimation.value * 0.06),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/images/splash-logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _AnimatedWordmark(animation: _wordmarkAnimation),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _taglineAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(_taglineAnimation),
                      child: const Text(
                        'Every Great Work Deserves a Better System',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: FadeTransition(
                opacity: _badgeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.28),
                    end: Offset.zero,
                  ).animate(_badgeAnimation),
                  child: const Center(
                    child: _MadeInIndiaBadge(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedWordmark extends StatelessWidget {
  const _AnimatedWordmark({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: Text(
              'VAYUXI',
              style: TextStyle(
                color: const Color(0xFF111827),
                fontSize: 30,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 12 - (4 * value),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MadeInIndiaBadge extends StatelessWidget {
  const _MadeInIndiaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(child: Container(color: const Color(0xFFFF9933))),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A4FA3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container(color: const Color(0xFF138808))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Made in India',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
