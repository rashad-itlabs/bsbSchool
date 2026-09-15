import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Step one of "Şifrəni unutmusunuz?" — mails a 6-digit code to an account
/// that already exists.
///
/// Distinct from [ResendOtp], which only serves accounts still waiting to
/// confirm a sign-up and therefore turns away everyone who needs a reset.
class ForgotPassword implements UseCase<Unit, ForgotPasswordParams> {
  final AuthRepository repository;
  const ForgotPassword(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ForgotPasswordParams params) {
    return repository.sendResetCode(email: params.email);
  }
}

class ForgotPasswordParams extends Equatable {
  final String email;

  const ForgotPasswordParams({required this.email});

  @override
  List<Object?> get props => [email];
}
