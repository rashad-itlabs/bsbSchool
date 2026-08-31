part of 'register_bloc.dart';

enum RegisterStatus { initial, loading, success, error }

/// The inputs the sign-up form can complain about. Errors are keyed by field
/// rather than collapsed into one message, because the endpoint answers with
/// every problem at once — a duplicate e-mail and an unknown admission code
/// arrive together — and each belongs under its own input.
enum RegisterField {
  name,
  email,
  phone,
  password,
  passwordConfirmation,
  admissionNo,
  terms,
}

class RegisterState extends Equatable {
  final RegisterStatus status;

  /// Per-field messages, from the local rules or from the backend's `errors`
  /// map. Empty while the form is clean.
  final Map<RegisterField, String> errors;

  /// Form-wide text that belongs to no single input: a server or network
  /// failure, or the confirmation once the account exists.
  final String? message;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.errors = const {},
    this.message,
  });

  bool get isLoading => status == RegisterStatus.loading;

  String? errorFor(RegisterField field) => errors[field];

  RegisterState copyWith({
    RegisterStatus? status,
    Map<RegisterField, String>? errors,
    String? message,
  }) =>
      RegisterState(
        status: status ?? this.status,
        errors: errors ?? this.errors,
        // message is intentionally not carried over: each state sets it, so a
        // stale failure can't resurface on the next emit.
        message: message,
      );

  @override
  List<Object?> get props => [status, errors, message];
}
