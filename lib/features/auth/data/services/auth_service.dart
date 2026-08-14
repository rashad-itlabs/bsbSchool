import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';

/// Talks to the auth endpoints over the shared [Dio] instance. Throws the
/// app's typed [ServerException] / [ValidationException] so the repository
/// can map them to [Failure]s.
abstract class AuthService {
  Future<AuthSessionModel> login({
    required String email,
    required String password,
    required String deviceName,
  });

  Future<void> logout();

  /// Points the account at another of its students: the backend writes the id
  /// into `users.user_id`, so every later request resolves to that student
  /// from the token alone.
  ///
  /// Returns the refreshed user when the endpoint echoes one back (same shape
  /// as the login body), null when it only reports success.
  Future<AuthUserModel?> selectChild(int childId);

  /// Sets a new password for the account matching [email].
  Future<void> resetPassword({
    required String email,
    required String password,
  });
}

class AuthServiceImpl implements AuthService {
  /// Backend route that swaps the password of a known e-mail. Kept here so a
  /// rename on the Laravel side is a one-line change.
  static const String resetPasswordPath = '/changePassword';

  /// Backend route that re-points the account at another of its students.
  static const String selectChildPath = '/selectChild';

  final Dio dio;
  const AuthServiceImpl(this.dio);

  @override
  Future<AuthSessionModel> login({
    required String email,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 && data is Map<String, dynamic>) {
        final session = AuthSessionModel.fromJson(data);
        if (session.token.isEmpty) {
          throw const ServerException('Token cavabda tapılmadı');
        }
        return session;
      }

      // 401/422 etc. — surface the server's validation message.
      throw ValidationException(_messageFrom(data, status));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/logout');
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  @override
  Future<AuthUserModel?> selectChild(int childId) async {
    try {
      final response = await dio.post(
        selectChildPath,
        data: {'child_id': childId},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 || status == 201 || status == 204) {
        if (data is! Map<String, dynamic>) return null;
        // `{"success": false, "message": ...}` — a 200 that isn't one.
        if (data['success'] == false) {
          throw ValidationException(_messageFrom(data, status));
        }
        // The body may be the refreshed user (flat, or under `user` / `data`),
        // or just an acknowledgement. Only the former is worth caching.
        final user = _userFrom(data);
        return user == null ? null : AuthUserModel.fromJson(user);
      }

      // 403 — the student isn't on this account. 422 — unknown id.
      throw ValidationException(_selectChildMessage(data, status));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  /// The user object hides in one of three places depending on how the
  /// endpoint answers; anything without a `user_id` is an acknowledgement, not
  /// a user, and caching it would wipe the session down to empty strings.
  Map<String, dynamic>? _userFrom(Map<String, dynamic> data) {
    for (final candidate in [
      data['user'],
      data['data'],
      data,
    ]) {
      if (candidate is Map<String, dynamic> &&
          (candidate.containsKey('user_id') || candidate.containsKey('id'))) {
        return candidate;
      }
    }
    return null;
  }

  String _selectChildMessage(dynamic data, int status) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (status == 403) return 'Bu şagird sizin hesabınıza aid deyil';
    if (status == 404 || status == 422) return 'Şagird tapılmadı';
    return 'Şagird dəyişdirilmədi';
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        resetPasswordPath,
        data: {
          'email': email,
          'new_password': password,
          // Laravel's `confirmed` rule on `new_password` looks for this exact
          // key; without it the request fails validation.
          'new_password_confirmation': password,
        },
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      // The endpoint answers `{"success": true, "message": "..."}` — trust the
      // flag over the status code when both are present.
      if (status == 200 || status == 201 || status == 204) {
        if (data is Map && data['success'] == false) {
          throw ValidationException(_resetMessageFrom(data, status));
        }
        return;
      }

      // 422 — unknown e-mail, or the password failed `min:6` / `confirmed`.
      throw ValidationException(_resetMessageFrom(data, status));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  /// Laravel's ValidationException body is `{"message": ..., "errors": {field:
  /// [msg, ...]}}`. The nested error is the specific one ("Bu email ilə
  /// istifadəçi tapılmadı."), so it wins over the generic top-level message.
  String _resetMessageFrom(dynamic data, int status) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    if (status == 404 || status == 422) {
      return 'Bu e-mail ilə istifadəçi tapılmadı';
    }
    return 'Server xətası baş verdi';
  }

  String _messageFrom(dynamic data, int status) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (status == 401 || status == 422) {
      return 'E-mail və ya şifrə yanlışdır';
    }
    return 'Server xətası baş verdi';
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Serverə qoşulmaq mümkün olmadı';
    }
    return _messageFrom(e.response?.data, e.response?.statusCode ?? 0);
  }
}
