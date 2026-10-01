import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// "Hesabı sil" — the signed-in parent permanently deletes their own account,
/// confirming with its password. Takes the password; yields the server's
/// confirmation message, if any.
class DeleteAccount implements UseCase<String?, String> {
  final AuthRepository repository;
  const DeleteAccount(this.repository);

  @override
  Future<Either<Failure, String?>> call(String password) {
    return repository.deleteAccount(password: password);
  }
}
