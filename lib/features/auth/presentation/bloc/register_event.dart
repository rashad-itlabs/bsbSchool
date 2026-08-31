part of 'register_bloc.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

/// Parent tapped "Qeydiyyatdan keç". Carries the raw form values — trimming
/// and validation belong to the bloc, so the screen stays a set of
/// controllers.
class RegisterSubmitted extends RegisterEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;

  /// The student's admission code (`allinone_pay_id`).
  final String admissionNo;

  final bool acceptedTerms;

  /// `father` / `mother` / `guardian` for the `parent_student` pivot. Optional
  /// on the backend, and the form does not offer it yet.
  final String? relation;

  const RegisterSubmitted({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    required this.admissionNo,
    required this.acceptedTerms,
    this.relation,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        password,
        passwordConfirmation,
        admissionNo,
        acceptedTerms,
        relation,
      ];
}

/// An input was edited after a failed submit — drops the message sitting under
/// it so a corrected field stops shouting.
class RegisterFieldEdited extends RegisterEvent {
  final RegisterField field;

  const RegisterFieldEdited(this.field);

  @override
  List<Object?> get props => [field];
}
