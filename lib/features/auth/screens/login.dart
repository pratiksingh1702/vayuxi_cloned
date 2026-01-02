import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/utlis/widgets/buttons.dart';
import '../../modules/screen/craosule_banner.dart';
import '../provider/auth_provider.dart';
import '../../../core/router/routes.dart';
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

  final List<String> carouselImages = [
    'assets/images/l1.webp',
    'assets/images/l2.webp',
    'assets/images/l3.webp',
  ];

  @override
  void initState() {
    super.initState();
    // No need for auto-scroll timer anymore as CarouselSlider handles it
  }

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
      _showSuccessSnackBar("OTP sent successfully!");
    } catch (e) {
      _showErrorSnackBar(
          e.toString().contains('timeout')
              ? "Network timeout. Please check your connection"
              : "Failed to send OTP. Please try again"
      );
    } finally {
      if (mounted) setState(() => isSendingOtp = false);
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      _showErrorSnackBar("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() => otpButtonLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .loginWithOtp(emailController.text.trim(), otp);

      // ❌ DO NOTHING AFTER THIS
      // AuthNotifier will:
      // - update auth state
      // - trigger subscription check
      // - open Razorpay if needed
      // - router will redirect
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar(
        e.toString().contains('Invalid OTP')
            ? "Invalid OTP. Please check and try again"
            : "OTP verification failed. Please try again",
      );
    }

    // ❌ NO finally block
    // ❌ NO setState(false)
  }


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

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Welcome to",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.07,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                        Text(
                          "VAYUXI",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            letterSpacing: MediaQuery.of(context).size.width * 0.002,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Carousel using your custom widget
                  AdBannerCarousel(
                    height: 250,
                    boxFit: BoxFit.contain,
                    imageUrls: carouselImages,
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          height: 1.4,

                        ),
                        children: const [
                          TextSpan(text: "Congrats! There are "),
                          TextSpan(
                            text: "70 Million+",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: " people working in Construction sector, you are one step ahead of them"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email Field with integrated SVG button
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "E-Mail ID*",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Email TextField with integrated SVG button
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "xyz@gmail.com",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _validateEmail() ? "Invalid email format" : null,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: isSendingOtp || _validateEmail() ? null : sendOtp,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSendingOtp || _validateEmail()
                                  ? Colors.grey
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: isSendingOtp
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),

                  // OTP Section
                  if (otpVisible) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "OTP",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    PinCodeTextField(
                      length: 6,
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
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: otpButtonLoading || otpController.text.length != 6
                          ? null
                          : verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF218AE6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: otpButtonLoading
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: RoundedButton(
                      text: "Register",
                      color: const Color(0xFF007BFF),
                      textColor: Colors.white,
                      onPressed: () => context.push('/register'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.push('/manpower-login'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.blue),
                      ),
                      child: const Text(
                        "Login as Manpower",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),

                  // Terms and Privacy Policy
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          "By continuing, you're agreeing to our Terms of Service and Privacy Policy.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "© 2025 VAYUXI. All rights reserved.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateEmail() {
    final email = emailController.text.trim();
    return email.isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }
}