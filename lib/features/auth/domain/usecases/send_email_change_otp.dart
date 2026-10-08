import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Mails the code a login e-mail change is confirmed with — to the new
/// address, so a mistyped one can never become the address an account signs
/// in with. Right carries the seconds until another code may be asked for.
class SendEmailChangeOtp implements UseCase<int, SendEmailChangeOtpParams> {
  final AuthRepository repository;
  const SendEmailChangeOtp(this.repository);

  @override
  Future<Either<Failure, int>> call(SendEmailChangeOtpParams params) {
    return repository.sendEmailChangeOtp(
      email: params.email,
      childId: params.childId,
    );
  }
}

class SendEmailChangeOtpParams extends Equatable {
  final String email;

  /// Set when the address is one student's rather than the account's own.
  final int? childId;

  const SendEmailChangeOtpParams({required this.email, this.childId});

  @override
  List<Object?> get props => [email, childId];
}
