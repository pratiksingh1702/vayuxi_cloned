import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/api/requestQueue.dart';
import 'package:untitled2/core/api/requestQueueModel.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:untitled2/core/api/sync_job.dart';
import 'package:untitled2/features/noti_system/updates/domain/services/notification_ingestion_service.dart';

import '../utlis/common_functions.dart';
import 'network_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DioClient {
  static ProviderContainer? syncRef;

  static const String healthUrl =
      "https://be-vayuxi-chi.vercel.app/api/health";

  static const String _startTimeKey = 'startTimeMs';
  static const String _forcedOfflineKey = 'forcedOffline';
  static const String _bypassOfflineKey = 'bypassOffline';
  static const String _skipQueueKey = 'skipQueue';

  static late CookieJar cookieJar;
  static final Dio dio = Dio(BaseOptions(
    baseUrl: "https://be-vayuxi-chi.vercel.app/api/v1",
    connectTimeout: const Duration(seconds: 100000),
    receiveTimeout: const Duration(seconds: 100000),
  ));
  static final dioV2 = Dio(BaseOptions(
    baseUrl: "https://be-vayuxi-chi.vercel.app/api/v2",
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static Future<void> init() async {
    cookieJar = PersistCookieJar(
      storage: FileStorage(await _cookiePath()),
    );

    // Add cookie manager to both instances
    dio.interceptors.add(CookieManager(cookieJar));
    dioV2.interceptors.add(CookieManager(cookieJar));

    Future<void> debugAllCookies() async {
      print("🔍 DEBUG - All Cookies:");
      try {
        final cookies = await cookieJar.loadForRequest(
            Uri.parse("https://be-vayuxi-chi.vercel.app/api/v1"));
        if (cookies.isEmpty) {
          print("   No cookies stored at all!");
        } else {
          for (final cookie in cookies) {
            print("   🍪 ${cookie.name}=${cookie.value}");
          }
        }
      } catch (e) {
        print("   Error: $e");
      }
    }

    Map<String, dynamic> _safeJson(Map data) {
      final result = <String, dynamic>{};

      data.forEach((key, value) {
        if (value is String || value is num || value is bool || value == null) {
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

    void recordLatency(Duration latency) {
      final ref = syncRef;
      if (ref == null) return;
      ref.read(networkModeProvider.notifier).recordLatency(latency);
    }

    void recordNetworkError(String reason) {
      final ref = syncRef;
      if (ref == null) return;
      ref.read(networkModeProvider.notifier).recordNetworkError(reason);
    }

    // Create interceptor wrapper
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) async {
        final bypassOffline = options.extra[_bypassOfflineKey] == true;
        final networkState = syncRef?.read(networkModeProvider);

        if (networkState?.isOffline == true && !bypassOffline) {
          options.extra[_forcedOfflineKey] = true;
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              error: 'Offline mode enabled',
            ),
          );
        }

        options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          print(token);
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Debug cookies including device ID
        await debugAllCookies();

        print("🍪 Cookies being sent:");
        final cookies = await cookieJar.loadForRequest(options.uri);

        print("➡️ Sending request: ${options.method} ${options.uri}");

        // Check if device ID cookie exists
        final deviceIdCookie = cookies.firstWhere(
          (cookie) => cookie.name == 'deviceId',
          orElse: () => Cookie('', ''),
        );

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
              print(
                  "     ${file.key}: ${file.value.filename} (${file.value.length} bytes)");
            }
          }
        } else if (options.data != null) {
          print("   Body: ${options.data}");
        }

        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final requestOptions = e.requestOptions;
        final extra = requestOptions.extra;
        final forcedOffline = extra[_forcedOfflineKey] == true;
        final skipQueue = extra[_skipQueueKey] == true;
        final startMs = extra[_startTimeKey] as int?;
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        print(
            "❌ Request failed: ${requestOptions.method} ${requestOptions.uri}");
        print("   Error type: ${e.type}");
        print("   Error: ${e.error}");

        if (!forcedOffline && startMs != null && e.response != null) {
          recordLatency(Duration(milliseconds: nowMs - startMs));
        }

        if (!forcedOffline) {
          if (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.unknown) {
            recordNetworkError(e.type.toString());
          }
        }

        if (skipQueue) {
          return handler.next(e);
        }

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
          jsonData = _safeJson(requestOptions.data);
        } else if (requestOptions.data is List) {
          jsonData = {"__isList": true, "data": requestOptions.data};
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
          files: requestOptions.data is FormData
              ? _extractFiles(requestOptions.data)
              : null,
          contentType: requestOptions.data is FormData ? "form" : "json",
        );

        // ✅ queue ONLY if network problem
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.unknown) {
          print("QUEUE RAW:");
          print(queuedReq.toJson());

          await RequestQueue.add(queuedReq);
          await NotificationIngestionService.persistQueuedRequest(queuedReq);
          print(DioClient.syncRef);

          final label = buildTaskLabel(
            requestOptions.method,
            requestOptions.path,
          );

          syncRef
              ?.read(syncJobsProvider.notifier)
              .addQueued(queuedReq.id, label);

          print("🔥 PROVIDER ADD CALLED");

          print("📌 Queued: ${queuedReq.path}");
          print(
              "📌 Saved request to queue: ${queuedReq.method} ${queuedReq.path}");
        } else {
          print("🚫 Not queued (server/client error)");
        }

        print(
            "📌 Saved request to queue: ${queuedReq.method} ${queuedReq.path}");
        if (queuedReq.data != null) print("   Saved data: ${queuedReq.data}");
        if (queuedReq.files != null)
          print("   Saved files: ${queuedReq.files}");

        return handler.next(e);
      },
      onResponse: (response, handler) {
        print(
            "✅ Response received: ${response.statusCode} ${response.requestOptions.uri}");

        final startMs = response.requestOptions.extra[_startTimeKey] as int?;
        if (startMs != null) {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          recordLatency(Duration(milliseconds: nowMs - startMs));
        }

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
    );

    // Add interceptor to both dio instances
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          // 🔥 INTERNAL LOG (keep this)
          print("❌ TECH ERROR: ${e.type}");
          print("❌ TECH DETAILS: ${e.error}");
          print("❌ TECH RESPONSE: ${e.response?.data}");

          // 🎯 USER-FRIENDLY MESSAGE ONLY
          final cleanMessage = extractBackendError(e);
          print(cleanMessage);

          // 🚫 Replace technical error with clean message
          final transformedError = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: cleanMessage,
          );

          return handler.next(transformedError);
        },
      ),
    );

// same for dioV2
    dioV2.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          final cleanMessage = extractBackendError(e);

          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: cleanMessage,
            ),
          );
        },
      ),
    );

    dio.interceptors.add(interceptor);
    dioV2.interceptors.add(interceptor);
  }

  static Future<String> _cookiePath() async {
    print("😊😊😊😊😊😊😊😊😊😊😊😊");
    final dir = await getApplicationDocumentsDirectory();
    return "${dir.path}/.cookies/";
  }

  static Future<Response<dynamic>> probe(String path) {
    return dio.get(
      path,
      options: Options(
        extra: {
          _bypassOfflineKey: true,
          _skipQueueKey: true,
        },
      ),
    );
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
      final cookies = await cookieJar
          .loadForRequest(Uri.parse("https://be-vayuxi-chi.vercel.app"));
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
