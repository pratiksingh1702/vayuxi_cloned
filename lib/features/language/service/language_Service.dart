import 'package:untitled2/core/api/dio.dart';
import 'dart:io';
import 'package:dio/dio.dart';
// providers/insulation_combined_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/api/dio.dart';

class LanguageApiService {
  final Dio dio = DioClient.dio;



  Future<Response> listLanguages({String? userId}) {
    return dio.get(
      '/language/list',
      queryParameters: userId != null ? {'userId': userId} : null,
    );
  }

  Future<Response> downloadLanguage(String userId, String code) {
    return dio.post(
      '/language/download',
      data: {'userId': userId, 'languageCode': code},
    );
  }

  Future<Response> setActiveLanguage(String userId, String code) {
    return dio.post(
      '/language/set-active',
      data: {'userId': userId, 'languageCode': code},
    );
  }

  Future<Response> getModule(
      String userId,
      String code,
      String module,
      ) {
    return dio.get(
      '/language/get-module',
      queryParameters: {
        'userId': userId,
        'languageCode': code,
        'moduleName': module,
      },
    );
  }
  bool _isLanguageNotDownloadedError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = (data['message'] ?? '').toString().toLowerCase();
      return msg.contains('language not downloaded');
    }
    return false;
  }

}

