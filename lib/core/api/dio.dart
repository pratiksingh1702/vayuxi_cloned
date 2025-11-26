import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/api/requestQueue.dart';
import 'package:untitled2/core/api/requestQueueModel.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class DioClient {
  static late CookieJar cookieJar;
  static final Dio dio = Dio(BaseOptions(
    baseUrl: "https://be-vayuxi-chi.vercel.app/api/v1",
    connectTimeout: const Duration(seconds: 100),
    receiveTimeout: const Duration(seconds: 100),
  ));

  static Future<void> init() async {
    cookieJar = PersistCookieJar(
        storage: FileStorage(await _cookiePath()),
    );

    dio.interceptors.add(CookieManager(cookieJar));

    Future<void> debugAllCookies() async {
      print("🔍 DEBUG - All Cookies:");
      try {
        final cookies = await cookieJar.loadForRequest(Uri.parse("https://be-vayuxi-chi.vercel.app/api/v1"));
        if (cookies.isEmpty) {
          print("   No cookies stored at all!");
        } else {
          for (final cookie in cookies) {
            print("   🍪 ${cookie.name}=${cookie.value}");
            print("     Domain: ${cookie.domain}");
            print("     Path: ${cookie.path}");
            print("     Secure: ${cookie.secure}");
            print("     HttpOnly: ${cookie.httpOnly}");
          }
        }
      } catch (e) {
        print("   Error: $e");
      }
    }
    Map<String, dynamic> _safeJson(Map data) {
      final result = <String, dynamic>{};

      data.forEach((key, value) {
        if (value is String ||
            value is num ||
            value is bool ||
            value == null) {
          result[key] = value;
        } else if (value is List) {
          result[key] = value.map((e) {
            if (e is String || e is num || e is bool || e == null) return e;
            if (e is Map) return _safeJson(e);
            return e.toString(); // force primitive fallback
          }).toList();
        } else if (value is Map) {
          result[key] = _safeJson(value);
        } else {
          result[key] = value.toString(); // 🚨 prevents Hive crash
        }
      });

      return result;
    }


    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Debug cookies including device ID
        await debugAllCookies();

        print("🍪 Cookies being sent:");
        final cookies = await cookieJar.loadForRequest(options.uri);
        print("   $cookies");

        print("➡️ Sending request: ${options.method} ${options.uri}");
        print("   Headers: ${options.headers}");

        // Check if device ID cookie exists
        final deviceIdCookie = cookies.firstWhere(
              (cookie) => cookie.name == 'deviceId',
          orElse: () => Cookie('', ''),
        );

        if (deviceIdCookie.value.isNotEmpty) {
          print("📱 Device ID Cookie: ${deviceIdCookie.value}");
        }

        // FIX: Properly handle FormData logging
        if (options.data is FormData) {
          final formData = options.data as FormData;
          print("   Body: FormData");
          print("   Fields:");
          for (final field in formData.fields) {
            print("     ${field.key}: ${field.value}");
          }

          // Log all files
          if (formData.files.isNotEmpty) {
            print("   Files: ${formData.files.length}");
            for (final file in formData.files) {
              print("     ${file.key}: ${file.value.filename} (${file.value.length} bytes)");
            }
          }
        } else if (options.data != null) {
          print("   Body: ${options.data}");
        }

        return handler.next(options);
      },

      onError: (DioException e, handler) async {
        final requestOptions = e.requestOptions;

        print("❌ Request failed: ${requestOptions.method} ${requestOptions.uri}");
        print("   Error type: ${e.type}");
        print("   Error: ${e.error}");

        // Prepare data for queue
        Map<String, dynamic>? jsonData;
        List<Map<String, dynamic>>? filesData;

        if (requestOptions.data is FormData) {
          print("yesssssssssssss");
          final formData = requestOptions.data as FormData;
          jsonData = {};
          filesData = [];

          // Separate fields
          formData.fields.forEach((f) {
            jsonData![f.key] = f.value;
          });

          // Store file info for later rebuild
          formData.files.forEach((f) {
            filesData!.add({
              "key": f.key,
              "filename": f.value.filename,
              "contentType": "multipart/form-data",
            });
          });
        } else if (requestOptions.data is Map<String, dynamic>) {
          // Force deep JSON serialization
          jsonData = _safeJson(requestOptions.data);
        }



        // Only queue network errors, not server errors
        List<Map<String, String>> _extractFiles(FormData formData) {
          return formData.files.map((f) {
            return {
              "key": f.key,
              "filename": f.value.filename ?? "",
              "path": "",
            };
          }).toList();
        }

        // Queue the request
        final queuedReq = QueuedRequest(
          method: requestOptions.method,
          path: requestOptions.path,
          data: jsonData,
          query: requestOptions.queryParameters,
          files: requestOptions.data is FormData ? _extractFiles(requestOptions.data) : null,
          contentType: requestOptions.data is FormData ? "form" : "json",
        );

        await RequestQueue.add(queuedReq);

        print("📌 Saved request to queue: ${queuedReq.method} ${queuedReq.path}");
        if (queuedReq.data != null) print("   Saved data: ${queuedReq.data}");
        if (queuedReq.files != null) print("   Saved files: ${queuedReq.files}");

        return handler.next(e);
      },

      onResponse: (response, handler) {
        print("✅ Response received: ${response.statusCode} ${response.requestOptions.uri}");

        // FIX: Better response logging
        if (response.data is Map) {
          final data = response.data as Map;
          print("   Data: ${data}");
          // Log specific fields you care about
          if (data.containsKey('siteName')) {
            print("   siteName: ${data['siteName']}");
          }
          if (data.containsKey('updatedAt')) {
            print("   updatedAt: ${data['updatedAt']}");
          }
        } else {
          print("   Data: ${response.data}");
        }

        return handler.next(response);
      },
    ));
  }
  static Future<String> _cookiePath() async {
    print("😊😊😊😊😊😊😊😊😊😊😊😊");
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/.cookies/";
  }

  // Helper method to manually set device ID cookie
  static Future<void> setDeviceIdCookie(String deviceId) async {
    try {
      final deviceCookie = Cookie('deviceId', deviceId)
        ..path = '/'
        ..maxAge = 365 * 24 * 60 * 60 // 1 year
        ..httpOnly = false
        ..secure = true;

      await cookieJar.saveFromResponse(
        Uri.parse("https://be-vayuxi-chi.vercel.app"),
        [deviceCookie],
      );

      print("✅ Device ID cookie set: $deviceId");
    } catch (e) {
      print("❌ Failed to set device ID cookie: $e");
    }
  }


  // Helper method to get current device ID from cookies
  static Future<String?> getDeviceId() async {
    try {
      final cookies = await cookieJar.loadForRequest(Uri.parse("https://be-vayuxi-chi.vercel.app"));
      final deviceIdCookie = cookies.firstWhere(
            (cookie) => cookie.name == 'deviceId',
        orElse: () => Cookie('', ''),
      );

      return deviceIdCookie.value.isNotEmpty ? deviceIdCookie.value : null;
    } catch (e) {
      print("❌ Failed to get device ID: $e");
      return null;
    }
  }
}