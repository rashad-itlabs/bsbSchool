import 'package:equatable/equatable.dart';

import 'auth_user.dart';

/// A successful login result: the bearer token plus the user it belongs to.
class AuthSession extends Equatable {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});

  @override
  List<Object?> get props => [token, user];
}
