import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:smart_auth/smart_auth.dart';

import '../provider/auth_provider.dart';
import '../service/auth_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final SmartAuth _smartAuth = SmartAuth.instance;

  bool otpVisible = false;
  bool isSendingOtp = false;
  bool isVerifyingOtp = false;
  bool isRequestingPhoneHint = false;
  bool _showOnboarding = true;
  bool _hasAttemptedAutoPhoneHint = false;
  bool _isContinuePressed = false;
  DateTime? _lastAutoHintAt;

  int _resendCooldown = 0;
  Timer? _resendTimer;

  late final AnimationController _topAnimController;
  late final AnimationController _sheetAnimController;
  late final Animation<double> _topFade;
  late final Animation<Offset> _topSlide;
  late final Animation<double> _sheetFade;
  late final Animation<Offset> _sheetSlide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    phoneController.addListener(_refreshUi);
    _phoneFocusNode.addListener(_onPhoneFocusChanged);

    _topAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _sheetAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _topFade = CurvedAnimation(
      parent: _topAnimController,
      curve: Curves.easeOutCubic,
    );
    _topSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _topAnimController, curve: Curves.easeOutCubic),
    );

    _sheetFade = CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOutQuart,
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _sheetAnimController, curve: Curves.easeOutQuart),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _topAnimController.forward();
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _sheetAnimController.forward();
      });
      Future<void>.delayed(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        if (!_showOnboarding) _triggerAutoPhoneHint();
      });
    });
  }

  Future<void> _triggerAutoPhoneHint() async {
    if (_hasAttemptedAutoPhoneHint) return;
    if (isRequestingPhoneHint) return;
    if (otpVisible) return;
    if (_showOnboarding) return;
    if (_phoneFocusNode.hasFocus) return;
    if (phoneController.text.trim().isNotEmpty) return;
    _hasAttemptedAutoPhoneHint = true;
    _lastAutoHintAt = DateTime.now();
    debugPrint('[SMART_AUTH] Auto phone hint trigger started');
    await _requestPhoneHint(showPickerMessage: false);
  }

  void _openLoginFromOnboarding() {
    if (!_showOnboarding) return;
    setState(() => _showOnboarding = false);
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      _triggerAutoPhoneHint();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!mounted) return;
    if (isRequestingPhoneHint || otpVisible) return;
    if (_showOnboarding) return;
    if (_phoneFocusNode.hasFocus) return;
    if (phoneController.text.trim().isNotEmpty) return;

    final now = DateTime.now();
    if (_lastAutoHintAt != null &&
        now.difference(_lastAutoHintAt!).inSeconds < 3) {
      return;
    }

    _lastAutoHintAt = now;
    _requestPhoneHint(showPickerMessage: false);
  }

  void _refreshUi() {
    if (!mounted) return;
    setState(() {});
  }

  void _onPhoneFocusChanged() {
    if (_phoneFocusNode.hasFocus) {
      // User is entering phone manually, so don't interrupt with auto-hint flow.
      _hasAttemptedAutoPhoneHint = true;
    }
  }

  String _normalizedPhone() {
    var digits = phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  bool get _isPhoneValid => RegExp(r'^[0-9]{10}$').hasMatch(_normalizedPhone());

  Future<void> _requestPhoneHint({
    bool showPickerMessage = true,
  }) async {
    if (isRequestingPhoneHint) return;
    setState(() => isRequestingPhoneHint = true);
    debugPrint('[SMART_AUTH] requestPhoneNumberHint() called');

    try {
      final res = await _smartAuth.requestPhoneNumberHint();
      if (!mounted) return;

      if (res.hasData) {
        debugPrint('[SMART_AUTH] Phone hint received: ${res.requireData}');
        var digits = res.requireData.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length > 10) {
          digits = digits.substring(digits.length - 10);
        }
        if (digits.length == 10) {
          phoneController.text = digits;
          if (showPickerMessage) {
            _showSuccessSnackBar('Phone number selected');
          }
        } else {
          debugPrint('[SMART_AUTH] Hint parse failed. Digits: $digits');
          _showErrorSnackBar('Could not find a valid 10-digit number');
        }
      } else if (!res.isCanceled) {
        debugPrint('[SMART_AUTH] Phone hint unavailable: ${res.error}');
        _showErrorSnackBar('Phone hint is unavailable on this device');
      } else {
        debugPrint('[SMART_AUTH] Phone hint canceled by user');
      }
    } catch (e) {
      debugPrint('[SMART_AUTH] Phone hint error: $e');
      if (mounted) {
        _showErrorSnackBar('Phone hint is unavailable on this device');
      }
    } finally {
      if (mounted) setState(() => isRequestingPhoneHint = false);
    }
  }

  Future<void> _startSmsAutofill() async {
    try {
      final res = await _smartAuth.getSmsWithUserConsentApi(
        matcher: r'\b(\d{4})\b',
      );
      if (!mounted || !res.hasData) return;

      final code = res.requireData.code;
      if (code == null || code.length != 4) return;
      otpController.text = code;
      if (mounted) setState(() {});
    } catch (_) {
      // User can continue with manual OTP entry.
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = 30);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) {
      _showErrorSnackBar('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() => isSendingOtp = true);

    try {
      await AuthAPI.sendPhoneOtp(_normalizedPhone());
      if (!mounted) return;

      setState(() => otpVisible = true);
      _startResendCooldown();
      _startSmsAutofill();
      _showSuccessSnackBar('OTP sent successfully');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.length != 4) {
      _showErrorSnackBar('Please enter a valid 4-digit OTP');
      return;
    }

    setState(() => isVerifyingOtp = true);
    var shouldResetLoading = true;

    try {
      await ref
          .read(authProvider.notifier)
          .loginWithPhoneOtp(_normalizedPhone(), otp);

      await _smartAuth.removeUserConsentApiListener();
      _resendTimer?.cancel();

      if (!mounted) return;
      _showSuccessSnackBar('Login successful');
      shouldResetLoading = false;
      context.go('/workCategory');
      return;
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && shouldResetLoading) {
        setState(() => isVerifyingOtp = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C1810),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1A2C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _smartAuth.removeUserConsentApiListener();
    WidgetsBinding.instance.removeObserver(this);
    _topAnimController.dispose();
    _sheetAnimController.dispose();
    _phoneFocusNode.removeListener(_onPhoneFocusChanged);
    _phoneFocusNode.dispose();
    phoneController.removeListener(_refreshUi);
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Widget _buildLoginPane() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      key: const ValueKey('login-pane'),
      padding: EdgeInsets.fromLTRB(18, 6, 18, 18 + keyboardInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Continue with your phone number to access attendance and site workflows.',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Phone Number',
            style: TextStyle(
              color: Color(0xFF5D6070),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PhoneField(
                  controller: phoneController,
                  focusNode: _phoneFocusNode,
                  isValid: _isPhoneValid,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (otpVisible) ...[
            const SizedBox(height: 6),
            const Text(
              'One-Time Password',
              style: TextStyle(
                color: Color(0xFF5D6070),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _OtpField(
              controller: otpController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _resendCooldown == 0 ? _sendOtp : null,
                child: Text(
                  _resendCooldown == 0
                      ? 'Resend OTP'
                      : 'Resend in ${_resendCooldown}s',
                  style: TextStyle(
                    color: _resendCooldown == 0
                        ? const Color(0xFF3554C7)
                        : const Color(0xFFB3B6C3),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTapDown: (details) {
              final canPress = otpVisible
                  ? (!isVerifyingOtp && otpController.text.trim().length == 4)
                  : (!isSendingOtp && _isPhoneValid);
              if (!canPress) return;
              setState(() => _isContinuePressed = true);
            },
            onTapCancel: () {
              if (_isContinuePressed) {
                setState(() => _isContinuePressed = false);
              }
            },
            onTapUp: (details) {
              if (_isContinuePressed) {
                setState(() => _isContinuePressed = false);
              }
            },
            child: AnimatedScale(
              scale: _isContinuePressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: otpVisible
                      ? (isVerifyingOtp || otpController.text.trim().length != 4
                          ? null
                          : _verifyOtp)
                      : (isSendingOtp || !_isPhoneValid ? null : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF121926),
                    disabledBackgroundColor: const Color(0xFFE3E6F1),
                    disabledForegroundColor: const Color(0xFFB0B5C6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isVerifyingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF7F9FF),
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            otpVisible ? 'Continue' : 'Send OTP',
                            key: ValueKey(
                                'cta-${otpVisible ? 'continue' : 'send'}'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF7F9FF),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    const accent = Color(0xFF4AA3FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: baseTheme.brightness,
    );
    final pageTheme = baseTheme.copyWith(
      colorScheme: scheme,
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardInset > 0;
    final sheetMaxHeight = _showOnboarding
        ? mediaQuery.size.height * 0.63
        : mediaQuery.size.height * 0.72;

    return Theme(
      data: pageTheme,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            _AuthBackground(showOnboarding: _showOnboarding),
            SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 18,
                    child: IgnorePointer(
                      ignoring: isKeyboardVisible,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 140),
                        opacity: isKeyboardVisible ? 0 : 1,
                        child: FadeTransition(
                          opacity: _topFade,
                          child: const _HeaderLogoAvatar(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 18,
                    child: IgnorePointer(
                      ignoring: isKeyboardVisible,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 140),
                        opacity: isKeyboardVisible ? 0 : 1,
                        child: FadeTransition(
                          opacity: _topFade,
                          child: const _HeaderSocialProof(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _showOnboarding ? 98 : 88,
                    left: _showOnboarding ? 18 : 8,
                    right: _showOnboarding ? 18 : 8,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      opacity: isKeyboardVisible ? 0 : 1,
                      child: FadeTransition(
                        opacity: _topFade,
                        child: SlideTransition(
                          position: _topSlide,
                          child: _AuthTopPanel(showOnboarding: _showOnboarding),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FadeTransition(
                      opacity: _sheetFade,
                      child: SlideTransition(
                        position: _sheetSlide,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: sheetMaxHeight,
                          ),
                          child: _AuthSheet(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.08),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: _showOnboarding
                                  ? _OnboardingPane(
                                      key: const ValueKey('onboarding-pane'),
                                      onContinue: _openLoginFromOnboarding,
                                    )
                                  : _buildLoginPane(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground({required this.showOnboarding});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    final colors = const [
      Color(0xFF0A3D99),
      Color(0xFF1262D3),
      Color(0xFF2690FF),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -86,
            left: -72,
            child: _AnimatedOrb(
              size: 250,
              baseColor: Color(0xFF77CBF9),
              duration: Duration(milliseconds: 5200),
            ),
          ),
          Positioned(
            top: 92,
            right: -56,
            child: _AnimatedOrb(
              size: 220,
              baseColor: Color(0xFF4DE2BE),
              duration: Duration(milliseconds: 4300),
            ),
          ),
          Positioned(
            bottom: -118,
            left: -66,
            child: _AnimatedOrb(
              size: 270,
              baseColor: Color(0xFF4AA3FF),
              duration: Duration(milliseconds: 4700),
            ),
          ),
          Positioned(
            bottom: -84,
            right: -64,
            child: _AnimatedOrb(
              size: 230,
              baseColor: Color(0xFF72E3D9),
              duration: Duration(milliseconds: 5100),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _GridTexture(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOrb extends StatefulWidget {
  const _AnimatedOrb({
    required this.size,
    required this.baseColor,
    required this.duration,
  });

  final double size;
  final Color baseColor;
  final Duration duration;

  @override
  State<_AnimatedOrb> createState() => _AnimatedOrbState();
}

class _AnimatedOrbState extends State<_AnimatedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -16 * t),
          child: Transform.scale(
            scale: 0.9 + (t * 0.18),
            child: Opacity(
              opacity: 0.25 + (t * 0.2),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.baseColor,
              widget.baseColor.withValues(alpha: 0.06),
              widget.baseColor.withValues(alpha: 0),
            ],
            stops: const [0.12, 0.58, 1],
          ),
        ),
      ),
    );
  }
}

class _GridTexture extends StatelessWidget {
  const _GridTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridTexturePainter(),
    );
  }
}

class _GridTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.06);

    const ringGap = 58.0;
    final center = Offset(size.width * 0.78, size.height * 0.12);
    for (double radius = 36;
        radius < size.longestSide * 0.9;
        radius += ringGap) {
      canvas.drawCircle(center, radius, ringPaint);
    }

    final linePaint = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.035);
    const gap = 44.0;
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AuthTopPanel extends StatelessWidget {
  const _AuthTopPanel({required this.showOnboarding});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: showOnboarding
          ? Column(
              key: const ValueKey('onboarding-top'),
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                _RotatingTypewriterPanel(),
              ],
            )
          : const _HappyStoriesPanel(
              key: ValueKey('stories-top'),
            ),
    );
  }
}

class _HappyStoriesPanel extends StatefulWidget {
  const _HappyStoriesPanel({super.key});

  @override
  State<_HappyStoriesPanel> createState() => _HappyStoriesPanelState();
}

class _HappyStoriesPanelState extends State<_HappyStoriesPanel> {
  static const List<({String name, String quote})> _stories = [
    (
      name: 'Rakesh, Site Supervisor',
      quote: 'Attendance updates are finally smooth. My day starts calmer now.'
    ),
    (
      name: 'Anita, Project Coordinator',
      quote:
          'Progress tracking feels clean and fast. Teams stay perfectly aligned.'
    ),
    (
      name: 'Mohan, Field Engineer',
      quote:
          'From material checks to logs, everything is now one effortless flow.'
    ),
  ];

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86);
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 3400), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _stories.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 620),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _stories.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemBuilder: (context, index) {
              final story = _stories[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  var page = _currentPage.toDouble();
                  if (_pageController.hasClients) {
                    page = _pageController.page ?? page;
                  }
                  final distance = (page - index).abs().clamp(0.0, 1.0);
                  final scale = 1 - (distance * 0.14);
                  final lift = 14 * distance;
                  return Transform.translate(
                    offset: Offset(0, lift),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: 1 - (distance * 0.42),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _StoryCardSurface(story: story),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: _StoryPageIndicator(
              itemCount: _stories.length,
              currentIndex: _currentPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCardSurface extends StatelessWidget {
  const _StoryCardSurface({required this.story});

  final ({String name, String quote}) story;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.13),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                color: Color(0xFFEAF4FF),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                story.quote,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.45,
                  color: const Color(0xFFF3F9FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                story.name,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFBCE0FF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryPageIndicator extends StatelessWidget {
  const _StoryPageIndicator({
    required this.itemCount,
    required this.currentIndex,
  });

  final int itemCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected
                ? const Color(0xFFEAF5FF)
                : const Color(0xFFEAF5FF).withValues(alpha: 0.45),
          ),
        );
      }),
    );
  }
}

class _FullScreenLoginLottie extends StatelessWidget {
  const _FullScreenLoginLottie();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.84),
            ),
          ),
          Positioned.fill(
            child: Lottie.asset(
              'assets/images/Login.json',
              fit: BoxFit.cover,
              repeat: true,
              frameRate: FrameRate.max,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                    '[Lottie][_FullScreenLoginLottie] Failed to load assets/images/Login.json');
                debugPrint('[Lottie][_FullScreenLoginLottie] Error: $error');
                if (stackTrace != null) {
                  debugPrint(
                      '[Lottie][_FullScreenLoginLottie] StackTrace: $stackTrace');
                }
                return Container(
                  color: const Color(0xFFF6F8FC),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.animation_rounded,
                    size: 38,
                    color: Color(0xFF8EA0BE),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSocialProof extends StatelessWidget {
  const _HeaderSocialProof();

  @override
  Widget build(BuildContext context) {
    return const _AvatarStackSocialProof();
  }
}

class _HeaderLogoAvatar extends StatelessWidget {
  const _HeaderLogoAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Color(0x22000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/adaptive-icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _AvatarStackSocialProof extends StatelessWidget {
  const _AvatarStackSocialProof();

  static const List<({String initials, Color color})> _avatars = [
    (initials: 'RK', color: Color(0xFF2E8BDE)),
    (initials: 'AS', color: Color(0xFF1EA4A0)),
    (initials: 'MN', color: Color(0xFF4C74D9)),
    (initials: 'PA', color: Color(0xFF2D9FC8)),
  ];

  @override
  Widget build(BuildContext context) {
    const avatarSize = 32.0;
    const overlap = 10.0;
    final totalWidth = (_avatars.length * (avatarSize - overlap)) + overlap;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: totalWidth,
          height: avatarSize,
          child: Stack(
            children: [
              for (var i = 0; i < _avatars.length; i++)
                Positioned(
                  left: i * (avatarSize - overlap),
                  child: _AvatarDot(
                    initials: _avatars[i].initials,
                    color: _avatars[i].color,
                    size: avatarSize,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '+4.6k',
          style: GoogleFonts.poppins(
            color: const Color(0xFFF3F8FF),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _AvatarDot extends StatelessWidget {
  const _AvatarDot({
    required this.initials,
    required this.color,
    required this.size,
  });

  final String initials;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x22000000),
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RotatingTypewriterPanel extends StatefulWidget {
  const _RotatingTypewriterPanel();

  @override
  State<_RotatingTypewriterPanel> createState() =>
      _RotatingTypewriterPanelState();
}

class _RotatingTypewriterPanelState extends State<_RotatingTypewriterPanel> {
  static const Color _accent = Color(0xFF4AA3FF);

  static const List<({String keyword, String sentence, String subtitle})>
      _items = [
    (
      keyword: 'Workforce',
      sentence: 'Workforce visibility at every shift.',
      subtitle: 'See who is present and allocate teams quickly.'
    ),
    (
      keyword: 'Updates',
      sentence: 'Updates that keep everyone aligned.',
      subtitle: 'Share changes in real time with zero confusion.'
    ),
    (
      keyword: 'Records',
      sentence: 'Records organized without extra effort.',
      subtitle: 'Capture daily logs with reliable structure.'
    ),
    (
      keyword: 'Inventory',
      sentence: 'Inventory tracked before shortages happen.',
      subtitle: 'Monitor materials and avoid on-site delays.'
    ),
    (
      keyword: 'Progress',
      sentence: 'Progress measured with clear milestones.',
      subtitle: 'Keep project momentum visible every day.'
    ),
    (
      keyword: 'Coordination',
      sentence: 'Coordination simplified across teams.',
      subtitle: 'Connect field staff and office decisions faster.'
    ),
    (
      keyword: 'Decisions',
      sentence: 'Decisions driven by live site data.',
      subtitle: 'Act confidently with the right information.'
    ),
  ];

  int _index = 0;
  Timer? _rotateTimer;

  @override
  void initState() {
    super.initState();
    _rotateTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _items.length);
    });
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_index];
    return SizedBox(
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 550),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _SingleTypewriterLine(
          key: ValueKey(_index),
          keyword: item.keyword,
          sentence: item.sentence,
          subtitle: item.subtitle,
          accent: _accent,
        ),
      ),
    );
  }
}

class _SingleTypewriterLine extends StatefulWidget {
  const _SingleTypewriterLine({
    super.key,
    required this.keyword,
    required this.sentence,
    required this.subtitle,
    required this.accent,
  });

  final String keyword;
  final String sentence;
  final String subtitle;
  final Color accent;

  @override
  State<_SingleTypewriterLine> createState() => _SingleTypewriterLineState();
}

class _SingleTypewriterLineState extends State<_SingleTypewriterLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final typedCount = (widget.sentence.length * _controller.value)
            .floor()
            .clamp(0, widget.sentence.length);
        final visible = widget.sentence.substring(0, typedCount);

        final String keywordVisible;
        final String neutralVisible;
        if (visible.length <= widget.keyword.length) {
          keywordVisible = visible;
          neutralVisible = '';
        } else {
          keywordVisible = widget.keyword;
          neutralVisible = visible.substring(widget.keyword.length);
        }

        return Column(
          key: widget.key,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: keywordVisible,
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: widget.accent,
                      height: 1.1,
                    ),
                  ),
                  TextSpan(
                    text: neutralVisible,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF2F7FF),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _controller.value > 0.72 ? 1 : 0,
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFD6E6FA),
                  height: 1.45,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopLottieCard extends StatelessWidget {
  const _TopLottieCard({required this.size, required this.assetPath});

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.14),
        border:
            Border.all(color: const Color(0xFF9EC5F0).withValues(alpha: 0.55)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 20,
            color: Color(0x3300081A),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Lottie.asset(
            assetPath,
            fit: BoxFit.contain,
            repeat: true,
            frameRate: FrameRate.max,
            errorBuilder: (context, error, stackTrace) {
              debugPrint(
                  '[Lottie][_TopLottieCard] Failed to load asset: $assetPath');
              debugPrint('[Lottie][_TopLottieCard] Error: $error');
              if (stackTrace != null) {
                debugPrint('[Lottie][_TopLottieCard] StackTrace: $stackTrace');
              }
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9FD2FF).withValues(alpha: 0.5),
                      const Color(0xFF79E6D1).withValues(alpha: 0.45),
                    ],
                  ),
                ),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Color(0xFFF5FAFF),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  const _TypewriterText({
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final count = (widget.text.length * _controller.value).floor();
        final visible =
            widget.text.substring(0, count.clamp(0, widget.text.length));
        return Text(
          visible,
          textAlign: widget.textAlign,
          style: widget.style,
        );
      },
    );
  }
}

class _AuthSheet extends StatelessWidget {
  const _AuthSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 30,
            spreadRadius: 0,
            color: Color(0x1E000000),
            offset: Offset(0, -8),
          ),
        ],
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _OnboardingPane extends StatelessWidget {
  const _OnboardingPane({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TypewriterText(
            text: 'Everything you need on site, Perfectly organized.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111829),
            ),
          ),
          const SizedBox(height: 10),
          const _TypewriterText(
            text:
                'Attendance, progress and expenses connected in one delightful flow.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF5F6984),
            ),
          ),
          const SizedBox(height: 6),
          const _TypewriterText(
            text: 'Simple. Fast. Reliable.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF243B6A),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF121926),
                foregroundColor: const Color(0xFFF7F9FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Start Now',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1100),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        height: 176,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFE5F0FF), Color(0xFFDFF8F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFD6E5FF)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: _MiniCard(
                accentColor: const Color(0xFF3E62D3),
              ),
            ),
            Positioned(
              top: 26,
              right: 18,
              child: _MiniBar(width: 90, color: const Color(0xFF86B8FF)),
            ),
            Positioned(
              top: 44,
              right: 18,
              child: _MiniBar(width: 64, color: const Color(0xFFA7D5FF)),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: _MiniCard(
                accentColor: const Color(0xFF2F7A72),
              ),
            ),
            Positioned(
              bottom: 18,
              right: 16,
              child: const _SignalTile(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 18,
            height: 8,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalTile extends StatefulWidget {
  const _SignalTile();

  @override
  State<_SignalTile> createState() => _SignalTileState();
}

class _SignalTileState extends State<_SignalTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.62),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = 0.6 + (_controller.value * 0.4);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(color: const Color(0xFF2B6B63), scale: pulse),
                const SizedBox(width: 6),
                _PulseDot(color: const Color(0xFF3E62D3), scale: 1.4 - pulse),
                const SizedBox(width: 6),
                _PulseDot(color: const Color(0xFF4D9BEA), scale: pulse),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color, required this.scale});

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _PhoneField extends StatefulWidget {
  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.isValid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isValid;
  final ValueChanged<String> onChanged;

  @override
  State<_PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<_PhoneField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    _isFocused = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant _PhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final hasInput = widget.controller.text.trim().isNotEmpty;
    final borderColor = hasInput && !widget.isValid
        ? const Color(0xFFD4907A)
        : _isFocused
            ? const Color(0xFF4A69DC)
            : const Color(0xFFE0E6F7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF7F9FF),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '+91',
              style: TextStyle(
                color: Color(0xFF5B6178),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Color(0xFF151823), fontSize: 15),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: Color(0xFFA0A8C2)),
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintButton extends StatelessWidget {
  const _HintButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF7F9FF),
          border: Border.all(color: const Color(0xFFE0E6F7)),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4A69DC),
                  ),
                ),
              )
            : const Icon(
                Icons.sim_card_rounded,
                color: Color(0xFF586082),
                size: 20,
              ),
      ),
    );
  }
}

class _OtpField extends StatelessWidget {
  const _OtpField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PinCodeTextField(
      appContext: context,
      length: 4,
      autoDisposeControllers: false,
      controller: controller,
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      enableActiveFill: true,
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(12),
        fieldHeight: 52,
        fieldWidth: 52,
        activeFillColor: const Color(0xFFF7F9FF),
        inactiveFillColor: const Color(0xFFF7F9FF),
        selectedFillColor: const Color(0xFFE8EEFF),
        activeColor: const Color(0xFF4A69DC),
        inactiveColor: const Color(0xFFE0E6F7),
        selectedColor: const Color(0xFF4A69DC),
      ),
      textStyle: const TextStyle(
          color: Color(0xFF151823), fontWeight: FontWeight.w700),
      onChanged: onChanged,
    );
  }
}
