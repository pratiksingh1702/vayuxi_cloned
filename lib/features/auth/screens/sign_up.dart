import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _acceptedTerms = false;
  bool _isVerifyingOtp = false;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ─── Cooldown ─────────────────────────────────────────────────────────────

  void _startResendCooldown() {
    setState(() => _resendCooldown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendCooldown = 0);
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  // ─── OTP ──────────────────────────────────────────────────────────────────

  Future<void> _sendOtp({bool isResend = false}) async {
    final email = emailController.text.trim();
    if (_validateEmail(email) != null) {
      _showErrorSnackBar("Please enter a valid email address");
      return;
    }

    if (!isResend) setState(() => _isSendingOtp = true);

    try {
      await ref.read(authProvider.notifier).generateEmailOtp(email);
      _startResendCooldown();
      if (!isResend) _showOtpDialog();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          e.toString().contains('timeout')
              ? "Network timeout. Please check your connection"
              : "Failed to send OTP. Please try again",
        );
      }
    } finally {
      if (mounted && !isResend) setState(() => _isSendingOtp = false);
    }
  }

  void _showOtpDialog() {
    final otpFieldController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canResend = _resendCooldown == 0;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    "Verify your email",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "We sent a 4-digit code to ${emailController.text.trim()}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // OTP input — 4 digits
                  PinCodeTextField(
                    length: 4,
                    appContext: context,
                    controller: otpFieldController,
                    keyboardType: TextInputType.number,
                    enableActiveFill: true,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 52,
                      fieldWidth: 52,
                      activeFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      activeColor: Colors.black,
                      inactiveColor: Colors.black,
                      selectedColor: Colors.black,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),

                  // Resend row
                  StatefulBuilder(
                    builder: (_, setResendState) {
                      return Row(
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          GestureDetector(
                            onTap: canResend
                                ? () async {
                              await _sendOtp(isResend: true);
                              setDialogState(() {});
                            }
                                : null,
                            child: Text(
                              canResend
                                  ? "Resend"
                                  : "Resend in ${_resendCooldown}s",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: canResend
                                    ? const Color(0xFF218AE6)
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: TextButton(
                          onPressed: _isVerifyingOtp
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                          ),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Verify
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_isVerifyingOtp ||
                              otpFieldController.text.length != 4)
                              ? null
                              : () async {
                            setDialogState(() => _isVerifyingOtp = true);
                            try {
                              await ref
                                  .read(authProvider.notifier)
                                  .verifyEmailOtp(
                                emailController.text.trim(),
                                otpFieldController.text.trim(),
                              );
                              if (mounted) {
                                setState(() => _isEmailVerified = true);
                                Navigator.of(context).pop();
                                _showSuccessSnackBar(
                                    "Email verified successfully!");
                              }
                            } catch (e) {
                              if (mounted) {
                                _showErrorSnackBar(
                                  e.toString().contains('Invalid OTP')
                                      ? "Invalid OTP. Please try again"
                                      : "Verification failed. Please try again",
                                );
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(
                                        () => _isVerifyingOtp = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF218AE6),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isVerifyingOtp
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            "Verify",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Registration ─────────────────────────────────────────────────────────

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEmailVerified) {
      _showErrorSnackBar("Please verify your email before registering");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registrationData = {
        "fullName": fullNameController.text.trim(),
        "phoneNumber": phoneController.text
            .trim()
            .replaceAll(RegExp(r'[^0-9]'), ''),
        "email": emailController.text.trim(),
      };

      await ref.read(authProvider.notifier).register(registrationData);

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Feedback helpers ─────────────────────────────────────────────────────

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Account created!"),
        content: const Text("Your account has been created successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Create account",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Subheader ─────────────────────────────────────────────
                Text(
                  "Join 70 Million+ construction professionals",
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Full Name ─────────────────────────────────────────────
                _FormField(
                  label: "Full Name",
                  required: true,
                  child: _buildInput(
                    controller: fullNameController,
                    hint: "John Doe",
                    validator: (v) => _validateRequired(v, 'Full Name'),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Phone ─────────────────────────────────────────────────
                _FormField(
                  label: "Phone Number",
                  required: true,
                  child: PhoneInputField(
                    controller: phoneController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  )
                ),
                const SizedBox(height: 20),

                // ── Email ─────────────────────────────────────────────────
                _FormField(
                  label: "Email Address",
                  required: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildInput(
                        controller: emailController,
                        hint: "you@example.com",
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        onChanged: (_) => setState(() {}),
                        readOnly: _isEmailVerified,
                      ),
                      const SizedBox(height: 6),
                      _EmailVerifyAction(
                        isVerified: _isEmailVerified,
                        isSending: _isSendingOtp,
                        canSend: !_isEmailVerified &&
                            _validateEmail(emailController.text) == null,
                        onSend: () => _sendOtp(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Terms ─────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _acceptedTerms,
                        activeColor: const Color(0xFF218AE6),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (v) =>
                            setState(() => _acceptedTerms = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/terms'),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 13, color: Colors.black54),
                            children: [
                              TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Terms & Conditions",
                                style: TextStyle(
                                  color: Color(0xFF218AE6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Register CTA ──────────────────────────────────────────
                _RegisterButton(
                  isLoading: _isLoading,
                  isEnabled: _isEmailVerified && _acceptedTerms && !_isLoading,
                  onPressed: _handleRegistration,
                ),

                // Email not verified hint
                if (!_isEmailVerified) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Verify your email address to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Already have account ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                          fontSize: 13.5, color: Colors.grey.shade500),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF218AE6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Footer ────────────────────────────────────────────────
                Text(
                  "By continuing, you're agreeing to our Terms of Service and Privacy Policy.\n© 2026 VAYUXI. All rights reserved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade400, height: 1.6),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shared input builder — white background, black border.
  Widget _buildInput({
    required TextEditingController controller,
    String hint = "",
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 14.5, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a field with a label. Red asterisk for required fields.
class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _FormField({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Lightweight email verify action — text link style.
class _EmailVerifyAction extends StatelessWidget {
  final bool isVerified;
  final bool isSending;
  final bool canSend;
  final VoidCallback onSend;

  const _EmailVerifyAction({
    required this.isVerified,
    required this.isSending,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    if (isVerified) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 14, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            "Email verified",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.green.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: canSend && !isSending ? onSend : null,
      child: isSending
          ? const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          color: Color(0xFF218AE6),
        ),
      )
          : Text(
        "Send verification code",
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: canSend
              ? const Color(0xFF218AE6)
              : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Primary register button with clear disabled state.
class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _RegisterButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF218AE6),
          disabledBackgroundColor: Colors.grey.shade100,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            : Text(
          "Create Account",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}