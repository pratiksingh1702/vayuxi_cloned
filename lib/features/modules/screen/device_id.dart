import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/api/dio.dart';
import '../../auth/service/auth_client.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'device_id_helper.dart';

class DeviceOtpScreen extends StatefulWidget {
  final String? redirectRoute;
  final Map<String, dynamic>? redirectExtraData;

  const DeviceOtpScreen({
    super.key,
    this.redirectRoute,
    this.redirectExtraData,
  });

  @override
  State<DeviceOtpScreen> createState() => _DeviceOtpScreenState();
}

class _DeviceOtpScreenState extends State<DeviceOtpScreen> {
  final TextEditingController otpController = TextEditingController();

  bool loading = false;
  bool otpSent = false;
  String? message;
  bool isSuccess = false;

  Future<void> generateOtp() async {
    setState(() {
      loading = true;
      message = null;
      isSuccess = false;
    });

    try {
      final res = await AuthAPI.generateDeviceOtp();

      setState(() {
        otpSent = true;
        message = res["message"] ?? "OTP sent to your email";
        isSuccess = true;
      });
    } catch (e) {
      setState(() {
        message = "Failed to send OTP. Please try again.";
        isSuccess = false;
      });
    }

    setState(() => loading = false);
  }

  Future<void> verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      setState(() {
        message = "Please enter a valid 6-digit OTP";
        isSuccess = false;
      });
      return;
    }

    setState(() {
      loading = true;
      message = null;
      isSuccess = false;
    });

    try {
      final res = await AuthAPI.verifyDeviceOtp({
        "otp": otpController.text.trim(),
      });

      final String newDeviceId = res["deviceId"]?.toString() ?? '';

      await DioClient.setDeviceIdCookie(newDeviceId);
      await DevicePrefs.saveDeviceId(newDeviceId);

      if (!mounted) return;

      final targetTabIndex = widget.redirectExtraData?['targetTabIndex'] as int?;

      if (targetTabIndex != null) {
        Navigator.pop(context, targetTabIndex);
        return;
      }

      if (widget.redirectRoute != null) {
        if (widget.redirectExtraData != null) {
          context.pushReplacement(
            widget.redirectRoute!,
            extra: widget.redirectExtraData,
          );
        } else {
          context.pushReplacement(widget.redirectRoute!);
        }
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        message = "Invalid OTP. Please try again.";
        isSuccess = false;
      });
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Device Verification"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        otpSent ? Icons.mark_email_read : Icons.security,
                        size: 64,
                        color: Colors.blue[700],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      otpSent ? "Enter Verification Code" : "Verify Your Device",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      otpSent
                          ? "We've sent a 6-digit code to your email"
                          : "Tap the button below to receive a verification code",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // OTP Input (only show after OTP is sent)
                    if (otpSent) ...[
                      PinCodeTextField(
                        length: 6,
                        appContext: context,
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        cursorColor: Colors.blue[700],
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 56,
                          fieldWidth: 48,
                          activeColor: Colors.blue[700],
                          selectedColor: Colors.blue[700],
                          inactiveColor: Colors.grey[300],
                          activeFillColor: Colors.white,
                          selectedFillColor: Colors.blue[50],
                          inactiveFillColor: Colors.white,
                          borderWidth: 2,
                        ),
                        enableActiveFill: true,
                        animationDuration: const Duration(milliseconds: 200),
                        onChanged: (_) {},
                        autoDisposeControllers: false,
                        backgroundColor: Colors.transparent,
                      ),

                      const SizedBox(height: 24),

                      // Resend OTP
                      TextButton.icon(
                        onPressed: loading ? null : generateOtp,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("Didn't receive code? Resend"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Message
                    if (message != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSuccess ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSuccess
                                ? Colors.green[200]!
                                : Colors.red[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle : Icons.error,
                              color: isSuccess ? Colors.green[700] : Colors.red[700],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                message!,
                                style: TextStyle(
                                  color: isSuccess
                                      ? Colors.green[900]
                                      : Colors.red[900],
                                  fontSize: 14,
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

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: loading
                      ? null
                      : (otpSent ? verifyOtp : generateOtp),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    otpSent ? "Verify Code" : "Send Verification Code",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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