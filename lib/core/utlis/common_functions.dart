
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';



import 'dart:convert';
import 'package:dio/dio.dart';

/// ============================================================
/// INTELLIGENT ERROR EXTRACTOR
/// Handles: Dio/HTTP errors, backend JSON formats,
/// AND Dart/Flutter app crash errors
/// ============================================================

String extractBackendError(dynamic error) {
  // ─── NULL ──────────────────────────────────────────────────
  if (error == null) return 'An unknown error occurred.';

  // ─── DART / FLUTTER CRASH ERRORS ──────────────────────────
  if (error is! DioException) {
    return _extractDartError(error);
  }

  // ─── DIO NETWORK ERRORS ───────────────────────────────────
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Please check your internet and try again.';

    case DioExceptionType.connectionError:
      return 'No internet connection. Your data is saved and will sync automatically when restored.';

    case DioExceptionType.cancel:
      return 'Request was cancelled.';

    case DioExceptionType.badCertificate:
      return 'Security error: invalid server certificate.';

    case DioExceptionType.badResponse:
      return _extractFromResponse(error);

    case DioExceptionType.unknown:
      final inner = error.error;
      // Recurse: the wrapped error might be a Dart crash
      if (inner != null && inner is! DioException) {
        return _extractDartError(inner);
      }
      final innerStr = inner?.toString() ?? '';
      if (_isNetworkRelated(innerStr)) {
        return 'No internet connection. Your data is saved and will sync automatically when restored.';
      }
      return 'Something went wrong. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────
// DART / FLUTTER RUNTIME ERROR EXTRACTOR
// Catches all common crash types by runtimeType + message
// ─────────────────────────────────────────────────────────────
String _extractDartError(dynamic error) {
  final type = error.runtimeType.toString();
  final msg = error.toString();
  final lower = msg.toLowerCase();

  // ── Null / type errors ──────────────────────────────────────
  if (error is TypeError) {
    if (lower.contains('null check operator') || lower.contains('null')) {
      return 'A required value was missing. Please try again.';
    }
    if (lower.contains('is not a subtype of')) {
      return 'Received unexpected data format from server.';
    }
    return 'A data type mismatch occurred. Please try again.';
  }

  if (error is Null || lower.contains('null check operator used on a null value')) {
    return 'A required value was missing. Please try again.';
  }

  // ── Cast errors ─────────────────────────────────────────────
  if ( lower.contains('castererror') || lower.contains('type cast')) {
    return 'Received unexpected data format from server.';
  }

  // ── Range / index errors ────────────────────────────────────
  if (error is RangeError) {
    return 'Data index out of range. Please refresh and try again.';
  }

  if (error is IndexError || lower.contains('index out of range') || lower.contains('indexerror')) {
    return 'Data index out of range. Please refresh and try again.';
  }

  // ── Argument errors ─────────────────────────────────────────
  if (error is ArgumentError) {
    final invalidVal = error.invalidValue?.toString();
    if (invalidVal != null && !_isTechnicalString(invalidVal)) {
      return 'Invalid value provided: $invalidVal';
    }
    if (error.message != null) {
      final m = error.message.toString();
      if (!_isTechnicalString(m)) return m;
    }
    return 'Invalid data provided. Please check your input.';
  }

  // ── State errors ─────────────────────────────────────────────
  if (error is StateError) {
    if (lower.contains('no element')) return 'No matching data found.';
    if (lower.contains('bad state')) return 'Application state error. Please restart and try again.';
    return 'Application state error. Please try again.';
  }

  // ── Format errors ────────────────────────────────────────────
  if (error is FormatException) {
    return 'Invalid data format received. Please try again.';
  }

  // ── Unsupported operation ────────────────────────────────────
  if (error is UnsupportedError) {
    return 'This operation is not supported. Please update the app.';
  }

  // ── Assertion errors (debug/dev only, shouldn't reach prod) ──
  if (error is AssertionError) {
    return 'An internal assertion failed. Please contact support.';
  }

  // ── Stack overflow ────────────────────────────────────────────
  if (error is StackOverflowError) {
    return 'The app ran into a processing loop. Please restart.';
  }

  // ── Out of memory ─────────────────────────────────────────────
  if (error is OutOfMemoryError) {
    return 'The app ran out of memory. Please restart.';
  }

  // ── IO / file errors ──────────────────────────────────────────
  if (type.contains('FileSystemException') || lower.contains('filesystemexception')) {
    return 'File access error. Please check storage permissions.';
  }
  if (type.contains('IOException') || lower.contains('ioexception')) {
    return 'File read/write error. Please try again.';
  }

  // ── Platform / channel errors ─────────────────────────────────
  if (type.contains('PlatformException') || lower.contains('platformexception')) {
    // Extract message from PlatformException if accessible via reflection-like toString
    final codeMatch = RegExp(r'code:\s*(\w+)').firstMatch(msg);
    final msgMatch = RegExp(r'message:\s*([^,\)]+)').firstMatch(msg);
    final platformMsg = msgMatch?.group(1)?.trim();
    if (platformMsg != null && !_isTechnicalString(platformMsg)) {
      return platformMsg;
    }
    final code = codeMatch?.group(1);
    return code != null ? 'Platform error ($code). Please try again.' : 'Platform error. Please try again.';
  }

  // ── MissingPluginException ────────────────────────────────────
  if (lower.contains('missingpluginexception') || lower.contains('no implementation found')) {
    return 'A required app feature is unavailable. Please update the app.';
  }

  // ── Hive / storage errors ─────────────────────────────────────
  if (lower.contains('hiveerror') || lower.contains('hive') && lower.contains('box')) {
    return 'Local storage error. Please restart the app.';
  }

  // ── JSON decode errors ────────────────────────────────────────
  if (lower.contains('formatexception') || lower.contains('jsonunsupportedobjecterror') ||
      lower.contains('unexpected character') || lower.contains('invalid json')) {
    return 'Invalid data format received from server. Please try again.';
  }

  // ── Network / socket (non-Dio path) ───────────────────────────
  if (_isNetworkRelated(lower)) {
    return 'No internet connection. Your data is saved and will sync automatically when restored.';
  }

  // ── Timeout (non-Dio path) ────────────────────────────────────
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'Connection timed out. Please check your internet and try again.';
  }

  // ── Generic Exception with a readable message ─────────────────
  if (error is Exception) {
    // Exception.toString() returns "Exception: <message>"
    final cleaned = msg.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (cleaned.isNotEmpty && !_isTechnicalString(cleaned) && cleaned.length < 300) {
      return cleaned;
    }
    return 'An error occurred. Please try again.';
  }

  // ── Last resort: extract anything readable from toString() ────
  final cleaned = msg.replaceAll(RegExp(r'^[A-Za-z]+:\s*'), '').trim();
  if (cleaned.isNotEmpty && !_isTechnicalString(cleaned) && cleaned.length < 300) {
    return cleaned;
  }

  return 'An unexpected error occurred. Please try again.';
}

