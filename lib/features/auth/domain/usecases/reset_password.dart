import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Step three of "Şifrəni unutmusunuz?" — replaces the password, quoting the
/// code that was mailed so the backend can check it is really the account's
/// owner asking.
class ResetPassword implements UseCase<Unit, ResetPasswordParams> {
  final AuthRepository repository;
  const ResetPassword(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ResetPasswordParams params) {
    return repository.resetPassword(
      email: params.email,
      password: params.password,
      otp: params.otp,
    );
  }
}

class ResetPasswordParams extends Equatable {
  final String email;
  final String password;

  /// The code [SendPasswordResetOtp] mailed and [VerifyPasswordResetOtp]
  /// accepted.
  final String otp;

  const ResetPasswordParams({
    required this.email,
    required this.password,
    required this.otp,
  });

  @override
  List<Object?> get props => [email, password, otp];
}
