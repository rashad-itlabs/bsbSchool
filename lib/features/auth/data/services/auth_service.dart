import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/auth_session_model.dart';
import '../models/auth_user_model.dart';
import '../../../../core/l10n/l10n.dart';

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

  /// Links one more student to the signed-in parent account, by the same
  /// admission code registration asks for.
  ///
  /// Returns the refreshed user — same shape as the login body — whose `info`
  /// carries *every* student on the account, the new one included. Null when
  /// the endpoint only reports success; the caller then keeps what it had.
  Future<AuthUserModel?> attachChild({
    required String admissionNo,
    String? relation,
  });

  /// Sets a new password for the account matching [email].
  Future<void> resetPassword({
    required String email,
    required String password,
  });

  /// Creates a parent account and links it to the student whose admission
  /// code is [admissionNo]. Issues no token — the caller signs in afterwards.
  ///
  /// Throws a [FieldValidationException] when the backend rejects one of the
  /// inputs, so the form can show each message under its own field.
  Future<void> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String admissionNo,
    String? relation,
  });

  /// Confirms the address a registration was made with, using the 6-digit code
  /// Laravel mailed there. Issues no token — the caller signs in afterwards.
  Future<void> verifyOtp({
    required String email,
    required String otp,
  });

  /// Mails a fresh code to [email], retiring the one sent before it.
  Future<void> resendOtp({
    required String email,
  });
}

class AuthServiceImpl implements AuthService {
  /// Backend route that swaps the password of a known e-mail. Kept here so a
  /// rename on the Laravel side is a one-line change.
  static const String resetPasswordPath = '/changePassword';

  /// Backend route that re-points the account at another of its students.
  static const String selectChildPath = '/selectChild';

  /// Backend route that links one more student to the account.
  static const String attachChildPath = '/attachChild';

  /// Backend route behind `AuthController::registerParent`. Kept here so a
  /// rename on the Laravel side is a one-line change.
  static const String registerParentPath = '/register';

  /// Backend routes that check and re-send the registration code.
  static const String verifyOtpPath = '/verifyOtp';
  static const String resendOtpPath = '/resendOtp';

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
          throw ServerException(L.s.errTokenMissing);
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

