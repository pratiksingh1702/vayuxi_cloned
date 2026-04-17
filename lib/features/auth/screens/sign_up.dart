import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/routes.dart';
import '../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../provider/auth_provider.dart';
import '../service/auth_client.dart';

enum _Phase { phoneOtp, completeProfile }

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
  final companyController = TextEditingController();
  final otpController = TextEditingController();

  _Phase _phase = _Phase.phoneOtp;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _acceptedTerms = false;
  bool _isVerifyingOtp = false;
  bool _otpVisible = false;

  int _resendCooldown = 0;
  Timer? _resendTimer;

  void _handlePhoneInputChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_handlePhoneInputChanged);
    _restorePartialAuthFlow();
  }

  @override
  void dispose() {
    phoneController.removeListener(_handlePhoneInputChanged);
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    companyController.dispose();
    otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _restorePartialAuthFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final role = prefs.getString('auth_role');
    final pendingPhone = prefs.getString('pending_phone_number') ?? '';

    if (!mounted) return;

    if (token != null && token.isNotEmpty && role != 'user') {
      setState(() {
        phoneController.text = pendingPhone;
      });
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
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

  String _normalizedPhone() {
    return phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
  }

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

  bool get _isPhoneValid => RegExp(r'^[0-9]{10}$').hasMatch(_normalizedPhone());

  Future<void> _sendOtp({bool isResend = false}) async {
    if (!_isPhoneValid) {
      _showErrorSnackBar('Please enter a valid 10-digit phone number');
      return;
    }

    if (!isResend) setState(() => _isSendingOtp = true);

    try {
      final res = await AuthAPI.sendPhoneOtp(_normalizedPhone());
      setState(() => _otpVisible = true);
      _startResendCooldown();

      final isExistingUser = res['isExistingUser'] == true;
      if (isExistingUser) {
        _showSuccessSnackBar(
          'OTP sent. This number already exists. You can login after verification.',
        );
      } else {
        _showSuccessSnackBar('OTP sent successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          e.toString().contains('timeout')
              ? 'Network timeout. Please check your connection'
              : e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted && !isResend) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyPhoneOtp() async {
    if (otpController.text.trim().length != 4) {
      _showErrorSnackBar('Please enter a valid 4-digit OTP');
      return;
    }

    setState(() => _isVerifyingOtp = true);
    var shouldResetVerifyingState = true;

    try {
      final res = await ref
          .read(authProvider.notifier)
          .loginWithPhoneOtp(_normalizedPhone(), otpController.text.trim());

      final isNewUser = res['isNewUser'] == true;
      if (!mounted) return;

      if (isNewUser) {
        _showSuccessSnackBar('Signup complete. Please complete your profile.');
        shouldResetVerifyingState = false;
        context.go(Routes.workCategory);
        return;
      } else {
        _showSuccessSnackBar('Logged in successfully.');
        shouldResetVerifyingState = false;
        context.go(Routes.workCategory);
        return;
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          e.toString().contains('Invalid OTP')
              ? 'Invalid OTP. Please try again'
              : e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted && shouldResetVerifyingState) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      _showErrorSnackBar('Please accept Terms & Conditions to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).completeProfile(
            fullName: fullNameController.text.trim(),
            email: emailController.text.trim(),
            companyName: companyController.text.trim().isEmpty
                ? null
                : companyController.text.trim(),
          );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Account created!'),
        content:
            const Text('Your profile is complete and your account is ready.'),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child:
                Text('Continue', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _phase == _Phase.phoneOtp ? 'Create account' : 'Complete profile',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
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
                Text(
                  _phase == _Phase.phoneOtp
                      ? 'Join 70 Million+ construction professionals'
                      : 'Almost done. Add profile details to continue.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                if (_phase == _Phase.phoneOtp) ...[
                  _FormField(
                    label: 'Phone Number',
                    required: true,
                    child: PhoneInputField(
                      controller: phoneController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SendOtpAction(
                    isSending: _isSendingOtp,
                    canSend: _isPhoneValid,
                    onSend: _sendOtp,
                  ),
                  const SizedBox(height: 20),
                  if (_otpVisible) ...[
                    _FormField(
                      label: 'One-Time Password',
                      required: true,
                      child: PinCodeTextField(
                        length: 4,
                        autoDisposeControllers: false,
                        appContext: context,
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        enableActiveFill: true,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(8),
                          fieldHeight: 52,
                          fieldWidth: 52,
                          activeFillColor: colorScheme.surface,
                          inactiveFillColor: colorScheme.surface,
                          selectedFillColor: colorScheme.surface,
                          activeColor: colorScheme.primary,
                          inactiveColor: colorScheme.outline,
                          selectedColor: colorScheme.primary,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendCooldown == 0
                              ? () => _sendOtp(isResend: true)
                              : null,
                          child: Text(
                            _resendCooldown == 0
                                ? 'Resend'
                                : 'Resend in ${_resendCooldown}s',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _resendCooldown == 0
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _RegisterButton(
                      isLoading: _isVerifyingOtp,
                      isEnabled: !_isVerifyingOtp &&
                          otpController.text.trim().length == 4,
                      onPressed: _verifyPhoneOtp,
                      label: 'Verify OTP',
                    ),
                  ],
                ],
                if (_phase == _Phase.completeProfile) ...[
                  _FormField(
                    label: 'Phone Number',
                    required: true,
                    child: _buildInput(
                      controller: phoneController,
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormField(
                    label: 'Full Name',
                    required: true,
                    child: _buildInput(
                      controller: fullNameController,
                      hint: 'John Doe',
                      validator: (v) => _validateRequired(v, 'Full Name'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormField(
                    label: 'Email Address',
                    required: true,
                    child: _buildInput(
                      controller: emailController,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FormField(
                    label: 'Company Name',
                    child: _buildInput(
                      controller: companyController,
                      hint: 'Your Company (optional)',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _acceptedTerms,
                          activeColor: colorScheme.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
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
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: colorScheme.primary,
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
                  _RegisterButton(
                    isLoading: _isLoading,
                    isEnabled: _acceptedTerms && !_isLoading,
                    onPressed: _handleRegistration,
                    label: 'Create Account',
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "By continuing, you're agreeing to our Terms of Service and Privacy Policy.\n(c) 2026 VAYUXI. All rights reserved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.outline,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      style: TextStyle(fontSize: 14.5, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                const TextSpan(
                  text: ' *',
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

class _SendOtpAction extends StatelessWidget {
  final bool isSending;
  final bool canSend;
  final Future<void> Function({bool isResend}) onSend;

  const _SendOtpAction({
    required this.isSending,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: canSend && !isSending ? () => onSend() : null,
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
                'Send OTP',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: canSend
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;
  final String label;

  const _RegisterButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
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
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
