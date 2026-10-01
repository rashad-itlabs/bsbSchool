part of 'delete_account_bloc.dart';

enum DeleteAccountStatus { initial, submitting, deleted, failure }

class DeleteAccountState extends Equatable {
  final DeleteAccountStatus status;

  /// Shown under the password field: missing, or wrong.
  final String? passwordError;

  /// Shown under the form for anything that isn't about the password — not a
  /// parent account, deleting failed on the server, no connection.
  final String? formError;

  /// The server's confirmation once [DeleteAccountStatus.deleted].
  final String? message;

  const DeleteAccountState({
    this.status = DeleteAccountStatus.initial,
    this.passwordError,
    this.formError,
    this.message,
  });

  bool get isSubmitting => status == DeleteAccountStatus.submitting;

  @override
  List<Object?> get props => [status, passwordError, formError, message];
}