// ─────────────────────────────────────────────────────────────
// HTTP RESPONSE EXTRACTOR
// ─────────────────────────────────────────────────────────────
String _extractFromResponse(DioException error) {
  final response = error.response;
  final statusCode = response?.statusCode;
  final data = response?.data;

  String? extracted;

  if (data is Map<String, dynamic>) {
    extracted = _deepMessageExtractor(data);
  } else if (data is List) {
    extracted = _extractFromList(data);
  } else if (data is String && data.trim().isNotEmpty) {
    final trimmed = data.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        extracted = _deepMessageExtractor(decoded);
      } else if (decoded is List) {
        extracted = _extractFromList(decoded);
      }
    } catch (_) {
      if (!trimmed.startsWith('<') && trimmed.length < 300) {
        extracted = trimmed;
      }
    }
  }

  if (extracted != null && extracted.isNotEmpty) return extracted;

  if (statusCode != null) {
    if (statusCode == 400) return 'Bad request. Please check your input.';
    if (statusCode == 401) return 'Unauthorized. Please login again.';
    if (statusCode == 403) return 'Access denied. You don\'t have permission.';
    if (statusCode == 404) return 'Requested resource not found.';
    if (statusCode == 408) return 'Request timed out. Please try again.';
    if (statusCode == 409) return 'Conflict. This action cannot be completed.';
    if (statusCode == 422) return 'Validation failed. Please check your input.';
    if (statusCode == 429) return 'Too many requests. Please slow down and try again.';
    if (statusCode >= 500) return 'Server error ($statusCode). Please try again later.';
    return 'Request failed ($statusCode). Please try again.';
  }

  return 'Something went wrong. Please try again.';
}

