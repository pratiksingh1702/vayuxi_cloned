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

  const DeviceOtpScreen({super.key, this.redirectRoute});

  @override
  State<DeviceOtpScreen> createState() => _DeviceOtpScreenState();
}

class _DeviceOtpScreenState extends State<DeviceOtpScreen> {
  final TextEditingController deviceController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool loading = false;
  String? deviceId;
  String? message;

  Future<void> generateOtp() async {
    setState(() {
      loading = true;
      message = null;
    });

    try {
      final res = await AuthAPI.generateDeviceOtp();

      setState(() {
        message = res["message"] ?? "OTP sent!";
      });
    } catch (e) {
      setState(() {
        message = "Failed: $e";
      });
    }

    setState(() => loading = false);
  }

  Future<void> verifyOtp() async {
    setState(() {
      loading = true;
      message = null;
      deviceId = null;
    });

    try {
      final res = await AuthAPI.verifyDeviceOtp({
        "otp": otpController.text.trim(),
      });

      final String newDeviceId = res["deviceId"]?.toString() ?? '';

      // Save device ID to cookies (your existing logic)
      await DioClient.setDeviceIdCookie(newDeviceId);

      // ALSO save deviceId to SharedPreferences (required)
      await DevicePrefs.saveDeviceId(newDeviceId);
      if (!mounted) return;

      // 🔥 If redirect route exists → go there directly
      if (widget.redirectRoute != null) {
        context.pushReplacement(widget.redirectRoute!);
        return;
      }

      // Default fallback
      Navigator.pop(context);

      setState(() {
        deviceId = newDeviceId;
        message = "Device Verified! Saved to cookies & SharedPreferences.";
      });
    } catch (e) {
      setState(() {
        message = "Verification failed: $e";
      });
    }

    setState(() => loading = false);
  }

  // Future<void> _saveDeviceIdToCookie(String deviceId) async {
  //   try {
  //     final dio = Dio();
  //     final cookieJar = CookieJar();
  //
  //     // Create device ID cookie
  //     final deviceCookie = Cookie('deviceId', deviceId)
  //       ..path = '/'
  //       ..maxAge = 365 * 24 * 60 * 60 // 1 year
  //       ..httpOnly = false
  //       ..secure = true;
  //
  //     // Save to cookie jar
  //     await cookieJar.saveFromResponse(
  //       Uri.parse("https://be-vayuxi-chi.vercel.app"),
  //       [deviceCookie],
  //     );
  //
  //     print("✅ Device ID saved to cookie: $deviceId");
  //   } catch (e) {
  //     print("❌ Failed to save device ID to cookie: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Device OTP Verification")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Generate OTP Button ---
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: loading ? null : generateOtp,
                icon: loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_open),
                label: const Text("Generate Device OTP"),
              ),
            ),

            const SizedBox(height: 30),

            // --- OTP Card ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter OTP",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: constraints.maxWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: PinCodeTextField(
                            length: 6,
                            appContext: context,
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            cursorColor: Colors.black,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),

                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 55,
                              fieldWidth: MediaQuery.of(context).size.width / 9, // FIXED
                              activeColor: Colors.blue,
                              selectedColor: Colors.blue,
                              inactiveColor: Colors.grey.shade400,
                              activeFillColor: Colors.white,
                              selectedFillColor: Colors.white,
                              inactiveFillColor: Colors.grey.shade200,
                              borderWidth: 1.4,
                            ),


                            enableActiveFill: true,
                            animationDuration: const Duration(
                              milliseconds: 200,
                            ),
                            onChanged: (_) {},
                            autoDisposeControllers: false,
                            backgroundColor: Colors.transparent,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : verifyOtp,
                        child: loading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Verify OTP"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (message != null)
              Center(
                child: Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains("Failed")
                        ? Colors.red
                        : Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (deviceId != null)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Your Device ID",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deviceId!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Device ID saved to cookies & will be sent with future requests",
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      textAlign: TextAlign.center,
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
