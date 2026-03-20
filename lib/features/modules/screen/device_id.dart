import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/api/dio.dart';
import '../../auth/service/auth_client.dart';

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

  // ─── API calls (unchanged) ────────────────────────────────────────────────

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

      final targetTabIndex =
      widget.redirectExtraData?['targetTabIndex'] as int?;

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

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        message = "Invalid OTP. Please try again.";
        isSuccess = false;
      });
    }

    setState(() => loading = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Icon ────────────────────────────────────────────────
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

                    const SizedBox(height: 20),

                    // ── Title ───────────────────────────────────────────────
                    Text(
                      otpSent
                          ? "Enter Verification Code"
                          : "Verify Your Device",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Subtitle ────────────────────────────────────────────
                    Text(
                      otpSent
                          ? "We've sent a 6-digit code to your registered email"
                          : "A quick one-time step to confirm this is your device",
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // ── Why section (only before OTP is sent) ───────────────
                    if (!otpSent) _WhySection(),

                    // ── OTP Input ───────────────────────────────────────────
                    if (otpSent) ...[
                      const SizedBox(height: 16),
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

                      const SizedBox(height: 12),

                      // ── Resend — inline text style ───────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          GestureDetector(
                            onTap: loading ? null : generateOtp,
                            child: Text(
                              "Resend",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: loading
                                    ? Colors.grey[400]
                                    : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Feedback message ────────────────────────────────────
                    if (message != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? Colors.green[50]
                              : Colors.red[50],
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
                              isSuccess
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: isSuccess
                                  ? Colors.green[700]
                                  : Colors.red[700],
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

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA (unchanged) ───────────────────────────────────
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
                  onPressed: loading ? null : (otpSent ? verifyOtp : generateOtp),
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
                    otpSent
                        ? "Verify Code"
                        : "Send Verification Code",
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

// ─────────────────────────────────────────────────────────────────────────────
// Why Section — shown only before OTP is sent
// ─────────────────────────────────────────────────────────────────────────────

class _WhySection extends StatelessWidget {
  const _WhySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                "Why is this required?",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Explanation
          Text(
            "VAYUXI is used by supervisors and site managers to handle teams, reports, and project data. "
                "Device verification makes sure only authorised people can access this information — "
                "even if someone else installs the app.",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.blue[900],
              height: 1.55,
            ),
          ),

          const SizedBox(height: 12),

          // Benefit bullets
          _BulletPoint(
            icon: Icons.lock_outline_rounded,
            text: "Keeps your site data accessible only to you",
          ),
          const SizedBox(height: 6),
          _BulletPoint(
            icon: Icons.block_rounded,
            text: "Stops unauthorised changes or misuse",
          ),
          const SizedBox(height: 6),
          _BulletPoint(
            icon: Icons.devices_rounded,
            text: "Ties your account to this device securely",
          ),

          const SizedBox(height: 14),

          // Reassurance line
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_outlined,
                  size: 14, color: Colors.green[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Your data is safe. This verification happens only once per device.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.blue[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.blue[900],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}