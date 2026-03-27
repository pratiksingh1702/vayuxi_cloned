import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../modules/screen/craosule_banner.dart';
import '../provider/auth_provider.dart';
import '../service/auth_client.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();

  bool otpVisible = false;
  bool isSendingOtp = false;
  bool otpButtonLoading = false;

  // Resend cooldown state
  int _resendCooldown = 0;
  Timer? _resendTimer;

  final List<String> carouselImages = [
    'assets/images/l1.webp',
    'assets/images/l2.webp',
    'assets/images/l3.webp',
  ];

  // ─── Resend cooldown logic ────────────────────────────────────────────────

  void _startResendCooldown() {
    _resendTimer?.cancel();

    setState(() => _resendCooldown = 30);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel(); // 🔥 THIS IS MANDATORY
        return;
      }

      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }
  // ─── API calls ────────────────────────────────────────────────────────────

  Future<void> sendOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showErrorSnackBar("Please enter your email address");
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _showErrorSnackBar("Please enter a valid email address");
      return;
    }

    setState(() => isSendingOtp = true);

    try {
      await AuthAPI.generateLoginOtp(email);
      setState(() => otpVisible = true);
      _startResendCooldown();
      _showSuccessSnackBar("OTP sent successfully!");
    } catch (e) {
      if (e is DioException) {
        final data = e.response?.data;
        final code = data?['code'];

        if (code == 'USER_NOT_FOUND') {
          _showAccountNotFoundDialog();
          return;
        }
      }

      _showErrorSnackBar(
        e.toString().contains('timeout')
            ? "Network timeout. Please check your connection"
            : "Failed to send OTP. Please try again",
      );
    } finally {
      if (mounted) setState(() => isSendingOtp = false);
    }
  }

  void _showAccountNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Account Not Found",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "No account found with this email. Please register to continue.",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF218AE6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Register",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 4) {
      _showErrorSnackBar("Please enter a valid 4-digit OTP");
      return;
    }

    setState(() => otpButtonLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .loginWithOtp(emailController.text.trim(), otp);
      _resendTimer?.cancel(); // 🔥 ADD THIS

      // ❌ DO NOTHING AFTER THIS
      // AuthNotifier will update auth state → trigger subscription check
      // → open Razorpay if needed → router will redirect.
    } catch (e) {
      print("error");
      if (!mounted) return;


      _showErrorSnackBar(
        e.toString().contains('Invalid OTP')
            ? "Invalid OTP. Please check and try again"
            : "OTP verification failed. Please try again",
      );
    }finally{
      setState(() {
        otpButtonLoading=false;
      });
    }

    // ❌ NO finally / NO setState(false) — intentional.
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool get _isEmailValid =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(emailController.text.trim());

  bool get _hasEmailInput => emailController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _resendTimer?.cancel(); // 🔥 FIRST
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.webp',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcATop,
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  _WelcomeHeader(screenWidth: screenWidth),
                  const SizedBox(height: 12),

                  // ── Carousel ────────────────────────────────────────────
                  AdBannerCarousel(
                    height: 220,
                    boxFit: BoxFit.contain,
                    imageUrls: carouselImages,
                  ),
                  const SizedBox(height: 12),

                  // ── Tagline ─────────────────────────────────────────────
                  _TaglineText(),
                  const SizedBox(height: 24),

                  // ── Email field ─────────────────────────────────────────
                  _FieldLabel(label: "E-Mail ID*"),
                  const SizedBox(height: 6),
                  _EmailField(
                    controller: emailController,
                    isSendingOtp: isSendingOtp,
                    isEmailValid: _isEmailValid,
                    hasInput: _hasEmailInput,
                    onSend: sendOtp,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // ── OTP field (conditional) ──────────────────────────────
                  if (otpVisible) ...[
                    _FieldLabel(label: "One-Time Password"),
                    const SizedBox(height: 6),
                    PinCodeTextField(
                      length: 4,
                      appContext: context,
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      enableActiveFill: true,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 45,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        inactiveColor: Colors.grey.shade300,
                        selectedColor: const Color(0xFF218AE6),
                        activeColor: const Color(0xFF218AE6),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 4),

                    // ── Resend OTP inline text ───────────────────────────
                    _ResendRow(
                      cooldown: _resendCooldown,
                      onResend: _resendCooldown == 0 ? sendOtp : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Primary CTA: Login ───────────────────────────────────
                  _LoginButton(
                    isLoading: otpButtonLoading,
                    isEnabled:
                    !otpButtonLoading && otpController.text.length == 4,
                    onPressed: verifyOtp,
                  ),
                  const SizedBox(height: 28),

                  // ── Secondary text actions ───────────────────────────────
                  _SecondaryActions(
                    onRegister: () => context.push('/register'),
                    onManpowerLogin: () => context.push('/manpower-login'),
                  ),
                  const SizedBox(height: 20),

                  // ── Footer ───────────────────────────────────────────────
                  _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeHeader extends StatelessWidget {
  final double screenWidth;
  const _WelcomeHeader({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final fontSize = screenWidth * 0.07;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Welcome to ",
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
        ),
        Text(
          "VAYUXI",
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            letterSpacing: screenWidth * 0.002,
          ),
        ),
      ],
    );
  }
}