// ─────────────────────────────────────────────────────────────
// DEEP MESSAGE EXTRACTOR (backend JSON)
// ─────────────────────────────────────────────────────────────
String? _deepMessageExtractor(Map<String, dynamic> data, {int depth = 0}) {
  if (depth > 6) return null;

  // Priority 1: Validation field errors
  final validationFields = [
    'fieldErrors', 'field_errors', 'validationErrors',
    'validation_errors', 'fields', 'violations', 'constraints'
  ];
  for (final key in validationFields) {
    final val = data[key];
    if (val is Map<String, dynamic>) {
      final msgs = <String>[];
      val.forEach((field, v) {
        if (v is List) {
          for (final e in v) { if (e is String) msgs.add('$field: $e'); }
        } else if (v is String) {
          msgs.add('$field: $v');
        }
      });
      if (msgs.isNotEmpty) return msgs.first;
    }
  }

  // Priority 2: errors[] array
  final errorsVal = data['errors'] ?? data['error_list'] ?? data['errorList'];
  if (errorsVal is List && errorsVal.isNotEmpty) {
    final extracted = _extractFromList(errorsVal);
    if (extracted != null) return extracted;
  }

  // Priority 3: Flat string keys
  const messageKeys = [
    'message', 'msg', 'error', 'error_message', 'errorMessage',
    'detail', 'details', 'description', 'reason', 'cause', 'info',
    'title', 'text', 'statusMessage', 'status_message',
    'userMessage', 'user_message', 'displayMessage', 'display_message',
    'friendlyMessage', 'friendly_message', 'hint', 'summary',
    'content', 'body', 'exception', 'fault', 'code', 'status',
  ];

  for (final key in messageKeys) {
    final val = data[key];
    if (val is String && val.trim().isNotEmpty) {
      final cleaned = val.trim();
      if (_isTechnicalString(cleaned)) continue;
      return cleaned;
    }
    if (val is Map<String, dynamic> && depth < 5) {
      final nested = _deepMessageExtractor(val, depth: depth + 1);
      if (nested != null) return nested;
    }
  }

  // Priority 4: Container keys
  const containerKeys = [
    'response', 'data', 'result', 'payload', 'body', 'content', 'output', 'info', 'meta'
  ];
  for (final key in containerKeys) {
    final val = data[key];
    if (val is Map<String, dynamic> && depth < 4) {
      final nested = _deepMessageExtractor(val, depth: depth + 1);
      if (nested != null) return nested;
    }
  }

  // Priority 5: Any readable string value
  if (depth == 0) {
    for (final val in data.values) {
      if (val is String && val.trim().isNotEmpty) {
        final cleaned = val.trim();
        if (!_isTechnicalString(cleaned) && cleaned.length < 300) return cleaned;
      }
    }
  }

  return null;
}

String? _extractFromList(List list) {
  final messages = <String>[];
  for (final item in list) {
    if (item is String && item.trim().isNotEmpty && !_isTechnicalString(item.trim())) {
      messages.add(item.trim());
    } else if (item is Map<String, dynamic>) {
      final msg = _deepMessageExtractor(item);
      if (msg != null) messages.add(msg);
    }
  }
  if (messages.isEmpty) return null;
  if (messages.length == 1) return messages.first;
  return messages.take(3).join(' • ');
}

bool _isNetworkRelated(String s) {
  final lower = s.toLowerCase();
  return lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('host lookup') ||
      lower.contains('dns') ||
      lower.contains('unreachable') ||
      lower.contains('refused');
}

bool _isTechnicalString(String s) {
  if (s.contains('Exception') && s.contains('.')) return true;
  if (s.contains('\n') && s.contains('at ')) return true;
  if (s.startsWith('java.') || s.startsWith('com.')) return true;
  if (s.startsWith('System.')) return true;
  if (RegExp(r'^[A-Z][a-z]+([A-Z][a-z]+)+Exception$').hasMatch(s)) return true;
  if (s.toLowerCase().contains('null pointer')) return true;
  if (s.length > 500) return true;
  if (RegExp(r'^[a-z_]+\.[a-z_]+\.[a-z_]+').hasMatch(s)) return true;
  return false;
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
bool isDeviceAuthError(dynamic e) {
  try {
    if (e is DioException) {
      final data = e.response?.data;
      return data is Map && data["requiresDeviceAuth"] == true;
    }
  } catch (_) {}
  return false;
}


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