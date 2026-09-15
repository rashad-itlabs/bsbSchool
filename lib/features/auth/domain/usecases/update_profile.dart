import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// "Məlumatlarım" — the parent edits their own name, e-mail and phone.
class UpdateProfile implements UseCase<Unit, UpdateProfileParams> {
  final AuthRepository repository;
  const UpdateProfile(this.repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateProfileParams params) {
    return repository.updateProfile(
      name: params.name,
      email: params.email,
      phone: params.phone,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String name;
  final String email;
  final String phone;

  const UpdateProfileParams({
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, email, phone];
}
