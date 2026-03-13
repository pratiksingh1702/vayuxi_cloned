import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:untitled2/features/auth/screens/toc.dart';
import '../../../core/utlis/widgets/buttons.dart';
import '../../../core/utlis/widgets/custom_appBar.dart';
import '../../../core/utlis/widgets/fields/phone_number_field.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final gstinController = TextEditingController();
  final aadhaarController = TextEditingController();
  final companyController = TextEditingController();

  bool _isLoading = false;
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _acceptedTerms = false;
  bool _isVerifyingOtp = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    gstinController.dispose();
    aadhaarController.dispose();
    companyController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isEmailVerified) {
      _showErrorDialog("Please verify your email before registering");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the EXACT same field names as React Native
      final registrationData = {
        "firstName": firstNameController.text.trim(),
        "lastName": lastNameController.text.trim(),
        "phoneNumber": phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''), // Changed from "phone"
        "email": emailController.text.trim(),
        "aadhaarCard": aadhaarController.text.trim().isNotEmpty ? aadhaarController.text.trim() : null, // Changed from "aadhaar"
        "gstNumber": gstinController.text.trim().isNotEmpty ? gstinController.text.trim() : null, // Changed from "gstin"
        "company": companyController.text.trim().isNotEmpty ? companyController.text.trim() : null, // Changed from "companyName"
      };

      print("📤 REGISTRATION - Final data: $registrationData");

      await ref.read(authProvider.notifier).register(registrationData);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registration Successful"),
        content: const Text("Your account has been created successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to login screen
              Navigator.of(context).pop(); // Go back to login
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    final email = emailController.text.trim();

    if (_validateEmail(email) != null) {
      _showErrorSnackBar("Please enter a valid email address");
      return;
    }

    setState(() {
      _isSendingOtp = true;
    });

    try {
      final res= await ref.read(authProvider.notifier).generateEmailOtp(email);
      _showOtpDialog();
      print(res);

    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
            e.toString().contains('timeout')
                ? "Network timeout. Please check your connection"
                : "Failed to send OTP. Please try again"
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
      }
    }
  }

  void _showOtpDialog() {
    final otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Verify Email"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "We've sent a 6-digit OTP to your email. Please enter it below to verify your email address.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
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
                    fieldWidth: 40,
                    activeFillColor: Colors.grey[100],
                    inactiveFillColor: Colors.grey[100],
                    selectedFillColor: Colors.blue[50],
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                    selectedColor: Colors.blue,
                  ),
                  onChanged: (value) {},
                ),
                const SizedBox(height: 10),
                if (_isVerifyingOtp)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isVerifyingOtp
                    ? null
                    : () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: _isVerifyingOtp
                    ? null
                    : () async {
                  final otp = otpController.text.trim();
                  if (otp.length != 6) {
                    _showErrorSnackBar("Please enter a valid 6-digit OTP");
                    return;
                  }

                  setDialogState(() {
                    _isVerifyingOtp = true;
                  });

                  try {
                    await ref.read(authProvider.notifier).verifyEmailOtp(
                      emailController.text.trim(),
                      otp,
                    );

                    if (mounted) {
                      setState(() {
                        _isEmailVerified = true;
                      });
                      Navigator.of(context).pop();
                      _showSuccessSnackBar("Email verified successfully!");
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorSnackBar(
                        e.toString().contains('Invalid OTP')
                            ? "Invalid OTP. Please check and try again"
                            : "OTP verification failed. Please try again",
                      );
                    }
                  } finally {
                    if (mounted) {
                      setDialogState(() {
                        _isVerifyingOtp = false;
                      });
                    }
                  }
                },
                child: const Text("Verify OTP"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Register at VAYUXI"),
      backgroundColor: const Color(0xFFE9F3FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // --- Toggle Buttons for Login/Register ---
                Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        text: "Login",
                        color: Colors.blue,
                        textColor: Colors.blue,
                        isOutlined: true,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RoundedButton(
                        text: "Register",
                        color: Colors.blue,
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // --- First & Last Name ---
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        "First Name*",
                        firstNameController,
                        validator: (value) => _validateRequired(value, 'First Name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Last Name*",
                        lastNameController,
                        validator: (value) => _validateRequired(value, 'Last Name'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Phone Number ---
                PhoneInputField(
                  controller: phoneController,
                  countryCode: "+91",
                ),
                const SizedBox(height: 20),

                // --- Email with Verify Button ---
                // --- Email with Verify Button ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      "E-Mail ID*",
                      emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4), // Add some right padding
                        child: IconButton(
                          onPressed: _isSendingOtp
                              ? null
                              : _sendOtp,
                          icon: _isSendingOtp
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          )
                              : Icon(
                            _isEmailVerified ? Icons.check_circle : Icons.send,
                            color: _isEmailVerified ? Colors.green : Colors.blue,
                          ),
                          padding: const EdgeInsets.all(0), // Remove default padding
                          constraints: const BoxConstraints(), // Remove min size constraints
                        ),
                      ),
                    ),
                    if (_isEmailVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "Email verified",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- GSTIN ---
                _buildTextField(
                  "GSTIN",
                  gstinController,
                ),

                const SizedBox(height: 20),

                // --- Aadhaar ---
                _buildTextField(
                  "Aadhar Number",
                  aadhaarController,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 20),

                // --- Company Name ---
                _buildTextField("Company Name", companyController),

                const SizedBox(height: 25),


                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/terms');
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black87, fontSize: 13),
                            children: [
                              TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Terms & Conditions",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // --- Register Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isEmailVerified || !_acceptedTerms)
                        ? null
                        : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isEmailVerified && _acceptedTerms)
                          ? Colors.blue
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Register",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (!_isEmailVerified)
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Icon(Icons.info_outline, size: 16, color: Colors.white),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                if (!_isEmailVerified)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Please verify your email to register",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // --- Footer ---
                const Text(
                  "By continuing, you're agreeing to our Terms of Service and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                const Text(
                  "© 2025 VAYUXI. All rights reserved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        String? Function(String?)? validator,
        TextInputType keyboardType = TextInputType.text,
        Widget? suffixIcon, // Add suffixIcon parameter
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            hintText: "Input Text",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            suffixIcon: suffixIcon, // Use the passed suffixIcon
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}