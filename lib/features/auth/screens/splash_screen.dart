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
    _badgeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.48, 1, curve: Curves.easeOutCubic),
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
    final logoWidth = (width * 0.88).clamp(300.0, 460.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - _logoAnimation.value)),
                            child: Transform.scale(
                              scale: 0.96 + (_logoAnimation.value * 0.04),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/master_logo.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
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
