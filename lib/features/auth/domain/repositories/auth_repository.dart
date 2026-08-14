import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';
import '../entities/child_account.dart';

abstract class AuthRepository {
  /// Authenticates with the backend and persists the returned token.
  Future<Either<Failure, AuthSession>> login({
    required String email,
    required String password,
  });

  /// Revokes the token on the server (best-effort) and clears it locally.
  Future<Either<Failure, Unit>> logout();

  /// Sets a new password for [email] without signing the user in.
  /// Fails with a [ValidationFailure] when the e-mail is unknown.
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String password,
  });

  /// True when a token is already stored (used to skip the login screen).
  bool get isLoggedIn;

  /// The persisted user from the last login (null when logged out).
  AuthUser? get currentUser;

  /// The student the app is currently showing. A parent with several students
  /// switches between them; everyone else has at most one, so this is simply
  /// the account's own student (or null when the login carried no `info`).
  ChildAccount? get activeChild;

  /// `student_id` to scope requests with — the active child, falling back to
  /// the student the token itself belongs to.
  int? get activeStudentId;

  /// `class_id` to scope requests with, same fallback as [activeStudentId].
  int? get activeClassId;

  /// Switches the account over to another of its students: tells the backend
  /// (which writes the id into `users.user_id`, the same column the web panel
  /// drives) and, once that lands, remembers it locally.
  ///
  /// Fails without touching the local pick, so a rejected or unreachable
  /// switch leaves the app showing the student it already had.
  Future<Either<Failure, Unit>> selectChild(int childId);
}
