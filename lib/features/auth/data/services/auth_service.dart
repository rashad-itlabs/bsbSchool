import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/auth_session_model.dart';

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
}

class AuthServiceImpl implements AuthService {
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
