import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Single configured [Dio] instance shared by every service in the app.
///
/// It owns the base URL, the default headers and the token interceptor, so
/// individual services only deal with paths (`/login`, `/homeworks`, ...).
class ApiClient {
  /// Backend root. All service paths are relative to this.
  static const String baseUrl = 'https://laravel.bsb.edu.az/api/v1';

  final Dio dio;

  ApiClient(TokenStorage tokenStorage, {void Function()? onUnauthorized})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Let us read the body on 4xx/5xx instead of throwing blindly.
          validateStatus: (status) => status != null && status < 500,
        ),
      ) {
    dio.interceptors.add(
      AuthInterceptor(tokenStorage, onUnauthorized: onUnauthorized),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }
}
