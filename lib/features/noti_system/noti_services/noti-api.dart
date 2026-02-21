import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/api/dio.dart';

class NotiApi {
  final dio = DioClient.dio;

  static const _tokenKey = "saved_fcm_token";

  Future<void> saveTokenIfNeeded(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_tokenKey);

      /// 🚫 If same → skip API
      if (oldToken == token) {
        return;
      }

      final deviceInfo = await _getDeviceInfo();

      await dio.post(
        '/notifications/save-token',
        data: {
          "fcmToken": token,
          "deviceInfo": deviceInfo,
        },
      );

      /// ✅ Save locally only after success
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print(e);
    }
  }

  Future<String> _getDeviceInfo() async {
    final devicePlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await devicePlugin.androidInfo;
      return "${android.manufacturer} ${android.model} (Android ${android.version.release})";
    } else if (Platform.isIOS) {
      final ios = await devicePlugin.iosInfo;
      return "${ios.name} ${ios.model} (iOS ${ios.systemVersion})";
    }

    return "Unknown Device";
  }
}
