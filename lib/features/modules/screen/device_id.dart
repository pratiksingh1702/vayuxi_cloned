import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio.dart';
import '../../auth/service/auth_client.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
class DeviceOtpScreen extends StatefulWidget {
  const DeviceOtpScreen({super.key});

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

      // Save device ID to cookies
      await DioClient.setDeviceIdCookie(newDeviceId);


      setState(() {
        deviceId = newDeviceId;
        message = "Device Verified! Device ID saved to cookies.";
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
      appBar: AppBar(
        title: const Text("Device OTP Verification"),
      ),
      body: SingleChildScrollView( // Added to prevent overflow
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: deviceController,
              decoration: const InputDecoration(
                labelText: "Device Name / Device Identifier",
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : generateOtp,
              child: const Text("Generate Device OTP"),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: otpController,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : verifyOtp,
              child: const Text("Verify OTP"),
            ),

            const SizedBox(height: 30),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: message!.contains("Failed") ? Colors.red : Colors.blue,
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
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Your Device ID:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      deviceId!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "✅ Device ID has been saved to cookies and will be sent with all future requests",
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}