class _TaglineText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        style: TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.5),
        children: [
          TextSpan(text: "Congrats! There are "),
          TextSpan(
            text: "70 Million+",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text:
            " people working in Construction sector, you are one step ahead of them",
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
    );
  }
}

/// Email input with a lightweight inline "Send" text-button below the field.
class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSendingOtp;
  final bool isEmailValid;
  final bool hasInput;
  final VoidCallback onSend;
  final ValueChanged<String> onChanged;

  const _EmailField({
    required this.controller,
    required this.isSendingOtp,
    required this.isEmailValid,
    required this.hasInput,
    required this.onSend,
    required this.onChanged,
  });

  bool get _canSend => isEmailValid && !isSendingOtp;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: "xyz@gmail.com",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
              const BorderSide(color: Color(0xFF218AE6), width: 1.5),
            ),
            // Show error border only when user has typed something invalid
            errorText:
            hasInput && !isEmailValid ? "Invalid email format" : null,
            errorStyle: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(height: 6),

        // Lightweight "Send OTP" text action, right-aligned under the field
        GestureDetector(
          onTap: _canSend ? onSend : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: isSendingOtp
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: Color(0xFF218AE6),
              ),
            )
                : Text(
              "Send OTP",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _canSend
                    ? const Color(0xFF218AE6)
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Inline "Didn't get the code? Resend" row with optional cooldown timer.
class _ResendRow extends StatelessWidget {
  final int cooldown;
  final VoidCallback? onResend;

  const _ResendRow({required this.cooldown, this.onResend});

  @override
  Widget build(BuildContext context) {
    final canResend = cooldown == 0 && onResend != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "Didn't get the code? ",
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: canResend ? onResend : null,
          child: Text(
            canResend ? "Resend" : "Resend in ${cooldown}s",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: canResend ? const Color(0xFF218AE6) : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _LoginButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF218AE6),
          disabledBackgroundColor: Colors.grey.shade200,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          "Login",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Secondary actions rendered as minimal inline text — no large buttons.
class _SecondaryActions extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onManpowerLogin;

  const _SecondaryActions({
    required this.onRegister,
    required this.onManpowerLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Register
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            GestureDetector(
              onTap: onRegister,
              child: const Text(
                "Register",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF218AE6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Manpower login
        GestureDetector(
          onTap: onManpowerLogin,
          child: Text(
            "Login as Manpower",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              decoration: TextDecoration.underline,
              decorationColor: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "By continuing, you're agreeing to our Terms of Service and Privacy Policy.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 4),
        Text(
          "© 2026 VAYUXI. All rights reserved.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}