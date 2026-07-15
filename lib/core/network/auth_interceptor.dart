import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches `Authorization: Bearer <token>` to every outgoing request and
/// clears the token when the server rejects it with 401 (expired/invalid).
class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;

  /// Called after a 401 so the app can route back to the login screen.
  final void Function()? onUnauthorized;

  AuthInterceptor(this.tokenStorage, {this.onUnauthorized});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.cachedToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && tokenStorage.hasToken) {
      tokenStorage.clear();
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
