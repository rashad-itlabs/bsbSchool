import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Changes the address one student signs in with — the parent holds those
/// credentials (see `PassScreen`), so they are the one who corrects them.
class UpdateChildEmail implements UseCase<Unit, UpdateChildEmailParams> {
  final AuthRepository repository;
  const UpdateChildEmail(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateChildEmailParams params) {
    return repository.updateChildEmail(
      childId: params.childId,
      email: params.email,
    );
  }
}

class UpdateChildEmailParams extends Equatable {
  final int childId;
  final String email;

  const UpdateChildEmailParams({required this.childId, required this.email});

  @override
  List<Object?> get props => [childId, email];
}
