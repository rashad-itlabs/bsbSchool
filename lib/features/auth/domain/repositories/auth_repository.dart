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

  /// Updates the signed-in account's own details and caches the result, so
  /// the profile shows the new values without a re-login.
  ///
  /// Fails with a [FieldValidationFailure] when the backend rejects an input,
  /// so the form can put each message back under its own field.
  Future<Either<Failure, Unit>> updateProfile({
    required String name,
    required String email,
    required String phone,
  });

  /// Replaces the signed-in account's own password. Nothing is cached: the
  /// password is never held by the app, and the session survives the change.
  ///
  /// Fails with a [FieldValidationFailure] when the current password is wrong
  /// or the new one is rejected.
  Future<Either<Failure, Unit>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Changes the login e-mail of one student on the account, and caches the
  /// result so the credentials card shows the new address.
  ///
  /// Fails with a [ValidationFailure] when the student is on another account
  /// or the address is already taken.
  Future<Either<Failure, Unit>> updateChildEmail({
    required int childId,
    required String email,
  });

  /// Mails a 6-digit code to [email] so its password can be replaced.
  ///
  /// Not the same code path as [resendOtp]: that one only serves accounts
  /// still waiting to confirm a registration, so it turns away every account
  /// that has already been confirmed.
  ///
  /// Fails with a [ValidationFailure] when no account holds the address.
  Future<Either<Failure, Unit>> sendResetCode({required String email});

  /// Sets a new password for [email] without signing the user in. [otp] is the
  /// code [sendResetCode] mailed; the backend checks it in the same request,
  /// so a reset cannot be driven by an address alone.
  ///
  /// Fails with a [ValidationFailure] when the e-mail is unknown or the code
  /// no longer holds.
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String password,
    required String otp,
  });

  /// Creates a parent account and links it to the student holding
  /// [admissionNo]. Issues no session: the caller signs in afterwards with the
  /// same credentials, so login stays the one place a token is minted.
  ///
  /// Fails with a [FieldValidationFailure] when the backend rejects an input,
  /// so the form can put each message back under its own field.
  Future<Either<Failure, Unit>> registerParent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String admissionNo,
    String? relation,
  });

  /// Confirms the 6-digit code mailed to [email] after registration. Mints no
  /// token either: the caller signs in through login once the code is
  /// accepted, so login stays the one place a token is minted.
  ///
  /// Fails with a [ValidationFailure] when the code is wrong or expired.
  Future<Either<Failure, Unit>> verifyOtp({
    required String email,
    required String otp,
  });

  /// Mails a fresh code to [email], invalidating the previous one.
  Future<Either<Failure, Unit>> resendOtp({required String email});

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

  /// Links one more student to the account, by the admission code the school
  /// issued for them.
  ///
  /// Registration only takes one code, but a parent with several children is
  /// given one per child, so the rest are linked after the fact. On success
  /// the refreshed user is cached, which is what puts the new student into
  /// [currentUser]'s `children` and therefore into the switcher.
  ///
  /// Fails with a [ValidationFailure] when the code matches no student or the
  /// student is already on this account.
  Future<Either<Failure, Unit>> attachChild({
    required String admissionNo,
    String? relation,
  });
}
