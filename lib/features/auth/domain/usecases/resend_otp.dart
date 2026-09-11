import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Mails a fresh confirmation code when the first one never arrived.
///
/// The previous code stops working, so the parent must use the newest mail.
class ResendOtp implements UseCase<Unit, ResendOtpParams> {
  final AuthRepository repository;
  const ResendOtp(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ResendOtpParams params) {
    return repository.resendOtp(email: params.email);
  }
}

class ResendOtpParams extends Equatable {
  final String email;

  const ResendOtpParams({required this.email});

  @override
  List<Object?> get props => [email];
}
