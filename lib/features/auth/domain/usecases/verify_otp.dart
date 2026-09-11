import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Confirms the 6-digit code mailed after registration.
///
/// Returns [Unit], not a session: the endpoint mints no token, so the caller
/// still hands the credentials back to the login screen once this succeeds.
class VerifyOtp implements UseCase<Unit, VerifyOtpParams> {
  final AuthRepository repository;
  const VerifyOtp(this.repository);

  @override
  Future<Either<Failure, Unit>> call(VerifyOtpParams params) {
    return repository.verifyOtp(email: params.email, otp: params.otp);
  }
}

class VerifyOtpParams extends Equatable {
  final String email;
  final String otp;

  const VerifyOtpParams({required this.email, required this.otp});

  @override
  List<Object?> get props => [email, otp];
}
