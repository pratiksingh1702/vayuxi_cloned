
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';


String buildTaskLabel(String method, String path) {
  final lower = path.toLowerCase();

  String section = "data";

  if (lower.contains("dpr")) section = "DPR";
  else if (lower.contains("site")) section = "site";
  else if (lower.contains("manpower")) section = "manpower";
  else if (lower.contains("rate")) section = "rate";
  else if (lower.contains("team")) section = "team";

  switch (method.toUpperCase()) {
    case "POST":
      return "Creating $section";
    case "PUT":
    case "PATCH":
      return "Updating $section";
    case "DELETE":
      return "Deleting $section";
    case "GET":
      return "Fetching $section";
    default:
      return "Syncing $section";
  }
}


String extractBackendError(dynamic error) {
  // Unknown / non-Dio error (usually programming bugs)
  if (error is! DioException) {
    return 'Unexpected error occurred';
  }

  // Handle Dio-specific errors
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Please try again.';

    case DioExceptionType.connectionError:
      return 'No internet connection. Your data is saved and will sync automatically when connection is restored.';


    case DioExceptionType.cancel:
      return 'Request was cancelled';

    case DioExceptionType.badCertificate:
      return 'Security error. Invalid server certificate.';

    case DioExceptionType.badResponse:
      final response = error.response;
      final data = response?.data;

      // Try extracting message from common backend formats
      if (data is Map<String, dynamic>) {
        final possibleMessage = _deepMessageExtractor(data);
        if (possibleMessage != null && possibleMessage.isNotEmpty) {
          return possibleMessage;
        }
      }

      // Plain text response
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }

      // Fallback based on HTTP status
      final statusCode = response?.statusCode;
      if (statusCode != null) {
        if (statusCode >= 500) {
          return 'Server error ($statusCode). Please try later.';
        }
        if (statusCode == 401) {
          return 'Unauthorized. Please login again.';
        }
        if (statusCode == 403) {
          return 'Access denied.';
        }
        if (statusCode == 404) {
          return 'Requested resource not found.';
        }
        return 'Request failed ($statusCode).';
      }

      return 'Server error occurred';

    case DioExceptionType.unknown:
      return 'Something went wrong. Please try again.';
  }
}
String? _deepMessageExtractor(Map<String, dynamic> data) {
  const keys = [
    'message',
    'error',
    'msg',
    'detail',
    'description',
  ];

  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }

  // Common nested formats
  if (data['error'] is Map<String, dynamic>) {
    return _deepMessageExtractor(data['error']);
  }

  if (data['errors'] is List && data['errors'].isNotEmpty) {
    final first = data['errors'].first;
    if (first is String) return first;
    if (first is Map<String, dynamic>) {
      return _deepMessageExtractor(first);
    }
  }

  return null;
}



class LanguagePopupPrefs {
  static const _key = "language_popup_seen";

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
class NetworkSwitch {
  static bool offline = true;
}
