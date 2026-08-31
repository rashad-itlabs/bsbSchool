import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// "Qeydiyyat" — creates a parent account and links it to the student whose
/// admission code was entered.
///
/// Returns [Unit], not a session: the endpoint deliberately mints no token, so
/// the caller follows up with a normal login.
class RegisterParent implements UseCase<Unit, RegisterParentParams> {
  final AuthRepository repository;
  const RegisterParent(this.repository);

  @override
  Future<Either<Failure, Unit>> call(RegisterParentParams params) {
    return repository.registerParent(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
      admissionNo: params.admissionNo,
      relation: params.relation,
    );
  }
}

class RegisterParentParams extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String password;

  /// The student's `allinone_pay_id` — what the school prints on the admission
  /// document. The backend refuses the whole request when no student holds it.
  final String admissionNo;

  /// `father` / `mother` / `guardian`, written to the `parent_student` pivot.
  /// Optional on the backend, and the form does not ask for it yet.
  final String? relation;

  const RegisterParentParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.admissionNo,
    this.relation,
  });

  @override
  List<Object?> get props =>
      [name, email, phone, password, admissionNo, relation];
}