  @override
  Future<AuthUserModel?> attachChild({
    required String admissionNo,
    String? relation,
  }) async {
    try {
      final response = await dio.post(
        attachChildPath,
        data: {
          'admission_no': admissionNo,
          if (relation != null && relation.isNotEmpty) 'relation': relation,
        },
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 || status == 201) {
        if (data is! Map<String, dynamic>) return null;
        // `{"success": false, ...}` — a 200 that isn't one.
        if (data['success'] == false) {
          throw ValidationException(_attachChildMessage(data, status));
        }
        // Same three hiding places as `/selectChild`.
        final user = _userFrom(data);
        if (user != null) return AuthUserModel.fromJson(user);

        // Failing that, the roster on its own is enough: the repository folds
        // a children-only model into the cached session, so every scalar it
        // already held survives. Without this branch an endpoint that answers
        // `{"success": true, "info": [...]}` — no `user_id` anywhere — reads as
        // a bare acknowledgement, and the new student stays invisible until
        // the next login.
        final roster = _rosterFrom(data);
        return roster == null
            ? null
            : AuthUserModel.fromJson({'info': roster});
      }

      // 422 — unknown code, or already on this account. 403 — not a parent.
      throw ValidationException(_attachChildMessage(data, status));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  /// The students array on its own, wherever the response chose to put it.
  ///
  /// An empty list is treated as absent: it is indistinguishable from an
  /// endpoint that sends no roster at all, and caching it would empty the
  /// switcher for an account that demonstrably has students.
  List<dynamic>? _rosterFrom(Map<String, dynamic> data) {
    for (final candidate in [
      data['info'],
      data['children'],
      data['students'],
      data['data'],
    ]) {
      if (candidate is List && candidate.isNotEmpty) return candidate;
    }
    return null;
  }

  /// The endpoint answers Laravel's validation body, so the nested
  /// `errors.admission_no` message is the specific one and wins over the
  /// generic top-level `message` — same order as [_resetMessageFrom].
  String _attachChildMessage(dynamic data, int status) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    if (status == 404 || status == 422) return L.s.errStudentNotFound;
    return L.s.errServer;
  }

  String _selectChildMessage(dynamic data, int status) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (status == 403) return L.s.errChildNotYours;
    if (status == 404 || status == 422) return L.s.errStudentNotFound;
    return L.s.errChildNotSwitched;
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
      return L.s.errUserNotFound;
    }
    return L.s.errServer;
  }

  @override
  Future<void> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String admissionNo,
    String? relation,
  }) async {
    try {
      final response = await dio.post(
        registerParentPath,
        // The endpoint validates on these exact keys — it was written against
        // the form's controller names, so they are the contract, not a typo.
        data: {
          '_name_nameController': name,
          '_emailController': email,
          '_phoneController': phone,
          '_passwordController': password,
          '_admissionController': admissionNo,
          if (relation != null && relation.isNotEmpty) 'relation': relation,
        },
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      // The endpoint answers `{"success": true, "message": ...}` on 200 — trust
      // the flag over the status code when both are present.
      if (status == 200 || status == 201) {
        if (data is Map && data['success'] == false) {
          throw FieldValidationException(
            _fieldErrorsFrom(data),
            _registerMessageFrom(data, status),
          );
        }
        return;
      }

      // 422 — a field failed, or the admission code matched no student. Both
      // arrive together in `errors`, which is the point of the endpoint's
      // single-basket validation.
      throw FieldValidationException(
        _fieldErrorsFrom(data),
        _registerMessageFrom(data, status),
      );
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  /// `{"errors": {field: [msg, ...]}}` flattened to one message per field —
  /// the form shows a single line under each input.
  Map<String, String> _fieldErrorsFrom(dynamic data) {
    final errors = data is Map ? data['errors'] : null;
    if (errors is! Map) return const {};

    final flattened = <String, String>{};
    errors.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        flattened[key.toString()] = value.first.toString();
      } else if (value != null) {
        flattened[key.toString()] = value.toString();
      }
    });
    return flattened;
  }

  /// Form-wide wording. The per-field messages are the specific ones, so this
  /// only needs to cover the case where the body carries none.
  String _registerMessageFrom(dynamic data, int status) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (status == 422) return L.s.errInvalid;
    return L.s.errServer;
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await dio.post(
        verifyOtpPath,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      // The endpoint answers `{"success": true, "message": "..."}` — trust the
      // flag over the status code when both are present.
      if (status == 200 || status == 201 || status == 204) {
        if (data is Map && data['success'] == false) {
          throw ValidationException(_otpMessageFrom(data, status));
        }
        return;
      }

      // 400/422 — the code is wrong, already spent, or past its expiry.
      throw ValidationException(_otpMessageFrom(data, status));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  @override
  Future<void> resendOtp({
    required String email,
  }) async {
    try {
      final response = await dio.post(
        resendOtpPath,
        data: {'email': email},
      );

      final status = response.statusCode ?? 0;
      final data = response.data;

      if (status == 200 || status == 201 || status == 204) {
        if (data is Map && data['success'] == false) {
          throw ValidationException(_otpMessageFrom(data, status));
        }
        return;
      }

      // 422 — the address is unknown, or the backend is throttling re-sends.
      throw ValidationException(_otpMessageFrom(data, status));
    } on DioException catch (e) {
      throw ServerException(_dioMessage(e));
    }
  }

  /// Same Laravel validation body as [_resetMessageFrom], but the fallback has
  /// to blame the code rather than the e-mail: the account already exists by
  /// the time these run, so an unknown address is not what went wrong.
  String _otpMessageFrom(dynamic data, int status) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first != null) return first.toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    if (status == 400 || status == 401 || status == 404 || status == 422) {
      return L.s.otpInvalid;
    }
    return L.s.errServer;
  }

  String _messageFrom(dynamic data, int status) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (status == 401 || status == 422) {
      return L.s.errWrongCredentials;
    }
    return L.s.errServer;
  }

  String _dioMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return L.s.errNoConnection;
    }
    return _messageFrom(e.response?.data, e.response?.statusCode ?? 0);
  }
}
