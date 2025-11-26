import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utlis/widgets/buttons.dart';
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
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String sendOtpError = "";
  String otpError = "";
  bool otpVerified = false;
  bool otpVisible = false;
  bool _isDisposed = false;

  final List<String> carouselImages = [
    'assets/images/Untitled design (11).png',
    'assets/images/WhatsApp Image 2025-11-03 at 23.45.34_52e9b781.jpg',
    'assets/images/WhatsApp Image 2025-11-04 at 00.07.16_6b118cd8.jpg'
  ];

  bool get isValidEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailController.text);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _pageController.hasClients && !_isDisposed) {
        int nextPage = _currentPage + 1;
        if (nextPage >= carouselImages.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  // Safe state update method
  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!isValidEmail) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter a valid email.")),
        );
      }
      return;
    }
    try {
      _safeSetState(() {
        sendOtpError = "";
      });
      await AuthAPI.generateLoginOtp(emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP sent successfully!")),
        );
      }
      _safeSetState(() {
        otpVisible = true;
      });
    } catch (e) {
      _safeSetState(() {
        sendOtpError = e.toString();
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = otpController.text;
    if (otp.length != 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a 6-digit OTP.")),
        );
      }
      return;
    }

    try {
      _safeSetState(() {
        otpError = "";
        otpVerified = false;
      });

      await ref
          .read(authProvider.notifier)
          .loginWithOtp(emailController.text, otp);

      // Check if widget is still mounted before proceeding
      if (!mounted || _isDisposed) return;

      final authState = ref.read(authProvider);

      if (authState.isLoggedIn) {
        _safeSetState(() => otpVerified = true);

        // Use a small delay to ensure state is properly updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isDisposed) {
            context.go(Routes.workCategory);
          }
        });
      } else {
        _safeSetState(() {
          otpError = authState.errorMessage ?? "Invalid OTP";
        });
      }
    } catch (e) {
      _safeSetState(() {
        otpError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Gemini_Generated_Image_pi2r7npi2r7npi2r.png',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcATop,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // --- Carousel Images Section ---
                  Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: carouselImages.length,
                          onPageChanged: (int page) {
                            _safeSetState(() {
                              _currentPage = page;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  carouselImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Dot indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          carouselImages.length,
                              (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? const Color(0xFF007BFF)
                                  : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFF007BFF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text.rich(
                        TextSpan(
                          text: 'Welcome to ',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: 'VAYUXI',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF007BFF),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Congrats there! 70 Million people working in Construction sector, you are one step ahead of them",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- Email Section ---
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: "xyz@gmail.com",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: sendOtpError.isNotEmpty
                                ? sendOtpError
                                : null,
                          ),
                          onChanged: (_) => _safeSetState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Verify",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- OTP Section (Visible only after clicking Verify) ---
                  if (otpVisible) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Phone Number OTP",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // FIXED: Properly constrained PinCodeTextField
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: constraints.maxWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: PinCodeTextField(
                            length: 6,
                            appContext: context,
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(8),
                              fieldHeight: 50,
                              fieldWidth: 45,
                              activeFillColor: Colors.white.withOpacity(0.9),
                              activeColor: const Color(0xFF007BFF),
                              selectedColor: const Color(0xFF007BFF),
                              inactiveColor: Colors.grey.shade300,
                              inactiveFillColor: Colors.grey.shade50.withOpacity(0.9),
                              selectedFillColor: Colors.white.withOpacity(0.9),
                            ),
                            animationDuration: const Duration(milliseconds: 300),
                            enableActiveFill: true,
                            onChanged: (_) {},
                            // Added explicit configuration to prevent layout issues
                            textStyle: const TextStyle(fontSize: 18),
                            backgroundColor: Colors.transparent,
                            enablePinAutofill: true,
                            autoDisposeControllers: false,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    if (otpError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          otpError,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),

                    if (otpVerified)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "OTP Verified",
                          style: const TextStyle(color: Colors.green, fontSize: 14),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // FIXED: Properly constrained buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF218AE6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: authState.isLoading
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
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: RoundedButton(
                              text: "Register",
                              color: const Color(0xFF007BFF),
                              textColor: Colors.white,
                              onPressed: () {
                                context.push('/register');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- Footer ---
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}