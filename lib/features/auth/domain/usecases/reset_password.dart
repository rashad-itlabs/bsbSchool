import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// "Şifrəni unutmusunuz?" — replaces the password of an existing account.
class ResetPassword implements UseCase<Unit, ResetPasswordParams> {
  final AuthRepository repository;
  const ResetPassword(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ResetPasswordParams params) {
    return repository.resetPassword(
      email: params.email,
      password: params.password,
    );
  }
}

class ResetPasswordParams extends Equatable {
  final String email;
  final String password;

  const ResetPasswordParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
