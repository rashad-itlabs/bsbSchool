import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Tells the backend which FCM token reaches this device, and in which
/// language to write to it.
///
/// The account is never sent: the bearer token the interceptor attaches is
/// what the server files the device under, so a token cannot be pinned to
/// somebody else's account from the outside.
abstract class PushTokenApi {
  /// Upserts the row for [token]. A token already filed under another account
  /// — a shared family phone — moves to the one signed in now.
  ///
  /// [muted] are the kinds the parent switched off on this device
  /// (`NotificationKind.pushKind`); the server sends this device none of them.
  /// Always sent, empty included, so turning the last switch back on clears
  /// the list on the server.
  ///
  /// Answers whether the server took it, so the caller knows to try again.
  Future<bool> register({
    required String token,
    required String platform,
    required String locale,
    String? appVersion,
    List<String> muted = const [],
  });

  /// Forgets [token]. Has to run while the session is still valid: without
  /// the bearer token the server cannot tell whose row it is.
  Future<bool> unregister(String token);
}

class DioPushTokenApi implements PushTokenApi {
  static const String path = '/pushToken';

  final Dio dio;
  const DioPushTokenApi(this.dio);

  @override
  Future<bool> register({
    required String token,
    required String platform,
    required String locale,
    String? appVersion,
    List<String> muted = const [],
  }) {
    return _send(() => dio.post(path, data: {
          'token': token,
          'platform': platform,
          'locale': locale,
          'app_version': ?appVersion,
          'muted': muted,
        }));
  }

  @override
  Future<bool> unregister(String token) {
    return _send(() => dio.delete(path, data: {'token': token}));
  }

  /// Nothing here is worth surfacing to the parent: a registration that did
  /// not land is retried on the next launch, and a sign-out goes ahead anyway.
  Future<bool> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final status = response.statusCode ?? 0;
      final data = response.data;
      final ok = status >= 200 &&
          status < 300 &&
          !(data is Map && data['success'] == false);
      if (!ok) debugPrint('[push] $path answered $status: $data');
      return ok;
    } on DioException catch (e) {
      debugPrint('[push] $path failed: ${e.type} ${e.message}');
      return false;
    }
  }
}
