import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  /// Authenticates with the backend and persists the returned token.
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  /// Revokes the token on the server (best-effort) and clears it locally.
  Future<Either<Failure, Unit>> logout();

  /// True when a token is already stored (used to skip the login screen).
  bool get isLoggedIn;

  /// The persisted user from the last login (null when logged out).
  AuthUser? get currentUser;
}
