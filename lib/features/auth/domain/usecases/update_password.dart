import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// "Şifrəni dəyiş" from inside the app — the signed-in parent replaces their
/// own password.
///
/// Distinct from [ResetPassword], which is for someone locked out: there the
/// proof is a mailed code, here it is the password they already have.
class UpdatePassword implements UseCase<Unit, UpdatePasswordParams> {
  final AuthRepository repository;
  const UpdatePassword(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdatePasswordParams params) {
    return repository.updatePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class UpdatePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;

  const UpdatePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}
