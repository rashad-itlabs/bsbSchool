import '../../domain/entities/auth_session.dart';
import 'auth_user_model.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.token,
    required AuthUserModel super.user,
  });

  /// Parses the login response. The user fields may be nested under `user`
  /// (`{ "token": ..., "user": {...} }`) or sit flat at the root
  /// (`{ "token": ..., "name": ..., "child_name": ... }`).
  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? json;

    return AuthSessionModel(
      token: json['token'] as String? ?? '',
      user: AuthUserModel.fromJson(user),
    );
  }
}
